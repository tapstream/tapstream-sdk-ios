//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>

#import "TSTestPersistentStorage.h"
#import "TSDefaultFireEventStrategy.h"
#import "TSDefaultCoreListener.h"
#import "TSConfig.h"

SpecBegin(FireEventStrategy)
describe(@"FireEventStrategy", ^{
	__block TSTestPersistentStorage* storage;
	__block TSDefaultFireEventStrategy* strat;
	__block TSEvent *baseEvent, *normalEvent, *oneTimeEvent;
	__block TSDefaultCoreListener* listener;

	beforeEach(^{
		storage = [[TSTestPersistentStorage alloc] init];
		listener = [[TSDefaultCoreListener alloc] init];
		strat = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener];
		baseEvent = [TSEvent eventWithName:@"MyName" oneTimeOnly:true];
		oneTimeEvent = [TSEvent eventWithName:@"MyName" oneTimeOnly:true];
		normalEvent = [TSEvent eventWithName:@"MyName" oneTimeOnly:false];
	});

	it(@"Should fire all unregistered events", ^{
		assertThatBool([strat shouldFireEvent:baseEvent], isTrue());
		assertThatBool([strat shouldFireEvent:normalEvent], isTrue());
		assertThatBool([strat shouldFireEvent:oneTimeEvent], isTrue());
	});

	it(@"Should obey the oneTimeOnly field if an event is currently firing", ^{
		[strat registerFiringEvent:baseEvent];

		assertThatBool([strat shouldFireEvent:normalEvent], isTrue());
		assertThatBool([strat shouldFireEvent:oneTimeEvent], isFalse());
	});

	it(@"Should obey the oneTimeOnly field if an event has fired successfully", ^{
		[strat registerFiringEvent:baseEvent];

		TSResponse* resp = [TSResponse responseWithStatus:200 message:@"" data:nil];
		[strat registerResponse:resp forEvent:baseEvent];

		assertThatBool([strat shouldFireEvent:normalEvent], isTrue());
		assertThatBool([strat shouldFireEvent:oneTimeEvent], isFalse());
	});

	it(@"Should allow a oneTimeOnly event to re-fire if it failed", ^{
		[strat registerFiringEvent:baseEvent];

		TSResponse* resp = [TSResponse responseWithStatus:400 message:@"" data:nil];
		[strat registerResponse:resp forEvent:baseEvent];

		assertThatBool([strat shouldFireEvent:normalEvent], isTrue());
		assertThatBool([strat shouldFireEvent:oneTimeEvent], isTrue());
	});

	it(@"Should persist fired events", ^{
		[strat registerFiringEvent:baseEvent];
		TSResponse* resp = [TSResponse responseWithStatus:200 message:@"" data:nil];
		[strat registerResponse:resp forEvent:baseEvent];

		TSDefaultFireEventStrategy* newStrat = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener];

		assertThatBool([newStrat shouldFireEvent:normalEvent], isTrue());
		assertThatBool([newStrat shouldFireEvent:oneTimeEvent], isFalse());
	});

	it(@"Should keep track of firing events", ^{
		assertThatInteger([[strat firingEvents] count], equalToInteger(0));

		[strat registerFiringEvent:baseEvent];

		assertThatInteger([[strat firingEvents] count], equalToInteger(1));
		assertThat([[strat firingEvents] anyObject], is([baseEvent name]));

		TSResponse* resp = [TSResponse responseWithStatus:200 message:@"" data:nil];
		[strat registerResponse:resp forEvent:baseEvent];

		assertThatInteger([[strat firingEvents] count], equalToInteger(0));
	});

	describe(@"retry limit", ^{
		TSResponse* (^failure)(void) = ^{
			return [TSResponse responseWithStatus:500 message:@"" data:nil];
		};

		it(@"Defaults to unlimited retries", ^{
			TSConfig* config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
			assertThatInteger(config.maxEventRetries, equalToInteger(kTSUnlimitedRetries));
			assertThatInteger(strat.maxRetries, equalToInteger(kTSUnlimitedRetries));

			for(int ii = 0; ii < 100; ii++)
			{
				assertThatBool([strat shouldRetryEvent:normalEvent], isTrue());
			}
			assertThatInteger(normalEvent.retryCount, equalToInteger(100));
		});

		it(@"Stops retrying an event after maxRetries", ^{
			TSDefaultFireEventStrategy* limited = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener maxRetries:2];

			assertThatBool([limited shouldRetryEvent:normalEvent], isTrue());
			assertThatBool([limited shouldRetryEvent:normalEvent], isTrue());
			assertThatBool([limited shouldRetryEvent:normalEvent], isFalse());
			assertThatInteger(normalEvent.retryCount, equalToInteger(2));

			// The limit is per event
			assertThatBool([limited shouldRetryEvent:oneTimeEvent], isTrue());
		});

		it(@"Never retries when maxRetries is 0", ^{
			TSDefaultFireEventStrategy* limited = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener maxRetries:0];

			assertThatBool([limited shouldRetryEvent:normalEvent], isFalse());
			assertThatInteger(normalEvent.retryCount, equalToInteger(0));
		});

		it(@"Hands off delay management when the failing event gives up", ^{
			TSDefaultFireEventStrategy* limited = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener maxRetries:1];

			[limited registerResponse:failure() forEvent:normalEvent];
			assertThatInt([limited getDelay], equalToInt(2));
			assertThat(limited.failingEventId, is(normalEvent.uid));

			assertThatBool([limited shouldRetryEvent:normalEvent], isTrue());

			// The final failure won't be retried: it releases ownership without growing the delay
			[limited registerResponse:failure() forEvent:normalEvent];
			assertThatInt([limited getDelay], equalToInt(2));
			assertThat(limited.failingEventId, nilValue());
			assertThatBool([limited shouldRetryEvent:normalEvent], isFalse());

			// Another failing event takes over and keeps backing off
			[limited registerResponse:failure() forEvent:oneTimeEvent];
			assertThat(limited.failingEventId, is(oneTimeEvent.uid));
			assertThatInt([limited getDelay], equalToInt(4));
		});

		it(@"Does not grow the delay for failures that will not be retried", ^{
			TSDefaultFireEventStrategy* noRetries = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener maxRetries:0];

			for(int ii = 0; ii < 6; ii++)
			{
				TSEvent* event = [TSEvent eventWithName:@"MyName" oneTimeOnly:false];
				[noRetries registerResponse:failure() forEvent:event];
				assertThatBool([noRetries shouldRetryEvent:event], isFalse());
			}

			assertThatInt([noRetries getDelay], equalToInt(0));
			assertThat(noRetries.failingEventId, nilValue());
		});

		it(@"Hands off delay management when the failing event gets a non-retryable response", ^{
			[strat registerResponse:failure() forEvent:normalEvent];
			assertThatInt([strat getDelay], equalToInt(2));
			assertThat(strat.failingEventId, is(normalEvent.uid));

			[strat registerResponse:[TSResponse responseWithStatus:400 message:@"" data:nil] forEvent:normalEvent];
			assertThat(strat.failingEventId, nilValue());
			assertThatInt([strat getDelay], equalToInt(2));

			// Another failing event takes over and keeps backing off
			[strat registerResponse:failure() forEvent:oneTimeEvent];
			assertThat(strat.failingEventId, is(oneTimeEvent.uid));
			assertThatInt([strat getDelay], equalToInt(4));
		});
	});

});

SpecEnd

/*
 - (BOOL)shouldFireEvent:(TSEvent*)event;
 - (int)getDelay;
 - (void)registerEventFired:(TSEvent*)event;
 - (void)registerResponse:(TSResponse*)response forEvent:(TSEvent*)e;
*/
