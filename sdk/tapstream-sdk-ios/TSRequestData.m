//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSRequestData.h"
#import "TSURLEncoder.h"
#import "TSLogging.h"

@interface TSRequestData()
@property(readwrite, strong)NSMutableDictionary* items;
@end

@implementation TSRequestData
@synthesize items;

+ (instancetype)requestData
{
	return [[self alloc] initWithItems:[NSMutableDictionary dictionary]];
}

- (instancetype)initWithItems:(NSMutableDictionary*)initItems
{
	if((self = [self init]) != nil)
	{
		items = initItems;
	}
	return self;
}

- (NSUInteger)count
{
	return [items count];
}

- (void)appendItemWithPrefix:(NSString *)prefix key:(NSString *)key value:(NSString *)value
{
	if(items == nil)
	{
		items = [NSMutableDictionary dictionary];
	}

	if(![TSURLEncoder checkKeyLength:key]){
		return;
	}

	NSString* k = [prefix stringByAppendingString:key];

	if(![TSURLEncoder checkValueLength:value]){
		return;
	}
	if(value != nil && key != nil)
	{
		[items setObject:value forKey:k];
	}
	else
	{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Nil key or value passed to appendItemWithPrefix: %@=%@", k, value];
	}

}

- (void)appendItemsWithPrefix:(NSString*)prefix keysAndValues:(NSString*)key, ... NS_REQUIRES_NIL_TERMINATION
{
	va_list args;
	va_start(args, key);
	NSString* value;
	while (key != nil)
	{
		value = va_arg(args, NSString*);
		if(value != nil)
		{
			[self appendItemWithPrefix:prefix key:key value:value];
		}
		key = va_arg(args, NSString*);
	}
	va_end(args);
}
- (void) appendItemsFromRequestData:(TSRequestData*)other
{
	for(NSString* key in [[other items] keyEnumerator])
	{
		[items setObject:[[other items] objectForKey:key] forKey:key];
	}
}

- (NSString*) URLsafeString
{

	NSMutableString* outStr = [NSMutableString string];
	bool first = true;
	for(NSString* key in [items keyEnumerator])
	{
		if(!first)
		{
			[outStr appendString:@"&"];
		}
		else
		{
			first = false;
		}

		[outStr appendFormat:@"%@=%@",
		 [TSURLEncoder encodeStringForQuery:key],
		 [TSURLEncoder encodeStringForQuery:[items objectForKey:key]]];
	}
	return outStr;
}
@end
