//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>

#import "TSConfig.h"
#import "TSPlatform.h"
#import "TSHttpClient.h"
#import "TSTimelineLookupDelegate.h"

TSTimelineApiResponse* getConversionDataBlocking(id<TSTimelineLookupDelegate> del)
{
	// Used for tests which expect cookie matching (which must run on the main thread)
	// Otherwise, just use block_until_queue_completed
	__block TSTimelineApiResponse* response = nil;

	[del lookupTimeline:^(TSTimelineApiResponse* r){
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

SpecBegin(TimelineLookupDelegate)


describe(@"TimelineLookupDelegate", ^{
	__block id<TSTimelineLookupDelegate> timelineLookupDelegate;
	__block TSConfig* config;
	__block id<TSHttpClient> httpClient;
	__block id<TSPlatform> platform;
	__block dispatch_queue_t queue;

	beforeEach(^{
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
		httpClient = OCMProtocolMock(@protocol(TSHttpClient));
		platform = OCMProtocolMock(@protocol(TSPlatform));
		queue = dispatch_queue_create("testq", DISPATCH_QUEUE_SERIAL);
		timelineLookupDelegate = [TSDefaultTimelineLookupDelegate timelineLookupDelegateWithConfig:config
																							 queue:queue
																						  platform:platform
																						httpClient:httpClient];
	});

	it(@"Will retrieve a Conversion response", ^{
		NSString* jsonStr = @"{\"hits\": [{\"name\": \"mytracker\"}], \"events\": [{\"name\": \"myevent\"}, {\"x\":\"y\"}]}";
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"OK" data:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]];


		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:([OCMArg invokeBlockWithArgs:response, nil])]);


		TSTimelineApiResponse* queryResponse = getConversionDataBlocking(timelineLookupDelegate);

		OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:[OCMArg any]]);
		assertThat(queryResponse, notNilValue());
		assertThatBool([queryResponse failed], isFalse());
		assertThatInteger([[queryResponse hits] count], equalToInteger(1));
		assertThatInteger([[queryResponse events] count], equalToInteger(2));
	});


	it(@"Will not complete a conversion with an error response", ^{

		TSResponse* response = [TSResponse responseWithStatus:400 message:@"Bad request" data:nil];


		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:([OCMArg invokeBlockWithArgs:response, nil])]);

		TSTimelineApiResponse* queryResponse = getConversionDataBlocking(timelineLookupDelegate);

		assertThat(queryResponse, notNilValue());
		OCMVerify([httpClient request:[OCMArg any] data:[OCMArg any] method:@"GET" timeout_ms:10000 tries:3 completion:[OCMArg any]]);
		assertThatBool([queryResponse failed], isTrue());
	});

});

SpecEnd
