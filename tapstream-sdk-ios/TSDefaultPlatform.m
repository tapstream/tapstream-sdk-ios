//  Copyright © 2023 Tapstream. All rights reserved.

#import "TSDefaultPlatform.h"

#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <UIKit/UIKit.h>

#define platformName @"ios"

// Preferences keys

#define kTSUUIDKey @"__tapstream_uuid"
#define kTSHasRunKey @"__tapstream_has_run"


@interface TSDefaultPlatform()
@property(readwrite, strong)id<TSPersistentStorage> storage;
@end

@implementation TSDefaultPlatform

+ (instancetype)platformWithStorage:(id<TSPersistentStorage>)storage
{
	return [[self alloc] initWithStorage:storage];
}

- (instancetype)initWithStorage:(id<TSPersistentStorage>)storage
{
	if((self = [self init]) != nil)
	{
		self.storage = storage;
	}
	return self;
}

- (void)setPersistentFlagVal:(NSString*)key
{
	[self.storage setObject:[NSNumber numberWithBool:true] forKey:key];
}

- (BOOL)getPersistentFlagVal:(NSString*)key
{
	if([self.storage objectForKey:key] != nil)
	{
		return true;
	}
	return false;
}

- (BOOL) isFirstRun
{

	return ![self getPersistentFlagVal:kTSHasRunKey];
}

- (void) registerFirstRun
{
	[self setPersistentFlagVal:kTSHasRunKey];
}

- (NSString *)getSessionId
{
	NSString *uuid = [self.storage objectForKey:kTSUUIDKey];
	if(uuid == nil)
	{
		uuid =  [[NSUUID UUID] UUIDString];
		[self.storage setObject:uuid forKey:kTSUUIDKey];
	}
	return uuid;
}

- (NSString *)getIdfa
{
	Class asIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
	if(asIdentifierManagerClass){
		SEL getterSel = NSSelectorFromString(@"sharedManager");
		IMP getterImp = [asIdentifierManagerClass methodForSelector:getterSel];

		if(getterImp){
			id asIdentifierManager = ((id (*)(id, SEL))getterImp)(asIdentifierManagerClass, getterSel);

			if(asIdentifierManager){
				SEL idfaSel = NSSelectorFromString(@"advertisingIdentifier");
				IMP idfaImp = [asIdentifierManager methodForSelector:idfaSel];

				id idfa = ((id (*)(id, SEL))idfaImp)(asIdentifierManager, idfaSel);
				if(idfa){
					return [((NSUUID*) idfa) UUIDString];
				}
			}
		}
		[TSLogging logAtLevel:kTSLoggingWarn format:@"An problem occurred retrieving the IDFA."];
	}else{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream could not retrieve an IDFA. Is the AdSupport Framework enabled?"];
	}
	return nil;
}

- (NSString *)getManufacturer
{
	return @"Apple";
}

- (NSString *)getModel
{
	NSString *machine = [self systemInfoByName:@"hw.machine" default:@""];
	return machine;
}

- (NSString *)getOs
{
	return [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
}

- (NSString *)getAppName
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (NSString*)getPlatformName
{
	return platformName;
}

- (NSString *)getAppVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)getPackageName
{
	return [[NSBundle mainBundle] bundleIdentifier];
}

- (NSString *)systemInfoByName:(NSString *)name default:(NSString *)def
{
	size_t size;
	int result;
	result = sysctlbyname( [name UTF8String], NULL, &size, NULL, 0);
	if(result != 0){
		// Handle an error value
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream Warning: Failed to retrieve size of system value %@ (Error code: %d)", name, errno];
		return def;
	}

	char *pBuffer = malloc(size);
	if(pBuffer == NULL)
	{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream warning: failed to retrieve system value %@ (malloc failed)", name];
		return def;
	}

	NSString* value;

	result = sysctlbyname( [name UTF8String], pBuffer, &size, NULL, 0);

	if(result == 0){
		value = [NSString stringWithUTF8String:pBuffer];
	}else{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream Warning: Failed to retrieve system value %@ (Error code: %d)", name, errno];
		value = def;
	}

	free( pBuffer );

	return value;
}

- (NSString *)getComputerGUID
{
    return [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

- (NSString *)getBundleIdentifier
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

- (NSString *)getBundleShortVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}



@end

