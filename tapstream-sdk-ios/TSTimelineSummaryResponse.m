//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSTimelineSummaryResponse.h"

@interface TSTimelineSummaryResponse()
@property(readwrite, strong)NSDictionary<NSString*, NSString*>* hitParams;
@property(readwrite, strong)NSDictionary<NSString*, NSString*>* eventParams;
@property(readwrite, strong)NSString* latestDeeplink;
@property(readwrite) NSUInteger latestDeeplinkTimestamp;
@property(readwrite, strong)NSArray<NSString*>* deeplinks;
@property(readwrite, strong)NSArray<NSString*>* campaigns;
@property(readwrite, strong)NSError* error;
+ (instancetype)timelineSummaryResponseWithResponse:(TSResponse*)response;
@end


@implementation TSTimelineSummaryResponse
@synthesize error, latestDeeplink, latestDeeplinkTimestamp, deeplinks, campaigns, hitParams, eventParams;

+ (instancetype)timelineSummaryResponseWithResponse:(TSResponse*)response
{


	TSMaybeError<NSDictionary*>* result = [TSResponse parseJSONResponse:response];
	if([result failed])
	{
		return [[self alloc] initWithError:[result error]];
	}

	NSString* latestDeeplink = nil;
	NSUInteger latestDeeplinkTimestamp = 0;
	NSArray<NSString*>* campaigns;
	NSArray<NSString*>* deeplinks;
	NSDictionary<NSString*, NSString*>* hitParams;
	NSDictionary<NSString*, NSString*>* eventParams;

	NSDictionary* jsonDict = [result get];

	id maybeHitParams = [jsonDict objectForKey:@"hit_params"];
	hitParams = maybeHitParams == [NSNull null] ? nil : (NSDictionary<NSString*, NSString*>*) maybeHitParams;

	id maybeEventParams = [jsonDict objectForKey:@"event_params"];
	eventParams = maybeEventParams == [NSNull null] ? nil : (NSDictionary<NSString*, NSString*>*) maybeEventParams;

	id maybeDeeplinks = [jsonDict objectForKey:@"deeplinks"];
	deeplinks = maybeDeeplinks == [NSNull null] ? nil : (NSArray<NSString*>*) maybeDeeplinks;

	id maybeCampaigns = [jsonDict objectForKey:@"campaigns"];
	campaigns = maybeCampaigns == [NSNull null] ? nil : (NSArray<NSString*>*) maybeCampaigns;

	id maybeLatestDeeplink = [jsonDict objectForKey:@"latest_deeplink"];
	latestDeeplink = (maybeLatestDeeplink == [NSNull null]) ? nil : (NSString*) maybeLatestDeeplink;

	latestDeeplinkTimestamp = [(NSNumber*)[jsonDict objectForKey:@"latest_deeplink_timestamp"] longValue];
	
	return [[self alloc] initWithLatestDeeplink:latestDeeplink
						latestDeeplinkTimestamp:latestDeeplinkTimestamp
									  deeplinks:deeplinks
									  campaigns:campaigns
									  hitParams:hitParams
									eventParams:eventParams];
}

- (instancetype)initWithLatestDeeplink:(NSString*)_latestDeeplink
			   latestDeeplinkTimestamp:(NSUInteger)_latestDeeplinkTimestamp
							 deeplinks:(NSArray<NSString*>*)_deeplinks
							 campaigns:(NSArray<NSString*>*)_campaigns
							 hitParams:(NSDictionary<NSString*, NSString*>*)_hitParams
						   eventParams:(NSDictionary<NSString*, NSString*>*)_eventParams
{

	if((self = [super init]) != nil)
	{
		hitParams = _hitParams;
		eventParams = _eventParams;
		deeplinks = _deeplinks;
		campaigns = _campaigns;
		latestDeeplink = _latestDeeplink;
		latestDeeplinkTimestamp = _latestDeeplinkTimestamp;
		error = nil;

	}
	return self;
}

- (instancetype)initWithError:(NSError*)err
{
	if((self = [super init]) != nil)
	{
		hitParams = nil;
		eventParams = nil;
		deeplinks = nil;
		campaigns = nil;
		latestDeeplink = nil;
		error = err;

	}
	return self;
}

- (bool)failed { return [self error] != nil; }
@end
