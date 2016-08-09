//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSTestPersistentStorage_h
#define TSTestPersistentStorage_h

#import "TSPersistentStorage.h"

@interface TSTestPersistentStorage: NSObject<TSPersistentStorage>
@property(readonly, strong)NSMutableDictionary* defaults;
@end

#endif /* TSTestPersistentStorage_h */
