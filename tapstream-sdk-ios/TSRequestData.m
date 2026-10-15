//  Copyright © 2023 Tapstream. All rights reserved.

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
	@synchronized(items){
		return [items count];
	}
}

- (void) appendItem:(NSString*)value forKey:(NSString*)key
{
	if(![TSURLEncoder checkValueLength:value]){
		return;
	}

	if(value != nil && key != nil) {
		@synchronized(items){
			if(items == nil)
			{
				items = [NSMutableDictionary dictionary];
			}
			[items setObject:value forKey:key];
		}
	}

}

- (void)appendItemWithPrefix:(NSString *)prefix key:(NSString *)key value:(NSString *)value
{
	if(![TSURLEncoder checkKeyLength:key]){
		return;
	}

	NSString* k = [prefix stringByAppendingString:key];
	[self appendItem:value forKey:k];
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
	// Snapshot under the other object's lock, then append under our own. Never
	// hold both locks at once, or two objects copying into each other deadlock.
	NSDictionary* otherItems;
	@synchronized([other items]){
		otherItems = [[other items] copy];
	}
	for(NSString* key in otherItems)
	{
		[self appendItemWithPrefix:@"" key:key value:[otherItems objectForKey:key]];
	}
}

- (NSString*) URLsafeString
{

	NSMutableString* outStr = [NSMutableString string];
	bool first = true;

	// Hold the lock for the whole walk: reading values while another thread
	// appends to the dictionary is not safe.
	@synchronized(items){
		for(NSString* key in items)
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
	}
	return outStr;
}
@end
