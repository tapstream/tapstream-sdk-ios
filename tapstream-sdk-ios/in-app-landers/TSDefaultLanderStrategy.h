//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSDefaultLanderStrategy_h
#define TSDefaultLanderStrategy_h
#import "TSLanderStrategy.h"
#import "TSPersistentStorage.h"


@interface TSDefaultLanderStrategy: NSObject<TSLanderStrategy>
+ (instancetype)landerStrategyWithStorage:(id<TSPersistentStorage>)storage;
@end

#endif /* TSDefaultLanderStrategy_h */
