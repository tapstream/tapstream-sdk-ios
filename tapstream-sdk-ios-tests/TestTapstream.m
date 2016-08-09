//  Copyright © 2016 Tapstream. All rights reserved.

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "TapstreamIOS.h"
#else
#import "TapstreamMac.h"
#endif
#import "TSURLBuilder.h"
#import "TSFireEventStrategy.h"
#import "TSLanderController.h"


@interface TSEvent()
- (void)prepare:(NSDictionary*)globalEventParams;
@end

@interface TSTapstream()
@property(nonatomic) dispatch_queue_t queue;
@property(nonatomic) NSString* platformName;
- (void)start;
- (id)initWithPlatform:(id<TSPlatform>)platform
			  listener:(id<TSCoreListener>)listener
		appEventSource:(id<TSAppEventSource>)appEventSource
   cookieMatchStrategy:(id<TSCookieMatchStrategy>)cookieMatchStrategy
	 fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		landerStrategy:(id<TSLanderStrategy>)landerStrategy
 wordOfMouthController:(TSWordOfMouthController*)womController
#endif
			httpClient:(id<TSHttpClient>)httpClient
				config:(TSConfig *)config;
@end


void block_until_queue_completed(dispatch_queue_t queue)
{
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);

	// Wait 100 ms to send signal
	double t = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1);
	dispatch_after(t, queue, ^{
		dispatch_semaphore_signal(sem);
	});

	// Wait 1s to receive signal
	double t2 = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
	dispatch_semaphore_wait(sem, t2);
}

void fireEventBlocking(TSTapstream* tapstream, TSEvent* event)
{
	// Used for tests which expect cookie matching (which must run on the main thread)
	// Otherwise, just use block_until_queue_completed
	__block bool hasCompleted = false;

	[tapstream fireEvent:event completion:^(TSResponse* response){
		hasCompleted = true;
	}];

	// Wait 1 second or until completed
	NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
	while (!hasCompleted && [loopUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:loopUntil];
	}
}

TSTimelineApiResponse* getConversionDataBlocking(TSTapstream* tapstream)
{
	// Used for tests which expect cookie matching (which must run on the main thread)
	// Otherwise, just use block_until_queue_completed
	__block TSTimelineApiResponse* response = nil;

	[tapstream lookupTimeline:^(TSTimelineApiResponse* r){
		response = r;
	}];

	// Wait 1 second or until completed
	NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
	while (response == nil && [loopUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:loopUntil];
	}
	return response;
}

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
TSUniversalLinkApiResponse* handleUniversalLinkBlocking(TSTapstream* tapstream, NSUserActivity* userActivity)
{
	__block TSUniversalLinkApiResponse* ul;
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);
	[tapstream handleUniversalLink:userActivity completion:^(TSUniversalLinkApiResponse* u){
		ul = u;
		dispatch_semaphore_signal(sem);
	}];
	dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1));

	return ul;
}
#endif

SpecBegin(Tapstream)

