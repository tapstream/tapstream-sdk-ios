//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSDefaultFireEventStrategy.h"
#import "TSResponse.h"
#import "TSLogging.h"
#import "TSEvent.h"


#define kTSFiredEventsKey @"__tapstream_fired_events"


@implementation TSDefaultFireEventStrategy

+ (instancetype) fireEventStrategyWithStorage:(id<TSPersistentStorage>)storage listener:(id<TSCoreListener>)listener
{
	return [[self alloc] initWithStorage:storage listener:listener];
}

- (instancetype)initWithStorage:(id<TSPersistentStorage>)storage listener:(id<TSCoreListener>)listener
{
	if((self = [self init]) != nil)
	{
		self.storage = storage;
		self.listener = listener;
		self.firedEvents = [self loadFiredEvents];
		self.firingEvents = [[NSMutableSet alloc] initWithCapacity:32];
	}
	return self;
}

- (BOOL)shouldFireEvent:(TSEvent*)e
{

	if(e.isOneTimeOnly)
	{
		if([self.firedEvents containsObject:e.name])
		{
			[TSLogging logAtLevel:kTSLoggingInfo format:@"Tapstream ignoring event named \"%@\" because it is a one-time-only event that has already been fired", e.name];
			[self.listener reportOperation:@"event-ignored-already-fired" arg:e.encodedName];
			[self.listener reportOperation:@"job-ended" arg:e.encodedName];
			return false;
		}
		else if([self.firingEvents containsObject:e.name])
		{
			[TSLogging logAtLevel:kTSLoggingInfo format:@"Tapstream ignoring event named \"%@\" because it is a one-time-only event that is already in progress", e.name];
			[self.listener reportOperation:@"event-ignored-already-in-progress" arg:e.encodedName];
			[self.listener reportOperation:@"job-ended" arg:e.encodedName];
			return false;
		}

	}
	return true;
}

- (void)registerFiringEvent:(TSEvent*)e
{
	if(e.isOneTimeOnly)
	{
		[self.firingEvents addObject:e.name];
	}
}


- (void)registerResponse:(TSResponse*)response forEvent:(TSEvent*)e
{
	@synchronized(self)
	{
		if(e.isOneTimeOnly)
		{
			[self.firingEvents removeObject:e.name];
		}

		if([response failed])
		{
			// Only increase delays if we actually intend to retry the event
			if([response retryable])
			{
				// Not every job that fails will increase the retry delay.  It will be the responsibility of
				// the first failed job to increase the delay after every failure.
				if(self.delay == 0)
				{
					// This is the first job to fail, it must be the one to manage delay timing
					self.failingEventId = e.uid;
					[self increaseDelay];
				}
				else if([self.failingEventId isEqualToString:e.uid])
				{
					[self increaseDelay];
				}
			}
		}
		else
		{
			if(e.isOneTimeOnly)
			{
				[self.firedEvents addObject:e.name];

				[self saveFiredEvents];
				[self.listener reportOperation:@"fired-list-saved" arg:e.encodedName];
			}

			// Success of any event resets the delay
			self.delay = 0;
		}
	}

}

// Delay logic

- (int)getDelay
{
	@synchronized(self){
		return self.delay;
	}
}

- (void)increaseDelay
{
	if(self.delay == 0)
	{
		// First failure
		self.delay = 2;
	}
	else
	{
		// 2, 4, 8, 16, 32, 60, 60, 60...
		int newDelay = (int)pow( 2, log2( self.delay ) + 1 );
		self.delay = newDelay > 60 ? 60 : newDelay;
	}
	[self.listener reportOperation:@"increased-delay"];
}

// Load/save fired events set

- (NSMutableSet*)loadFiredEvents
{
	NSArray *fireList = [self.storage objectForKey:kTSFiredEventsKey];
	if(fireList)
	{
		return [NSMutableSet setWithArray:fireList];
	}
	return [NSMutableSet setWithCapacity:32];
}

- (void)saveFiredEvents
{
	[self.storage setObject:[self.firedEvents allObjects] forKey:kTSFiredEventsKey];
}

@end
