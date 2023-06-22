//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSDefaultRewardStrategy_h
#define TSDefaultRewardStrategy_h

#import "TSRewardStrategy.h"
#import "TSPersistentStorage.h"

@interface TSDefaultRewardStrategy : NSObject<TSRewardStrategy>
+ (instancetype)rewardStrategyWithStorage:(id<TSPersistentStorage>)storage;
@end

#endif /* TSDefaultRewardStrategy_h */
