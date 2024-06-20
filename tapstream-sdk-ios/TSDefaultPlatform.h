//  Copyright © 2023 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>
#import "TSPlatform.h"
#import "TSResponse.h"
#import "TSLogging.h"
#import "TSPersistentStorage.h"

@interface TSDefaultPlatform : NSObject<TSPlatform> {}

+ (instancetype)platformWithStorage:(id<TSPersistentStorage>)storage;
- (BOOL) isFirstRun;
- (void) registerFirstRun;
- (NSString *)getSessionId;
- (NSString *)getIdfa;
- (NSString *)getManufacturer;
- (NSString *)getModel;
- (NSString *)getOs;
- (NSString *)getAppName;
- (NSString *)getAppVersion;
- (NSString *)getPackageName;
- (NSString *)getComputerGUID;
- (NSString *)getBundleIdentifier;
- (NSString *)getBundleShortVersion;

@end
