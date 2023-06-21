//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSTestPersistentStorage.h"

@interface TSTestPersistentStorage()
@property(readwrite, strong)NSMutableDictionary* defaults;
@end


@implementation TSTestPersistentStorage

- (instancetype) init
{
	if((self = [super init]) != nil)
	{
		self.defaults = [NSMutableDictionary dictionary];
	}
	return self;
}

- (NSObject*) objectForKey:(NSString*)key
{
	return [self.defaults objectForKey:key];
}

- (void) setObject:(NSObject*)obj forKey:(NSString*)key
{

	if(obj == nil)
	{
		[self.defaults removeObjectForKey:key];
	}
	else
	{
		[self.defaults setObject:obj forKey:key];
	}
}
@end
