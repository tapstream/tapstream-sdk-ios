//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSWordOfMouthController.h"

void blockUntilNotNil(void* ptr, int secondsToWait)
{
	NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:secondsToWait];
	while (ptr == nil && [loopUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:loopUntil];
	}
}

TSOfferApiResponse* getOfferForInsertionPointBlocking(TSWordOfMouthController* controller, NSString* insertionPoint)
{
	__block TSOfferApiResponse* response = nil;

	[controller getOfferForInsertionPoint:insertionPoint completion:^(TSOfferApiResponse* r){
		response = r;
	}];

	blockUntilNotNil((__bridge void *)(response), 1);

	return response;
}

TSRewardApiResponse* getRewardListBlocking(TSWordOfMouthController* controller)
{
	__block TSRewardApiResponse* response = nil;

	[controller getRewardList:^(TSRewardApiResponse* r) {
		response = r;
	}];

	blockUntilNotNil((__bridge void *)(response), 1);
	return response;
}

SpecBegin(WordOfMouthController)

describe(@"WordOfMouthController", ^{

	NSString* sessionId = @"my-session-id";
	NSString* bundle = @"com.my.bundle";

	__block TSConfig* config;
	__block id<TSPlatform> platform;
	__block id<TSOfferStrategy> offerStrategy;
	__block id<TSRewardStrategy> rewardStrategy;
	__block id<TSHttpClient> httpClient;
	__block TSWordOfMouthController* controller;

	beforeEach(^{
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
		platform = OCMProtocolMock(@protocol(TSPlatform));
		offerStrategy = OCMProtocolMock(@protocol(TSOfferStrategy));
		rewardStrategy = OCMProtocolMock(@protocol(TSRewardStrategy));
		httpClient = OCMProtocolMock(@protocol(TSHttpClient));


		OCMStub([platform getSessionId]).andReturn(sessionId);
		OCMStub([platform getBundleIdentifier]).andReturn(bundle);

		controller = [[TSWordOfMouthController alloc]
					  initWithConfig:config
					  platform:platform
					  offerStrategy:offerStrategy
					  rewardStrategy:rewardStrategy
					  httpClient:httpClient];
	});

	it(@"Gracefully handles a nil response", ^{
		TSResponse* r = [TSResponse responseWithStatus:200 message:@"ok" data:nil];
		OCMStub([httpClient request:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:r, nil])]);
		TSOfferApiResponse* resp = getOfferForInsertionPointBlocking(controller, @"my-ins-pt");

		assertThatBool([resp failed], isTrue());
		assertThat(resp, notNilValue());
	});

});

SpecEnd
