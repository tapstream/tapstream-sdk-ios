//  Copyright © 2023 Tapstream. All rights reserved.

#import "TSConfig.h"
#import "TSURLEncoder.h"

@implementation TSConfig

@synthesize accountName = accountName;
@synthesize sdkSecret = sdkSecret;

@synthesize externalIdentity = externalIdentity;
@synthesize autoCollectIdfa = autoCollectIdfa;
@synthesize idfa = idfa;

@synthesize installEventName = installEventName;
@synthesize openEventName = openEventName;

@synthesize fireAutomaticInstallEvent = fireAutomaticInstallEvent;
@synthesize fireAutomaticOpenEvent = fireAutomaticOpenEvent;
@synthesize fireAutomaticIAPEvents = fireAutomaticIAPEvents;

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
		autoCollectIdfa = NO;
		fireAutomaticInstallEvent = YES;
		fireAutomaticOpenEvent = YES;
		fireAutomaticIAPEvents = YES;
		self.globalEventParams = [NSMutableDictionary dictionaryWithCapacity:16];
	}
	return self;
}

@end
