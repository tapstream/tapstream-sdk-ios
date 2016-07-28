//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSRewardStrategy_h
#define TSRewardStrategy_h

#import "TSReward.h"

@protocol TSRewardStrategy
- (bool)eligible:(TSReward*)reward;
- (void)registerClaimedReward:(TSReward*)reward;
@end

#endif /* TSRewardStrategy_h */