describe(@"Tapstream", ^{


	__block id<TSPlatform> platform;
	__block id<TSCoreListener> listener;
	__block id<TSAppEventSource> appEventSource;
	__block id<TSCookieMatchStrategy> cookieMatchStrategy;
	__block id<TSFireEventStrategy> fireEventStrategy;
	__block id<TSHttpClient> httpClient;
	__block TSTapstream* tapstream;
	__block TSConfig* config;

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	__block id<TSOfferStrategy> offerStrategy;
	__block id<TSRewardStrategy> rewardStrategy;
	__block id<TSLanderStrategy> landerStrategy;
#endif


	beforeEach(^{
		platform = OCMProtocolMock(@protocol(TSPlatform));
		listener = OCMProtocolMock(@protocol(TSCoreListener));
		appEventSource = OCMProtocolMock(@protocol(TSAppEventSource));

		cookieMatchStrategy = OCMProtocolMock(@protocol(TSCookieMatchStrategy));

		fireEventStrategy = OCMProtocolMock(@protocol(TSFireEventStrategy));

		httpClient = OCMProtocolMock(@protocol(TSHttpClient));
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];

		OCMStub([platform getSessionId]).andReturn(@"mysessionid");

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		offerStrategy = OCMProtocolMock(@protocol(TSOfferStrategy));
		rewardStrategy = OCMProtocolMock(@protocol(TSRewardStrategy));
		landerStrategy = OCMProtocolMock(@protocol(TSLanderStrategy));

		TSWordOfMouthController* womController = [[TSWordOfMouthController alloc] initWithConfig:config platform:platform offerStrategy:offerStrategy rewardStrategy:rewardStrategy httpClient:httpClient];

		tapstream = [[TSTapstream alloc]		initWithPlatform:platform
												 listener:listener
										   appEventSource:appEventSource
									  cookieMatchStrategy:cookieMatchStrategy
										fireEventStrategy:fireEventStrategy
										   landerStrategy:landerStrategy
									wordOfMouthController:womController
											   httpClient:httpClient
												   config:config];

#else
		tapstream = [[TSTapstream alloc]		initWithPlatform:platform
												  listener:listener
											appEventSource:appEventSource
									   cookieMatchStrategy:cookieMatchStrategy
										 fireEventStrategy:fireEventStrategy
												httpClient:httpClient
													config:config];
#endif

	});

	describe(@"Startup behavior", ^{

		it(@"Calls [platform registerFirstRun] on first run", ^{
			OCMStub([platform isFirstRun]).andReturn(true);
			[tapstream start];
			block_until_queue_completed([tapstream queue]);
			OCMVerify([platform registerFirstRun]);
		});

		it(@"Does not call registerFirstRun on other runs", ^{
			OCMStub([platform isFirstRun]).andReturn(false);
			OCMReject([platform registerFirstRun]);

			[tapstream start];
			block_until_queue_completed([tapstream queue]);
		});
		it(@"Does not attempt to cookie match if config.attemptCookieMatch is false", ^{
			OCMStub([platform isFirstRun]).andReturn(true);
			config.attemptCookieMatch = false;

			OCMReject([cookieMatchStrategy registerCookieMatchFired]);
			OCMReject([httpClient asyncSafariRequest:[OCMArg any] completion:[OCMArg any]]);

			[tapstream start];
			block_until_queue_completed([tapstream queue]);
		});

		it(@"Does attempt to cookie match if config.attemptCookieMatch is true", ^{
			OCMStub([platform isFirstRun]).andReturn(true);
			TSResponse* response = [TSResponse responseWithStatus:200 message:@"200 OK" data:nil];
			OCMStub([httpClient asyncSafariRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

			config.attemptCookieMatch = true;

			[tapstream start];
			block_until_queue_completed([tapstream queue]);

			OCMVerify([cookieMatchStrategy registerCookieMatchFired]);
			OCMVerify([httpClient asyncSafariRequest:[OCMArg any] completion:[OCMArg any]]);
		});

		it(@"Fires a first-run event called <appname>-ios-install if first run", ^{
			OCMStub([platform isFirstRun]).andReturn(true);
			OCMStub([platform getAppName]).andReturn(@"testapp");
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
			config.attemptCookieMatch = false;

			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-install", [tapstream platformName]];
			NSURL* expectedURL = [TSURLBuilder makeEventURL:config eventName:eventName];

			[tapstream start];
			block_until_queue_completed([tapstream queue]);

			OCMVerify([httpClient request:expectedURL data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);
		});

		it(@"Fires no install event on startup if not first run", ^{
			OCMStub([platform isFirstRun]).andReturn(false);
			OCMStub([platform getAppName]).andReturn(@"testapp");
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
			config.attemptCookieMatch = false;
			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-install", [tapstream platformName]];

			// Reject install event
			NSURL* expectedURL = [TSURLBuilder makeEventURL:config eventName:eventName];
			OCMReject([httpClient request:expectedURL data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);

			[tapstream start];
			block_until_queue_completed([tapstream queue]);
		});

		it(@"Does not fire a first-run install event if fireAutomaticInstallEvent is false", ^{
			OCMStub([platform isFirstRun]).andReturn(true);
			OCMStub([platform getAppName]).andReturn(@"testapp");
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
			config.attemptCookieMatch = false;
			config.fireAutomaticInstallEvent = false;

			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-install", [tapstream platformName]];
			// Reject install event
			NSURL* expectedURL = [TSURLBuilder makeEventURL:config eventName:eventName];
			OCMReject([httpClient request:expectedURL data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);

			[tapstream start];
			block_until_queue_completed([tapstream queue]);
		});

		it(@"Fires an open event on start", ^{
			OCMStub([platform isFirstRun]).andReturn(false);
			OCMStub([platform getAppName]).andReturn(@"testapp");
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
			config.attemptCookieMatch = false;

			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-open", [tapstream platformName]];
			NSURL* expectedURL = [TSURLBuilder makeEventURL:config eventName:eventName];

			[tapstream start];
			block_until_queue_completed([tapstream queue]);

			OCMVerify([httpClient request:expectedURL data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);
		});

		it(@"Does not fire an open event on start if fireAutomaticOpenEvent is false", ^{
			OCMStub([platform isFirstRun]).andReturn(false);
			OCMStub([platform getAppName]).andReturn(@"testapp");
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
			config.attemptCookieMatch = false;
			config.fireAutomaticOpenEvent = false;

			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-open", [tapstream platformName]];
			NSURL* expectedURL = [TSURLBuilder makeEventURL:config eventName:eventName];

			OCMReject([httpClient request:expectedURL data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);

			[tapstream start];
			block_until_queue_completed([tapstream queue]);

		});
	});

	describe(@"FireEvent behavior", ^{
		it(@"Will not fire an event if shouldFireEvent returns false", ^{
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(false);
			TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];

			OCMReject([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);
			[tapstream fireEvent:event];
			block_until_queue_completed([tapstream queue]);
		});

		it(@"Calls prepare on the event when it is fired", ^{
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(false);
			TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
			[tapstream fireEvent:event];
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

			fireEventBlocking(tapstream, event);

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

			fireEventBlocking(tapstream, event);

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

			[tapstream fireEvent:event];
			block_until_queue_completed([tapstream queue]);

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

			[tapstream fireEvent:event];
			block_until_queue_completed([tapstream queue]);

			assertThatInteger(firedCount, equalToInteger(2));
			OCMVerify([fireEventStrategy registerFiringEvent:event]);
			OCMVerify([fireEventStrategy registerResponse:errorResponse forEvent:event]);
			OCMVerify([fireEventStrategy registerResponse:badRequestResponse forEvent:event]);
		});
	});
	
	describe(@"Timeline lookup", ^{

		it(@"Will retrieve a Conversion response", ^{
			NSString* jsonStr = @"{\"hits\": [{\"name\": \"mytracker\"}], \"events\": [{\"name\": \"myevent\"}, {\"x\":\"y\"}]}";
			TSResponse* response = [TSResponse responseWithStatus:200 message:@"OK" data:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]];


			OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:([OCMArg invokeBlockWithArgs:response, nil])]);
			

			TSTimelineApiResponse* queryResponse = getConversionDataBlocking(tapstream);

			OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:[OCMArg any]]);
			assertThat(queryResponse, notNilValue());
			assertThatBool([queryResponse failed], isFalse());
			assertThatInteger([[queryResponse hits] count], equalToInteger(1));
			assertThatInteger([[queryResponse events] count], equalToInteger(2));
		});


		it(@"Will not complete a conversion with an error response", ^{

			TSResponse* response = [TSResponse responseWithStatus:400 message:@"Bad request" data:nil];


			OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:([OCMArg invokeBlockWithArgs:response, nil])]);

			TSTimelineApiResponse* queryResponse = getConversionDataBlocking(tapstream);

			assertThat(queryResponse, notNilValue());
			OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:[OCMArg any]]);
			assertThatBool([queryResponse failed], isTrue());
		});
		
	});

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	describe(@"Show Lander", ^{
		NSString* landerResponse = @"{\"url\": null, \"markup\": \"<h1>Ok</h1>\", \"id\": 31}";
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"OK" data:[landerResponse dataUsingEncoding:NSUTF8StringEncoding]];

		beforeEach(^{
			// Stub UI Window to prevent crash
			id uiWindow = OCMClassMock([UIWindow class]);
			OCMStub([uiWindow alloc]).andReturn(uiWindow);
			OCMStub([uiWindow initWithFrame:[UIScreen mainScreen].bounds]).andReturn(uiWindow);
		});

		it(@"Will properly show a lander", ^{
			OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 completion:([OCMArg invokeBlockWithArgs:response, nil])]);
			OCMStub([landerStrategy shouldShowLander:[OCMArg any]]).andReturn(true);

			id landerController = OCMClassMock([TSLanderController class]);
			OCMStub([landerController controllerWithLander:[OCMArg any] delegate:[OCMArg any]]).andReturn(landerController);

			id delegate = OCMProtocolMock(@protocol(TSLanderDelegate));

			[tapstream showLanderIfExistsWithDelegate:delegate];
			block_until_queue_completed([tapstream queue]);

			// Wait 10ms for the call to landerController
			NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.01];
			while ([loopUntil timeIntervalSinceNow] > 0) {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
										 beforeDate:loopUntil];
			}

			OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 completion:[OCMArg any]]);

			OCMVerify([landerController controllerWithLander:([OCMArg checkWithBlock:^BOOL(id it){
				TSLander* lander = (TSLander*) it;
				return [lander ident] == 31 && [@"<h1>Ok</h1>" isEqualToString:[lander html]];
			}]) delegate:([OCMArg checkWithBlock:^BOOL(id del){
				return [del delegate] == delegate;
			}])]);
		});

		it(@"Will respect the shouldShowLander check", ^{

			OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 completion:([OCMArg invokeBlockWithArgs:response, nil])]);
			OCMStub([landerStrategy shouldShowLander:[OCMArg any]]).andReturn(false);

			id delegate = OCMProtocolMock(@protocol(TSLanderDelegate));
			id landerController = OCMClassMock([TSLanderController class]);

			OCMReject([landerController controllerWithLander:([OCMArg checkWithBlock:^BOOL(id it){
				TSLander* lander = (TSLander*) it;
				return [lander ident] == 31 && [@"<h1>Ok</h1>" isEqualToString:[lander html]];
			}]) delegate:([OCMArg checkWithBlock:^BOOL(id del){
				return [del delegate] == delegate;
			}])]);




			[tapstream showLanderIfExistsWithDelegate:delegate];
			block_until_queue_completed([tapstream queue]);


			// Wait 10ms for the call to landerController
			NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.01];
			while ([loopUntil timeIntervalSinceNow] > 0) {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
										 beforeDate:loopUntil];
			}

			OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 completion:[OCMArg any]]);

		});
	});

	describe(@"handleUniversalLink", ^{
		__block NSUserActivity* activity;
		beforeEach(^{
			activity = OCMClassMock([NSUserActivity class]);
			OCMStub([activity activityType]).andReturn(NSUserActivityTypeBrowsingWeb);
		});

		it(@"Returns a kTSStatusUnknown for non-browsing NSUserActivity", ^{
			id activity = OCMClassMock([NSUserActivity class]);
			OCMStub([activity activityType]).andReturn(@"some activity type");

			TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(tapstream, activity);
			assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
		});

		it(@"Returns a kTSStatusUnknown for a nil websiteURL", ^{
			OCMStub([activity webpageURL]).andReturn(nil);
			OCMReject([httpClient request:[OCMArg any] completion:[OCMArg any]]);

			TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(tapstream, activity);
			assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
		});

		it(@"Returns a kTSStatusUnknown for a bad response", ^{
			OCMStub([activity webpageURL]).andReturn(nil);
			TSResponse* response = [TSResponse responseWithStatus:400 message:@"" data:nil];

			OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

			TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(tapstream, activity);
			assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
		});

		it(@"Returns a kTSStatusUnknown for an invalid registered url", ^{
			OCMStub([activity webpageURL]).andReturn([NSURL URLWithString:@"http://example.com/myshortlink"]);
			NSString* jsonResponse = @"{\"registered_url\": null, \"fallback_url\": null, \"enable_universal_links\": true}";

			TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:[jsonResponse dataUsingEncoding:NSUTF8StringEncoding]];

			OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

			TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(tapstream, activity);
			assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
		});
		it(@"Returns a kTSStatusDisabled for a disabled UL", ^{
			OCMStub([activity webpageURL]).andReturn([NSURL URLWithString:@"http://example.com/myshortlink"]);
			NSString* jsonResponse = @"{\"registered_url\": \"myurl://\", \"fallback_url\": \"http://example.com/\", \"enable_universal_links\": false}";

			TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:[jsonResponse dataUsingEncoding:NSUTF8StringEncoding]];

			OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

			TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(tapstream, activity);
			assertThatInteger(ul.status, equalToInteger(kTSULDisabled));
		});
		it(@"Returns a kTSStatusEnabled for a valid and enabled UL", ^{
			OCMStub([activity webpageURL]).andReturn([NSURL URLWithString:@"http://example.com/myshortlink"]);
			NSString* jsonResponse = @"{\"registered_url\": \"myurl://\", \"fallback_url\": \"http://example.com/\", \"enable_universal_links\": true}";

			TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:[jsonResponse dataUsingEncoding:NSUTF8StringEncoding]];

			OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

			TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(tapstream, activity);
			assertThatInteger(ul.status, equalToInteger(kTSULValid));
			assertThat(ul.deeplinkURL, is([NSURL URLWithString:@"myurl://"]));
		});
	});

