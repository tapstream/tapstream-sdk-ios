//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSRewardApiResponse_h
#define TSRewardApiResponse_h

#import "TSReward.h"
#import "TSResponse.h"
#import "TSFallable.h"
#import "TSRewardStrategy.h"

@interface TSRewardApiResponse : NSObject<TSFallable>
@property (strong, readonly) NSArray<TSReward*>* rewards;
@property (strong, readonly) TSResponse* response;
@property (strong, readonly) NSError* error;
+ (instancetype)rewardApiResponseWithResponse:(TSResponse*)response strategy:(id<TSRewardStrategy>)strategy;
@end

#endif /* TSRewardApiResponse_h */
