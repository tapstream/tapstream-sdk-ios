//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>

#import "TSHttpClient.h"

@protocol TSPlatform<NSObject>

- (BOOL) isFirstRun;
- (void) registerFirstRun;
- (NSString *)getSessionId;
- (NSString *)getIdfa;
- (NSString *)getManufacturer;
- (NSString *)getModel;
- (NSString *)getOs;
- (NSString *)getOsBuild;
- (NSString *)getAppName;
- (NSString *)getPlatformName;
- (NSString *)getAppVersion;
- (NSString *)getPackageName;
- (NSString *)getComputerGUID;
- (NSString *)getBundleIdentifier;
- (NSString *)getBundleShortVersion;

@end
