//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSDefaultPersistentStorage_h
#define TSDefaultPersistentStorage_h

#import "TSPersistentStorage.h"

@interface TSDefaultPersistentStorage : NSObject<TSPersistentStorage>
@property(readonly, strong)NSString* domain;
@property(readonly, strong)NSMutableDictionary* defaults;

+(instancetype)persistentStorageWithDomain:(NSString*)domain;

@end


#endif /* TSDefaultPersistentStorage_h */
