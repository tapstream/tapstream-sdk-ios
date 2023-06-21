//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSPersistentStorage_h
#define TSPersistentStorage_h


@protocol TSPersistentStorage
- (id) objectForKey:(NSString*)key;
- (void) setObject:(id)obj forKey:(NSString*)key;
@end;

#endif /* TSPersistentStorage_h */
