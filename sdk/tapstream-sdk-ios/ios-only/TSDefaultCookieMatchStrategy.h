//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSDefaultCookieMatchStrategy_h
#define TSDefaultCookieMatchStrategy_h

#import "TSCookieMatchStrategy.h"
#import "TSPersistentStorage.h"

@interface TSDefaultCookieMatchStrategy : NSObject<TSCookieMatchStrategy>
@property(readonly, strong)id<TSPersistentStorage> storage;
@property(readonly, nonatomic) BOOL cookieMatchInProgress;

+ (instancetype) cookieMatchStrategyWithStorage:(id<TSPersistentStorage>)storage;
@end

#endif /* TSDefaultCookieMatchStrategy_h */
