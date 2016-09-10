//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSDefs.h"
#import <Foundation/Foundation.h>
#import "TSHttpClient.h"
#import "TSResponse.h"
#import "TSURLBuilder.h"
#import "TSConfig.h"
#import "TSPlatform.h"
#import "TSLogging.h"
#import "TSTimelineLookupDelegate.h"


#define kTSDefaultTimeout 10000

@interface TSDefaultTimelineLookupDelegate()
@property(strong, readwrite) TSConfig* config;
@property(readwrite) dispatch_queue_t queue;
@property(strong, readwrite) id<TSPlatform> platform;
@property(strong, readwrite) id<TSHttpClient> httpClient;
@end


@implementation TSDefaultTimelineLookupDelegate
+ (instancetype)timelineLookupDelegateWithConfig:(TSConfig*)config
										   queue:(dispatch_queue_t)queue
										platform:(id<TSPlatform>)platform
									  httpClient:(id<TSHttpClient>)httpClient
{
	return [[self alloc] initWithConfig:config
								  queue:queue
							   platform:platform
							 httpClient:httpClient];
}

- (instancetype)initWithConfig:(TSConfig*)config
						 queue:(dispatch_queue_t)queue
					  platform:(id<TSPlatform>)platform
					httpClient:(id<TSHttpClient>)httpClient
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		self.queue = queue;
		self.platform = platform;
		self.httpClient = httpClient;
	}
	return self;
}
- (void)lookupTimeline:(void(^)(TSTimelineApiResponse *))completion
{
	if(completion == nil)
	{
		return;
	}

	dispatch_async(self.queue, ^{
		[self lookupTimeline:[completion copy] tries:3 timeout_ms:kTSDefaultTimeout];
	});
}

- (void)lookupTimeline:(void(^)(TSTimelineApiResponse *))completion tries:(int)tries timeout_ms:(int)timeout_ms
{
	NSURL* url = [TSURLBuilder makeConversionURL:self.config sessionId:[self.platform getSessionId]];
	[self.httpClient request:url data:nil method:@"GET" timeout_ms:timeout_ms tries:tries completion:^(TSResponse* response){
		if([response failed] && ![response retryable])
		{
			[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: 4XX while getting conversion data"];
		}

		// Run completion on the main thread
		dispatch_async(dispatch_get_main_queue(), ^{
			completion([TSTimelineApiResponse timelineApiResponseWithResponse:response]);
		});

	}];
}
@end