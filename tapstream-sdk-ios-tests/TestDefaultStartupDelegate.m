//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>

#import "TSAppEventSource.h"
#import "TSFireEventDelegate.h"
#import "TSStartupDelegate.h"
#import "TSTestUtils.h"
#import "TSPlatform.h"
#import "TSConfig.h"
#import "TSDefs.h"


SpecBegin(DefaultStartupDelegate)

describe(@"DefaultStartupDelegate", ^{
	__block TSDefaultStartupDelegate* startupDelegate;
	__block TSConfig* config;
	__block dispatch_queue_t queue;
	__block id<TSPlatform> platform;
	__block id<TSFireEventDelegate> fireEventDelegate;
	__block id<TSAppEventSource> appEventSource;


	beforeEach(^{
		platform = OCMProtocolMock(@protocol(TSPlatform));
		appEventSource = OCMProtocolMock(@protocol(TSAppEventSource));
		queue = dispatch_queue_create("testq", DISPATCH_QUEUE_SERIAL);
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
		OCMStub([platform getAppName]).andReturn(@"testapp");
		OCMStub([platform getPlatformName]).andReturn(kTSPlatform);

		fireEventDelegate = OCMProtocolMock(@protocol(TSFireEventDelegate));

		startupDelegate = [TSDefaultStartupDelegate defaultStartupDelegateWithConfig:config
																			platform:platform
																   fireEventDelegate:fireEventDelegate
																	  appEventSource:appEventSource];
	});

	it(@"Calls [platform registerFirstRun] on first run", ^{
		OCMStub([platform isFirstRun]).andReturn(true);
		[startupDelegate start];
		block_until_queue_completed(queue);
		OCMVerify([platform registerFirstRun]);
	});

	it(@"Does not call registerFirstRun on other runs", ^{
		OCMStub([platform isFirstRun]).andReturn(false);
		OCMReject([platform registerFirstRun]);

		[startupDelegate start];
		block_until_queue_completed(queue);
	});

	it(@"Fires a first-run event called <appname>-ios-install if first run", ^{
		OCMStub([platform isFirstRun]).andReturn(true);

		BOOL (^checkEventName)(id) = ^BOOL(id arg){
			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-install", [kTSPlatform lowercaseString]];
			return [((TSEvent*)arg).name isEqualToString:eventName];
		};

		[startupDelegate start];
		block_until_queue_completed(queue);

		OCMVerify([fireEventDelegate fireEvent:([OCMArg checkWithBlock:checkEventName])]);
	});

	it(@"Fires no install event on startup if not first run", ^{
		OCMStub([platform isFirstRun]).andReturn(false);

		BOOL (^checkEventName)(id) = ^BOOL(id arg){
			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-install", [kTSPlatform lowercaseString]];
			return [((TSEvent*)arg).name isEqualToString:eventName];
		};

		OCMReject([fireEventDelegate fireEvent:([OCMArg checkWithBlock:checkEventName])]);

		[startupDelegate start];
		block_until_queue_completed(queue);
	});

	it(@"Does not fire a first-run install event if fireAutomaticInstallEvent is false", ^{
		OCMStub([platform isFirstRun]).andReturn(true);

		config.fireAutomaticInstallEvent = false;

		BOOL (^checkEventName)(id) = ^BOOL(id arg){
			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-install", [kTSPlatform lowercaseString]];
			return [((TSEvent*)arg).name isEqualToString:eventName];
		};

		OCMReject([fireEventDelegate fireEvent:([OCMArg checkWithBlock:checkEventName])]);

		[startupDelegate start];
		block_until_queue_completed(queue);
	});

	it(@"Fires an open event on start", ^{
		OCMStub([platform isFirstRun]).andReturn(false);

		BOOL (^checkEventName)(id) = ^BOOL(id arg){
			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-open", [kTSPlatform lowercaseString]];
			BOOL ok = [((TSEvent*)arg).name isEqualToString:eventName];
			return ok;
		};

		[startupDelegate start];
		block_until_queue_completed(queue);

		OCMVerify([fireEventDelegate fireEvent:([OCMArg checkWithBlock:checkEventName])]);
	});

	it(@"Does not fire an open event on start if fireAutomaticOpenEvent is false", ^{
		OCMStub([platform isFirstRun]).andReturn(false);

		config.fireAutomaticOpenEvent = false;

		BOOL (^checkEventName)(id) = ^BOOL(id arg){
			NSString* eventName = [NSString stringWithFormat:@"%@-testapp-open", kTSPlatform];
			return [((TSEvent*)arg).name isEqualToString:eventName];
		};

		OCMReject([fireEventDelegate fireEvent:([OCMArg checkWithBlock:checkEventName])]);

		[startupDelegate start];
		block_until_queue_completed(queue);
		
	});

});

SpecEnd
