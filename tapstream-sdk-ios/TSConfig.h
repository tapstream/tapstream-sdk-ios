//  Copyright © 2023 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>

@interface TSConfig : NSObject {
@private

	NSString* accountName;
	NSString* sdkSecret;

	// Optional hardware identifiers that can be provided by the caller
	BOOL autoCollectIdfa;
	NSString *idfa;

	// Set these if you want to override the names of the automatic events sent by the sdk
	NSString *installEventName;
	NSString *openEventName;

	// Unset these if you want to disable the sending of the automatic events
	BOOL fireAutomaticInstallEvent;
	BOOL fireAutomaticOpenEvent;
	BOOL fireAutomaticIAPEvents;
	
	// These parameters will be automatically attached to all events fired by the sdk
	NSMutableDictionary *globalEventParams;
	
	/*
    Receipt validation: Set these if you want to make Tapstream's server-side receipt validation stricter.
    You should provide hard-coded string literals here, do not dynamically retrieve
    the values from your plist file and set them.
    */
	
	// hardcodedBundleId should match the CFBundleIdentifier value in your Info.plist
	NSString *hardcodedBundleId;

	// hardcodedBundleShortVersionString should match the CFBundleShortVersionString value in your Info.plist
	NSString *hardcodedBundleShortVersionString;
}
@property(nonatomic, strong) NSString *accountName;
@property(nonatomic, strong) NSString *sdkSecret;
	
@property(nonatomic, assign) BOOL autoCollectIdfa;
@property(nonatomic, strong) NSString *idfa;

@property(nonatomic, strong) NSString *installEventName;
@property(nonatomic, strong) NSString *openEventName;

@property(nonatomic, assign) BOOL fireAutomaticInstallEvent;
@property(nonatomic, assign) BOOL fireAutomaticOpenEvent;
@property(nonatomic, assign) BOOL fireAutomaticIAPEvents;

@property(nonatomic, strong) NSMutableDictionary *globalEventParams;

@property(nonatomic, strong) NSString *hardcodedBundleId;
@property(nonatomic, strong) NSString *hardcodedBundleShortVersionString;

+ (instancetype)configWithAccountName:(NSString*)accountName sdkSecret:(NSString*)sdkSecret;

@end

