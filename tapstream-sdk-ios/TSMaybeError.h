//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSMaybeError_h
#define TSMaybeError_h

#import "TSFallable.h"
#import "TSError.h"

@interface TSMaybeError<__covariant T> : NSObject<TSFallable>
+ (instancetype)withObject:(T)obj;
+ (instancetype)withError:(NSError*)err;
- (bool)failed;
- (T)get;
- (NSError*)error;
@end

#endif /* TSMaybeError_h */
