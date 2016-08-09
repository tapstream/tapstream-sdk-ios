//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSDefaultFireEventStrategy_h
#define TSDefaultFireEventStrategy_h

#import "TSFireEventStrategy.h"
#import "TSPersistentStorage.h"
#import "TSCoreListener.h"


@interface TSDefaultFireEventStrategy: NSObject<TSFireEventStrategy>
@property(readwrite) int delay;
@property(nonatomic, strong) NSString *failingEventId;
@property(nonatomic, strong) NSMutableSet *firingEvents;
@property(nonatomic, strong) NSMutableSet *firedEvents;
@property(readwrite, strong) id<TSPersistentStorage> storage;
@property(readwrite, strong) id<TSCoreListener> listener;
+ (instancetype) fireEventStrategyWithStorage:(id<TSPersistentStorage>)storage listener:(id<TSCoreListener>)listener;
@end


#endif /* TSDefaultFireEventStrategy_h */
