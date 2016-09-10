//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>

#import "TSHttpClient.h"

@protocol TSPlatform<NSObject>
//- (void)setPersistentFlagVal:(NSString*)key;
//- (BOOL)getPersistentFlagVal:(NSString*)key;

- (BOOL) isFirstRun;
- (void) registerFirstRun;
- (NSString *)getSessionId;
- (NSString *)getIdfa;
- (NSString *)getResolution;
- (NSString *)getManufacturer;
- (NSString *)getModel;
- (NSString *)getOs;
- (NSString *)getOsBuild;
- (NSString *)getLocale;
- (NSString *)getWifiMac;
- (NSString *)getAppName;
- (NSString *)getPlatformName;
- (NSString *)getAppVersion;
- (NSString *)getPackageName;
- (NSString *)getComputerGUID;
- (NSString *)getBundleIdentifier;
- (NSString *)getBundleShortVersion;


@end
