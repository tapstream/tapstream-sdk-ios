//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSDefaultLanderStrategy.h"
#import "TSPersistentStorage.h"

#define kTSLandersShownKey @"__tapstream_landers_shown"

@interface TSDefaultLanderStrategy()
@property(readwrite, strong) id<TSPersistentStorage> storage;
@end

@implementation TSDefaultLanderStrategy

+ (instancetype)landerStrategyWithStorage:(id<TSPersistentStorage>)storage
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

- (BOOL)shouldShowLander:(TSLander*)lander
{
	if(![lander isValid])
	{
		return false;
	}

	NSNumber* numberObj = [NSNumber numberWithUnsignedInteger:[lander ident]];
	NSArray* landerArray = [self.storage objectForKey:kTSLandersShownKey];
	NSMutableSet* shownLanders = [NSMutableSet setWithArray:landerArray];
	return ![shownLanders containsObject:numberObj];
}
- (void)registerLanderShown:(TSLander*)lander
{
	NSNumber* numberObj = [NSNumber numberWithUnsignedInteger:[lander ident]];
	NSArray* landerArray = [self.storage objectForKey:kTSLandersShownKey];
	NSMutableSet* shownLanders = [NSMutableSet setWithArray:landerArray];
	[shownLanders addObject:numberObj];
	[self.storage setObject:[shownLanders allObjects] forKey:kTSLandersShownKey];
}
@end
