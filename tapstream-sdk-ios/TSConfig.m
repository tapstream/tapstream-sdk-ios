//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSConfig.h"
#import "TSURLEncoder.h"

@implementation TSConfig


@synthesize accountName = accountName;
@synthesize sdkSecret = sdkSecret;

@synthesize hardware = hardware;
@synthesize odin1 = odin1;
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@synthesize openUdid = openUdid;
@synthesize udid = udid;
@synthesize autoCollectIdfa = autoCollectIdfa;
@synthesize idfa = idfa;
@synthesize secureUdid = secureUdid;
#else
@synthesize serialNumber = serialNumber;
#endif

@synthesize collectWifiMac = collectWifiMac;

@synthesize installEventName = installEventName;
@synthesize openEventName = openEventName;

@synthesize fireAutomaticInstallEvent = fireAutomaticInstallEvent;
@synthesize fireAutomaticOpenEvent = fireAutomaticOpenEvent;
@synthesize fireAutomaticIAPEvents = fireAutomaticIAPEvents;
@synthesize attemptCookieMatch = attemptCookieMatch;

@synthesize collectTasteData = collectTasteData;

@synthesize globalEventParams = globalEventParams;

@synthesize hardcodedBundleId = hardcodedBundleId;
@synthesize hardcodedBundleShortVersionString = hardcodedBundleShortVersionString;

+ (id)configWithAccountName:(NSString*)accountName sdkSecret:(NSString*)sdkSecret
{
	TSConfig* config = [[self alloc] init];
	config.accountName = [TSURLEncoder cleanForPath:accountName];
	config.sdkSecret = sdkSecret;
	return config;
}

- (id)init
{
	if((self = [super init]) != nil)
	{
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		autoCollectIdfa = YES;
#endif
		collectWifiMac = YES;
		fireAutomaticInstallEvent = YES;
		fireAutomaticOpenEvent = YES;
		fireAutomaticIAPEvents = YES;
		attemptCookieMatch = NO;
        collectTasteData = YES;
		self.globalEventParams = [NSMutableDictionary dictionaryWithCapacity:16];
	}
	return self;
}
@end
