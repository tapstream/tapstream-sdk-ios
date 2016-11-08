//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>

#import "TSResponse.h"
#import "TSConfig.h"
#import "TSHttpClient.h"
#import "TSPlatform.h"
#import "TSLanderController.h"
#import "TSIOSUniversalLinkDelegate.h"

TSUniversalLinkApiResponse* handleUniversalLinkBlocking(TSIOSUniversalLinkDelegate* del, NSUserActivity* userActivity)
{
	__block TSUniversalLinkApiResponse* ul;
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);
	[del handleUniversalLink:userActivity completion:^(TSUniversalLinkApiResponse* u){
		ul = u;
		dispatch_semaphore_signal(sem);
	}];
	dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1));

	return ul;
}

SpecBegin(UniversalLinkDelegate)

describe(@"UniversalLinkDelegate", ^{
	__block TSConfig* config;
	__block id<TSHttpClient> httpClient;
	__block id<TSPlatform> platform;
	__block TSIOSUniversalLinkDelegate* universalLinkDelegate;
	__block NSUserActivity* activity;
	__block NSString* sessionId;

	beforeEach(^{

		sessionId = [[NSUUID UUID] UUIDString];
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
		httpClient = OCMProtocolMock(@protocol(TSHttpClient));
		platform = OCMProtocolMock(@protocol(TSPlatform));
		activity = OCMClassMock([NSUserActivity class]);
		OCMStub([activity activityType]).andReturn(NSUserActivityTypeBrowsingWeb);
		OCMStub([platform getSessionId]).andReturn(sessionId);

		universalLinkDelegate = [TSIOSUniversalLinkDelegate
								 universalLinkDelegateWithConfig:config
								 platform:platform
								 httpClient:httpClient];
	});

	it(@"Returns a kTSStatusUnknown for non-browsing NSUserActivity", ^{
		id activity = OCMClassMock([NSUserActivity class]);
		OCMStub([activity activityType]).andReturn(@"some activity type");

		TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(universalLinkDelegate, activity);
		assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
	});

	it(@"Returns a kTSStatusUnknown for a nil websiteURL", ^{
		OCMStub([activity webpageURL]).andReturn(nil);
		OCMReject([httpClient request:[OCMArg any] completion:[OCMArg any]]);

		TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(universalLinkDelegate, activity);
		assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
	});

	it(@"Returns a kTSStatusUnknown for a bad response", ^{
		OCMStub([activity webpageURL]).andReturn(nil);
		TSResponse* response = [TSResponse responseWithStatus:400 message:@"" data:nil];

		OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

		TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(universalLinkDelegate, activity);
		assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
	});

	it(@"Returns a kTSStatusUnknown for an invalid registered url", ^{
		OCMStub([activity webpageURL]).andReturn([NSURL URLWithString:@"http://example.com/myshortlink"]);
		NSString* jsonResponse = @"{\"registered_url\": null, \"fallback_url\": null, \"enable_universal_links\": true}";

		TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:[jsonResponse dataUsingEncoding:NSUTF8StringEncoding]];

		OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

		TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(universalLinkDelegate, activity);
		assertThatInteger(ul.status, equalToInteger(kTSULUnknown));
	});
	it(@"Returns a kTSStatusDisabled for a disabled UL", ^{
		OCMStub([activity webpageURL]).andReturn([NSURL URLWithString:@"http://example.com/myshortlink"]);
		NSString* jsonResponse = @"{\"registered_url\": \"myurl://\", \"fallback_url\": \"http://example.com/\", \"enable_universal_links\": false}";

		TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:[jsonResponse dataUsingEncoding:NSUTF8StringEncoding]];

		OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

		TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(universalLinkDelegate, activity);
		assertThatInteger(ul.status, equalToInteger(kTSULDisabled));
	});
	it(@"Returns a kTSStatusEnabled for a valid and enabled UL", ^{
		OCMStub([activity webpageURL]).andReturn([NSURL URLWithString:@"http://example.com/myshortlink"]);
		NSString* jsonResponse = @"{\"registered_url\": \"myurl://\", \"fallback_url\": \"http://example.com/\", \"enable_universal_links\": true}";

		TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:[jsonResponse dataUsingEncoding:NSUTF8StringEncoding]];

		OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:response, nil])]);

		TSUniversalLinkApiResponse* ul = handleUniversalLinkBlocking(universalLinkDelegate, activity);
		assertThatInteger(ul.status, equalToInteger(kTSULValid));
		assertThat(ul.deeplinkURL, is([NSURL URLWithString:@"myurl://"]));
	});

});

SpecEnd
