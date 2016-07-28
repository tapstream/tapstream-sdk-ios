//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSDefaultOfferStrategy_h
#define TSDefaultOfferStrategy_h

#import "TSOfferStrategy.h"
#import "TSPersistentStorage.h"

@interface TSDefaultOfferStrategy : NSObject<TSOfferStrategy>
+ (instancetype)offerStrategyWithStorage:(id<TSPersistentStorage>)storage;
@end

#endif /* TSDefaultOfferStrategy_h */
