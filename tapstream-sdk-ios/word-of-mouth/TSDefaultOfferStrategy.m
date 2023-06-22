//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSDefaultOfferStrategy.h"
#import "TSLogging.h"

#define kTSInstallDateKey @"__tapstream_install_date"
#define kTSLastOfferImpressionTimesKey @"__tapstream_last_offer_impression_times"


@interface TSDefaultOfferStrategy ()
@property(strong, readwrite) id<TSPersistentStorage> storage;
@property(strong, readwrite) NSDate* installDate;
@property(strong, nonatomic) NSMutableDictionary *lastOfferImpressionTimes;
@end

@implementation TSDefaultOfferStrategy
+ (instancetype)offerStrategyWithStorage:(id<TSPersistentStorage>)storage
{
	return [[self alloc] initWithStorage:storage];
}

- (instancetype) initWithStorage:(id<TSPersistentStorage>)storage
{
	if((self = [self init]) != nil)
	{
		self.storage = storage;

		// Load install date from storage
		self.installDate = [storage objectForKey:kTSInstallDateKey];
		if(!self.installDate) {
			self.installDate = [NSDate date];
			[storage setObject:self.installDate forKey:kTSInstallDateKey];
		}

		// Load last offer times from storage
		self.lastOfferImpressionTimes = [[[NSUserDefaults standardUserDefaults] objectForKey:kTSLastOfferImpressionTimesKey] mutableCopy];
		if(!self.lastOfferImpressionTimes) {
			self.lastOfferImpressionTimes = [NSMutableDictionary dictionaryWithCapacity:8];
		}
	}
	return self;
}

- (TSOffer*)cachedOffer:(NSString*)insertionPoint sessionId:(NSString*)uuid
{
	NSString* key = [NSString stringWithFormat:@"cachedoffer:%@", insertionPoint];
	NSDictionary* description = [self.storage objectForKey:key];
	if(description != nil)
	{
		return [TSOffer offerWithDescription:description uuid:uuid];
	}
	return nil;
}

- (void)registerOfferRetrieved:(TSOffer *)offer forInsertionPoint:(NSString*)insertionPoint
{
	NSString* key = [NSString stringWithFormat:@"cachedoffer:%@", insertionPoint];
	[self.storage setObject:[offer description] forKey:key];
}

- (void)registerOfferShown:(TSOffer*)offer
{
	// Update last shown time for this offer
	[self.lastOfferImpressionTimes setObject:[NSDate date] forKey:[[NSNumber numberWithInteger:offer.ident] stringValue]];
	[self.storage setObject:self.lastOfferImpressionTimes forKey:kTSLastOfferImpressionTimesKey];
}

- (bool)eligible:(TSOffer *)offer
{
	if(offer == nil)
	{
		return false;
	}
	NSDate *now = [NSDate date];

	// Cannot show offers to users younger than minimumAge
	NSTimeInterval age = [now timeIntervalSinceDate:self.installDate];
	if(age < offer.minimumAge) {
		[TSLogging logAtLevel:kTSLoggingInfo
					   format:@"Offer '%@' ineligible (minimum age not met)",
		 [offer insertionPoint]];
		return NO;
	}

	// Cannot show offers more frequently than the rateLimit
	NSDate *lastImpression = [self.lastOfferImpressionTimes objectForKey:[[NSNumber numberWithInteger:offer.ident] stringValue]];
	if(lastImpression && [now timeIntervalSinceDate:lastImpression] < offer.rateLimit) {
		[TSLogging logAtLevel:kTSLoggingInfo
					   format:@"Offer '%@' ineligible (rate limited)",
		 [offer insertionPoint]];
		return NO;
	}

	[TSLogging logAtLevel:kTSLoggingInfo
				   format:@"Offer '%@' eligible",
	 [offer insertionPoint]];

	return YES;
}
@end
