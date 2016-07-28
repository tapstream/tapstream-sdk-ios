//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSURLEncoder.h"
#import "TSLogging.h"

#import <sys/sysctl.h>


__strong static NSMutableCharacterSet* queryAllowedChars = nil;
__strong static NSMutableCharacterSet* pathAllowedChars = nil;

@implementation TSURLEncoder

+ (NSString *)encodeStringForQuery:(NSString *)s
{
	@synchronized(self)
	{
		if(queryAllowedChars == nil)
		{
			queryAllowedChars = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
			[queryAllowedChars removeCharactersInString:@"&"];
		}
		return [s stringByAddingPercentEncodingWithAllowedCharacters:queryAllowedChars];
	}
}

+ (NSString *)encodeStringForPath:(NSString *)s
{
	@synchronized(self)
	{
		if(pathAllowedChars == nil)
		{
			pathAllowedChars = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
			[pathAllowedChars removeCharactersInString:@"/"];
		}
		return [s stringByAddingPercentEncodingWithAllowedCharacters:pathAllowedChars];
	}
}

+ (NSString *)cleanForQuery:(NSString *)s
{
	return [self encodeStringForQuery:[[s lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

+ (NSString *)cleanForPath:(NSString *)s
{
	return [self encodeStringForPath:[[s lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

+ (BOOL)checkKeyLength:(NSString *)key
{
	if(key.length > 255)
	{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream Warning: Event key exceeds 255 characters, this field will not be included in the post (key=%@)", key];
		return false;
	}
	return true;
}

+ (BOOL)checkValueLength:(NSString *)value
{
	if(value.length > 255)
	{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream Warning: Event value exceeds 255 characters, this field will not be included in the post (value=%@)", value];
		return false;
	}
	return true;
}



@end
