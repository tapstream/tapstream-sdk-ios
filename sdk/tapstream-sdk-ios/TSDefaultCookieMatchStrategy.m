//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSDefaultCookieMatchStrategy.h"
#import "TSPersistentStorage.h"

@interface TSDefaultCookieMatchStrategy()
@property(readwrite, strong)id<TSPersistentStorage> storage;
@property(readwrite, nonatomic) BOOL cookieMatchInProgress;
@end

#define SECONDS_PER_DAY 86400
#define kTSLastCookieMatchTimestampKey @"__tapstream_cookie_match_timestamp"

@implementation TSDefaultCookieMatchStrategy

+ (instancetype) cookieMatchStrategyWithStorage:(id<TSPersistentStorage>)storage
{
	return [[self alloc] initWithStorage:storage];
}

- (instancetype)initWithStorage:(id<TSPersistentStorage>)storage
{
	if((self = [self init]) != nil)
	{
		self.storage = storage;
		self.cookieMatchInProgress = false;
	}
	return self;
}


- (BOOL) shouldFireCookieMatch
{
	if(self.cookieMatchInProgress){
		return false;
	}

	NSTimeInterval lastCookieMatch = [self getCookieMatchFired];
	NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
	return (now - lastCookieMatch) >= SECONDS_PER_DAY;
}

- (void) startCookieMatch
{
	@synchronized (self) {
		self.cookieMatchInProgress = true;
	}
}

- (NSTimeInterval) getCookieMatchFired
{
	NSNumber* timestamp = [self.storage objectForKey:kTSLastCookieMatchTimestampKey];
	if(timestamp != nil)
	{
		return [timestamp doubleValue];
	}
	return -1;
}

- (void) registerCookieMatchFired
{
	NSNumber* t = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	[self.storage setObject:t forKey:kTSLastCookieMatchTimestampKey];
}


@end