#endif
});

SpecEnd

/*
#import "TSPlatform.h"
#import "TSPlatformImpl.h"
#import "TSCoreListenerImpl.h"
#import "TSAppEventSourceImpl.h"
#import "TSCoreListener.h"
#import "TSCore.h"
#import "TSLander.h"
#import <OCMock/OCMock.h>

@interface TSDelegateTestImpl : NSObject<TSDelegate>
- (int)getDelay;
- (void)setDelay:(int)delay;
- (BOOL)isRetryAllowed;
@end

@implementation TSDelegateTestImpl
- (int)getDelay {return 0;}
- (void)setDelay:(int)delay {}
- (BOOL)isRetryAllowed { return true; }
@end

@interface TSPlatformTestImpl : NSObject<TSPlatform>
@property(nonatomic, strong) id<TSPlatform> delegate;
@property(nonatomic) BOOL firstRun;
@property(nonatomic, strong) NSMutableArray<NSArray<NSString*>*>* requests;
- (NSMutableArray*)getRequests;
@end

@implementation TSPlatformTestImpl
- (TSPlatformTestImpl*)initWithDelegate:(id<TSPlatform>) delegate
{
	self = [super init];
	self.delegate = delegate;
	self.requests = [[NSMutableArray alloc] initWithCapacity:10];
	self.firstRun = true;
	return self;
}

- (TSResponse *)request:(NSString *)url data:(NSString *)data method:(NSString *)method timeout_ms:(int)timeout_ms
{

	NSArray<NSString*>* requestData = [[NSArray alloc] initWithObjects:url, data, method, nil];
	[self.requests addObject:requestData];
	return [[TSResponse alloc] initWithStatus:200 message:@"ok" data:nil];
}

- (BOOL)fireCookieMatch:(NSURL*)url completion:(void(^)(TSResponse*))completion
{
	NSArray* requestData = [[NSArray alloc] initWithObjects:[url absoluteString], @"", @"GET", nil];
	[self.requests addObject: requestData];
	completion([[TSResponse alloc] initWithStatus:200 message:@"ok" data:nil]);
	return true;
}

- (NSMutableArray*)getRequests
{
	return self.requests;
}

- (void)setPersistentFlagVal:(NSString*)key{ [self.delegate setPersistentFlagVal:key]; }
- (BOOL)getPersistentFlagVal:(NSString*)key{ return [self.delegate getPersistentFlagVal:key]; }
- (BOOL) isFirstRun{ return self.firstRun; }
- (void) registerFirstRun{ self.firstRun = false; }
- (NSString *)loadUuid{ return [self.delegate loadUuid]; }
- (NSMutableSet *)loadFiredEvents{ return [self.delegate loadFiredEvents]; }
- (void)saveFiredEvents:(NSMutableSet *)firedEvents{ [self.delegate saveFiredEvents:firedEvents]; }
- (NSString *)getResolution{ return [self.delegate getResolution]; }
- (NSString *)getManufacturer{ return [self.delegate getManufacturer]; }
- (NSString *)getModel{ return [self.delegate getModel]; }
- (NSString *)getOs{ return [self.delegate getOs]; }
- (NSString *)getOsBuild{ return [self.delegate getOsBuild]; }
- (NSString *)getLocale{ return [self.delegate getLocale]; }
- (NSString *)getWifiMac{ return [self.delegate getWifiMac]; }
- (NSString *)getAppName{ return [self.delegate getAppName]; }
- (NSString *)getAppVersion{ return [self.delegate getAppVersion]; }
- (NSString *)getPackageName{ return [self.delegate getPackageName]; }
- (NSString *)getComputerGUID{ return [self.delegate getComputerGUID]; }
- (NSString *)getBundleIdentifier{ return [self.delegate getBundleIdentifier]; }
- (NSString *)getBundleShortVersion{ return [self.delegate getBundleShortVersion]; }
- (BOOL)landerShown:(NSUInteger)landerId{ return [self.delegate landerShown:landerId]; }
- (void)setLanderShown:(NSUInteger)landerId{ [self.delegate setLanderShown:landerId]; }

- (BOOL) shouldCookieMatch{ return [self.delegate shouldCookieMatch]; }
- (void)setCookieMatchFired:(NSTimeInterval)t{ [self.delegate setCookieMatchFired:t]; }


@end


@interface TapstreamIOSTestTests : XCTestCase
@property(nonatomic, strong) id<TSDelegate> del;
@property(nonatomic, strong) TSPlatformTestImpl<TSPlatform>* platform;
@property(nonatomic, strong) id<TSCoreListener> listener;
@property(nonatomic, strong) id<TSAppEventSource> appEventSource;
@property(nonatomic, strong) TSCore* core;
@property(nonatomic, strong) id mockedDefaults;
@end

@implementation TapstreamIOSTestTests

- (void)initCore:(TSConfig*) config
{
	self.core = AUTORELEASE([[TSCore alloc] initWithDelegate:self.del
													platform:self.platform
													listener:self.listener
											  appEventSource:self.appEventSource
												 accountName:@"sdktest"
											 developerSecret:@""
													  config:config]);
}

- (void)setUp {
    [super setUp];

	self.del = [[TSDelegateTestImpl alloc] init];
	self.platform = [[TSPlatformTestImpl alloc] initWithDelegate:[[TSPlatformImpl alloc] init]];
	self.listener = [[TSCoreListenerImpl alloc] init];
	self.appEventSource = [[TSAppEventSourceImpl alloc] init];
	self.mockedDefaults = OCMClassMock([NSUserDefaults class]);
	OCMStub([self.mockedDefaults standardUserDefaults]).andReturn(self.mockedDefaults);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}




@end
*/
