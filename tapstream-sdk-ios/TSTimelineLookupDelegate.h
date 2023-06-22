//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSTimelineLookupDelegate_h
#define TSTimelineLookupDelegate_h

#import "TSTimelineApiResponse.h"
#import "TSTimelineSummaryResponse.h"

@protocol TSTimelineLookupDelegate
- (void)lookupTimeline:(void(^)(TSTimelineApiResponse*))completion;
- (void)getTimelineSummary:(void(^)(TSTimelineSummaryResponse*))completion;
@end

@interface TSDefaultTimelineLookupDelegate : NSObject<TSTimelineLookupDelegate>
+ (instancetype)timelineLookupDelegateWithConfig:(TSConfig*)config
										   queue:(dispatch_queue_t)queue
										platform:(id<TSPlatform>)platform
									  httpClient:(id<TSHttpClient>)httpClient;
@end

#endif /* TSTimelineLookupDelegate_h */
