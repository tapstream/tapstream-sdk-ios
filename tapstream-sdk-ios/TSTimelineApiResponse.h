//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSTimelineApiResponse_h
#define TSTimelineApiResponse_h

#import "TSFallable.h"
#import "TSResponse.h"

@interface TSTimelineApiResponse : NSObject<TSFallable>
@property(readonly, strong)NSArray* hits;
@property(readonly, strong)NSArray* events;
@property(readonly, strong)NSError* error;
+ (instancetype)timelineApiResponseWithResponse:(TSResponse*)response;
@end

#endif /* TSTimelineApiResponse_h */
