//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>

#import "TSAppEventSource.h"
#import "TSIOSFireEventDelegate.h"
#import "TSTestUtils.h"
#import "TSDefs.h"

@interface TSEvent()
- (void)prepare:(NSDictionary*)globalEventParams;
@end


void fireEventBlocking(TSIOSFireEventDelegate* del, TSEvent* event)
{
	// Used for tests which expect cookie matching (which must run on the main thread)
	// Otherwise, just use block_until_queue_completed
	__block bool hasCompleted = false;

	[del fireEvent:event completion:^(TSResponse* response){
		hasCompleted = true;
	}];

	// Wait 1 second or until completed
	NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
	while (!hasCompleted && [loopUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:loopUntil];
	}
}




SpecBegin(IOSFireEventDelegate)

describe(@"IOSFireEventDelegate", ^{
	__block TSConfig* config;
	__block dispatch_queue_t queue;
	__block id<TSPlatform> platform;
	__block id<TSHttpClient> httpClient;
	__block TSIOSFireEventDelegate* fireEventDelegate;
	__block id<TSCoreListener> listener;
	__block id<TSFireEventStrategy> fireEventStrategy;
	__block id<TSCookieMatchStrategy> cookieMatchStrategy;


	beforeEach(^{
		platform = OCMProtocolMock(@protocol(TSPlatform));
		listener = OCMProtocolMock(@protocol(TSCoreListener));
		queue = dispatch_queue_create("testq", DISPATCH_QUEUE_SERIAL);

		fireEventStrategy = OCMProtocolMock(@protocol(TSFireEventStrategy));
		cookieMatchStrategy = OCMProtocolMock(@protocol(TSCookieMatchStrategy));

		httpClient = OCMProtocolMock(@protocol(TSHttpClient));
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
		OCMStub([platform getAppName]).andReturn(@"testapp");
		OCMStub([platform getPlatformName]).andReturn(kTSPlatform);



		fireEventDelegate = [TSIOSFireEventDelegate iosFireEventDelegateWithConfig:config
																			 queue:queue
																		  platform:platform
																 fireEventStrategy:fireEventStrategy
															   cookieMatchStrategy:cookieMatchStrategy
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
		[fireEventDelegate fireEvent:event];
		OCMVerify([event prepare:[OCMArg any]]);
	});

	it(@"Will cookie-match if attemptCookieMatch is true and shouldCookieMatch returns true", ^{

		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"OK" data:nil];

		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
		OCMStub([cookieMatchStrategy shouldFireCookieMatch]).andReturn(true);
		OCMStub([httpClient asyncSafariRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]).andReturn(true);
		config.attemptCookieMatch = true;

		OCMReject([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);

		fireEventBlocking(fireEventDelegate, event);

		OCMVerify([cookieMatchStrategy startCookieMatch]);
		OCMVerify([cookieMatchStrategy registerCookieMatchFired]);
		OCMVerify([fireEventStrategy registerFiringEvent:event]);
		OCMVerify([fireEventStrategy registerResponse:response forEvent:event]);
		OCMVerify([httpClient asyncSafariRequest:[OCMArg any] completion:[OCMArg any]]);
	});

	it(@"Will not cookie-match if attemptCookieMatch is false", ^{

		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"OK" data:nil];

		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
		OCMStub([cookieMatchStrategy shouldFireCookieMatch]).andReturn(true);
		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:([OCMArg invokeBlockWithArgs:response, nil])]);
		config.attemptCookieMatch = false;

		OCMReject([httpClient asyncSafariRequest:[OCMArg any] completion:[OCMArg any]]);
		OCMReject([cookieMatchStrategy startCookieMatch]);
		OCMReject([cookieMatchStrategy registerCookieMatchFired]);

		fireEventBlocking(fireEventDelegate, event);

		OCMVerify([fireEventStrategy registerFiringEvent:event]);
		OCMVerify([fireEventStrategy registerResponse:response forEvent:event]);
		OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);
	});

	it(@"Will not cookie-match if shouldFireCookieMatch returns false", ^{

		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"OK" data:nil];

		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
		OCMStub([cookieMatchStrategy shouldFireCookieMatch]).andReturn(false);
		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:([OCMArg invokeBlockWithArgs:response, nil])]);
		config.attemptCookieMatch = true;

		OCMReject([httpClient asyncSafariRequest:[OCMArg any] completion:[OCMArg any]]);
		OCMReject([cookieMatchStrategy startCookieMatch]);
		OCMReject([cookieMatchStrategy registerCookieMatchFired]);

		[fireEventDelegate fireEvent:event];
		block_until_queue_completed(queue);

		OCMVerify([fireEventStrategy registerFiringEvent:event]);
		OCMVerify([fireEventStrategy registerResponse:response forEvent:event]);
		OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);
	});

	it(@"Will only retry retryable fire event responses", ^{
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* errorResponse = [TSResponse responseWithStatus:500 message:@"Error" data:nil];
		TSResponse* badRequestResponse = [TSResponse responseWithStatus:400 message:@"Error" data:nil];
		TSResponse* okResponse = [TSResponse responseWithStatus:200 message:@"OK" data:nil];

		__block int firedCount = 0;

		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
		OCMStub([cookieMatchStrategy shouldFireCookieMatch]).andReturn(false);
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
