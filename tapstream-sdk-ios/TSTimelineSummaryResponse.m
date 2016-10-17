//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSTimelineSummaryResponse.h"

@interface TSTimelineSummaryResponse()
@property(readwrite, strong)NSDictionary<NSString*, NSString*>* hitParams;
@property(readwrite, strong)NSDictionary<NSString*, NSString*>* eventParams;
@property(readwrite, strong)NSString* latestDeeplink;
@property(readwrite, strong)NSArray<NSString*>* deeplinks;
@property(readwrite, strong)NSArray<NSString*>* campaigns;
@property(readwrite, strong)NSError* error;
+ (instancetype)timelineSummaryResponseWithResponse:(TSResponse*)response;
@end


@implementation TSTimelineSummaryResponse
@synthesize error, latestDeeplink, deeplinks, campaigns, hitParams, eventParams;

+ (instancetype)timelineSummaryResponseWithResponse:(TSResponse*)response
{


	TSMaybeError<NSDictionary*>* result = [TSResponse parseJSONResponse:response];
	if([result failed])
	{
		return [[self alloc] initWithError:[result error]];
	}

	NSString* latestDeeplink = nil;
	NSArray<NSString*>* campaigns;
	NSArray<NSString*>* deeplinks;
	NSDictionary<NSString*, NSString*>* hitParams;
	NSDictionary<NSString*, NSString*>* eventParams;

	NSDictionary* jsonDict = [result get];

	hitParams = [jsonDict objectForKey:@"hit_params"];
	eventParams = [jsonDict objectForKey:@"event_params"];
	deeplinks = [jsonDict objectForKey:@"deeplinks"];
	campaigns = [jsonDict objectForKey:@"campaigns"];
	latestDeeplink = [jsonDict objectForKey:@"latest_deeplink"];
	
	return [[self alloc] initWithLatestDeeplink:latestDeeplink
									  deeplinks:deeplinks
									  campaigns:campaigns
									  hitParams:hitParams
									eventParams:eventParams];
}

- (instancetype)initWithLatestDeeplink:(NSString*)_latestDeeplink
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
