//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>

#import "TSTestPersistentStorage.h"
#import "TSDefaultFireEventStrategy.h"
#import "TSDefaultCoreListener.h"

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

});

SpecEnd

/*
 - (BOOL)shouldFireEvent:(TSEvent*)event;
 - (int)getDelay;
 - (void)registerEventFired:(TSEvent*)event;
 - (void)registerResponse:(TSResponse*)response forEvent:(TSEvent*)e;
*/
