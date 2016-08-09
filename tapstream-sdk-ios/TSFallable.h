//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSFallable_h
#define TSFallable_h

#import "TSError.h"

@protocol TSFallable
- (bool)failed;
- (NSError*)error;
@end

#endif /* TSFallable_h */
