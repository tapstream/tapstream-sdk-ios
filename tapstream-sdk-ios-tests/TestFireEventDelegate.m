//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>

#import "TSAppEventSource.h"
#import "TSFireEventDelegate.h"
#import "TSTestUtils.h"
#import "TSDefs.h"

@interface TSEvent()
- (void)prepare:(NSDictionary*)globalEventParams;
@end

SpecBegin(FireEventDelegate)

describe(@"FireEventDelegate", ^{
	__block TSConfig* config;
	__block dispatch_queue_t queue;
	__block id<TSPlatform> platform;
	__block id<TSHttpClient> httpClient;
	__block TSDefaultFireEventDelegate* fireEventDelegate;
	__block id<TSCoreListener> listener;
	__block id<TSFireEventStrategy> fireEventStrategy;


	beforeEach(^{
		platform = OCMProtocolMock(@protocol(TSPlatform));
		listener = OCMProtocolMock(@protocol(TSCoreListener));
		queue = dispatch_queue_create("testq", DISPATCH_QUEUE_SERIAL);

		fireEventStrategy = OCMProtocolMock(@protocol(TSFireEventStrategy));

		httpClient = OCMProtocolMock(@protocol(TSHttpClient));
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
		OCMStub([platform getAppName]).andReturn(@"testapp");
		OCMStub([platform getPlatformName]).andReturn(kTSPlatform);

		fireEventDelegate = [TSDefaultFireEventDelegate defaultFireEventDelegateWithConfig:config
																					 queue:queue
																				  platform:platform
																		 fireEventStrategy:fireEventStrategy
																				httpClient:httpClient
																				  listener:listener];
	});

	it(@"Will not fire an event if shouldFireEvent returns false", ^{
		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(false);
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];

		OCMReject([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);
		[fireEventDelegate fireEvent:event];
		block_until_queue_completed(queue);
	});

	it(@"Calls prepare on the event when it is fired", ^{
		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(false);
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
        assertThat(@(event.isPrepared), isFalse());
        [fireEventDelegate fireEvent:event];
        assertThat(@(event.isPrepared), isTrue());
	});

	it(@"Will only retry retryable fire event responses", ^{
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* errorResponse = [TSResponse responseWithStatus:500 message:@"Error" data:nil];
		TSResponse* badRequestResponse = [TSResponse responseWithStatus:400 message:@"Error" data:nil];
		TSResponse* okResponse = [TSResponse responseWithStatus:200 message:@"OK" data:nil];

		__block int firedCount = 0;

		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]).andDo(^(NSInvocation *invocation){
			[invocation retainArguments];
			void (^completion)(TSResponse*) = nil;
			[invocation getArgument:&completion atIndex:6];
			firedCount += 1;
			if(firedCount == 1)
			{
				completion(errorResponse);
			}
			else if(firedCount == 2)
			{
				completion(badRequestResponse);
			}
			else
			{
				completion(okResponse);
			}

		});

		OCMReject([fireEventStrategy registerResponse:okResponse forEvent:event]);

		[fireEventDelegate fireEvent:event];
		block_until_queue_completed(queue);

		assertThatInteger(firedCount, equalToInteger(2));
		OCMVerify([fireEventStrategy registerFiringEvent:event]);
		OCMVerify([fireEventStrategy registerResponse:errorResponse forEvent:event]);
		OCMVerify([fireEventStrategy registerResponse:badRequestResponse forEvent:event]);
	});
	
	
});

SpecEnd
