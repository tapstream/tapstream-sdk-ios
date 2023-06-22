//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSDefaultPersistentStorage.h"

@interface TSDefaultPersistentStorage()
@property(readwrite, strong)NSString* domain;
@property(readwrite, strong)NSMutableDictionary* defaults;
@end

@implementation TSDefaultPersistentStorage

+ (instancetype)persistentStorageWithDomain:(NSString*)domain
{
	return [[self alloc] initWithDomain:domain];
}

- (instancetype) initWithDomain:(NSString*)domain
{
	if((self = [self init]) != nil)
	{
		self.domain = domain;
		self.defaults = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] persistentDomainForName:domain]];
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

	[[NSUserDefaults standardUserDefaults] setPersistentDomain:self.defaults forName:self.domain];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
@end
