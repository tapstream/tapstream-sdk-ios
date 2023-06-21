//  Copyright © 2023 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>
#import "TSCoreListener.h"

@interface TSDefaultCoreListener : NSObject<TSCoreListener> {}

- (void)reportOperation:(NSString *)op;
- (void)reportOperation:(NSString *)op arg:(NSString *)arg;

@end
