//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>

#import "TSResponse.h"
#import "TSConfig.h"
#import "TSHttpClient.h"
#import "TSPlatform.h"
#import "TSLanderController.h"
#import "TSIOSShowLanderDelegate.h"


SpecBegin(ShowLanderDelegate)

describe(@"ShowLanderDelegate", ^{
	__block TSConfig* config;
	__block id<TSPlatform> platform;
	__block id<TSLanderStrategy> landerStrategy;
	__block id<TSHttpClient> httpClient;
	__block TSIOSShowLanderDelegate* showLanderDelegate;

	NSString* landerResponse = @"{\"url\": null, \"markup\": \"<h1>Ok</h1>\", \"id\": 31}";
	TSResponse* response = [TSResponse responseWithStatus:200 message:@"OK" data:[landerResponse dataUsingEncoding:NSUTF8StringEncoding]];

	beforeEach(^{

		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];

		platform = OCMProtocolMock(@protocol(TSPlatform));
		landerStrategy = OCMProtocolMock(@protocol(TSLanderStrategy));
		httpClient = OCMProtocolMock(@protocol(TSHttpClient));

		showLanderDelegate = [TSIOSShowLanderDelegate showLanderDelegateWithConfig:config
																		  platform:platform
																	landerStrategy:landerStrategy
																		httpClient:httpClient];

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

		[showLanderDelegate showLanderIfExistsWithDelegate:delegate];

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


		[showLanderDelegate showLanderIfExistsWithDelegate:delegate];


		// Wait 10ms for the call to landerController
		NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.01];
		while ([loopUntil timeIntervalSinceNow] > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:loopUntil];
		}

		OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 completion:[OCMArg any]]);

	});
});

SpecEnd
