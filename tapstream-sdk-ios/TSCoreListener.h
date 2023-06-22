//  Copyright © 2023 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>

@protocol TSCoreListener<NSObject>
- (void)reportOperation:(NSString *)op;
- (void)reportOperation:(NSString *)op arg:(NSString *)arg;
@end
