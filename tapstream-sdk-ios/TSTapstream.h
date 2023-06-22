//  Copyright © 2023 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>

#import "TSDefs.h"
#import "TSApi.h"
#import "TSConfig.h"
#import "TSCoreListener.h"

@interface TSTapstream : NSObject<TSApi>
+ (instancetype)instance;

+ (void)createWithConfig:(TSConfig *)config;
+ (void)createWithConfig:(TSConfig *)config listener:(id<TSCoreListener>)listener;
@end
