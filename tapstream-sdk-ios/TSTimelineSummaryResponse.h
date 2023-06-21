//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSTimelineSummaryResponse_h
#define TSTimelineSummaryResponse_h

#import "TSFallable.h"
#import "TSResponse.h"

@interface TSTimelineSummaryResponse : NSObject<TSFallable>
@property(readonly, strong)NSDictionary<NSString*, NSString*>* hitParams;
@property(readonly, strong)NSDictionary<NSString*, NSString*>* eventParams;
@property(readonly, strong)NSString* latestDeeplink;
@property(readonly)NSUInteger latestDeeplinkTimestamp;
@property(readonly, strong)NSArray<NSString*>* deeplinks;
@property(readonly, strong)NSArray<NSString*>* campaigns;
@property(readonly, strong)NSError* error;
+ (instancetype)timelineSummaryResponseWithResponse:(TSResponse*)response;
@end

#endif /* TSTimelineSummaryResponse_h */
