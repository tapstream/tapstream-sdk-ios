//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSURLBuilder.h"
#import "TSURLEncoder.h"


#define kTSEventUrlTemplate @"https://api.tapstream.com/%@/event/%@/"
#define kTSHitUrlTemplate @"https://api.tapstream.com/%@/hit/%@.gif"
#define kTSDeeplinkQueryUrlTemplate @"https://api.tapstream.com/%@/deeplink_query/"
#define kTSLanderUrlTemplate @"https://reporting.tapstream.com/v1/in_app_landers/display/?secret=%@&event_session=%@"
#define kTSConversionUrlTemplate @"https://reporting.tapstream.com/v1/timelines/lookup/"
#define kTSTimelineSummaryUrlTemplate @"https://reporting.tapstream.com/v1/timelines/summary/"
#define kTSOfferUrlTemplate @"https://app.tapstream.com/api/v1/word-of-mouth/offers/"
#define kTSRewardUrlTemplate @"https://app.tapstream.com/api/v1/word-of-mouth/rewards/"

@implementation TSURLBuilder

+ (NSURL*) urlWithParameters:(NSString*)baseUrl globalEventParams:(NSDictionary*)params data:(TSRequestData*)data, ... NS_REQUIRES_NIL_TERMINATION
{
	if(data == nil)
	{
		data = [TSRequestData requestData];
	}

	if(params != nil)
	{
		for(NSString* key in params)
		{
			if(![TSURLEncoder checkKeyLength:key]){
				continue;
			}

			[data appendItemWithPrefix:@"custom-"
								   key:key
								 value:[params objectForKey:key]];
		}
	}

	va_list args;
	va_start(args, data);
	NSString* key;
	while ((key = va_arg(args, NSString*)) != nil)
	{
		[data appendItemWithPrefix:@"" key:key value:va_arg(args, NSString*)];
	}
	va_end(args);
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", baseUrl, [data URLsafeString]]];
}

+ (NSURL*)makeEventURL:(TSConfig*)config eventName:(NSString*)eventName
{
	return [NSURL URLWithString:[NSString stringWithFormat:kTSEventUrlTemplate,
								 [config accountName],
								 [TSURLEncoder encodeStringForPath:eventName]]];
}
+ (NSURL*)makeConversionURL:(TSConfig*)config sessionId:(NSString*)sessionId
{
	return [self urlWithParameters:kTSConversionUrlTemplate
				 globalEventParams:nil
							  data:nil,
			@"secret", [config sdkSecret],
			@"event_session", sessionId,
			@"blocking", @"true",
			nil];
}
+ (NSURL*)makeTimelineSummaryURL:(TSConfig*)config sessionId:(NSString*)sessionId
{
	return [self urlWithParameters:kTSTimelineSummaryUrlTemplate
				 globalEventParams:nil
							  data:nil,
			@"secret", [config sdkSecret],
			@"event_session", sessionId,
			@"blocking", @"true",
			nil];
}

+ (NSURL*)makeLanderURL:(TSConfig*)config sessionId:(NSString*)sessionId
{
	return [[NSURL alloc] initWithString:[NSString stringWithFormat:kTSLanderUrlTemplate,
										  [TSURLEncoder encodeStringForQuery:config.sdkSecret],
										  sessionId]];
}

+ (NSURL*)makeDeeplinkQueryURL:(TSConfig*)config forURL:(NSString*)url
{
	NSString* deeplinkQueryURL = [NSString stringWithFormat:kTSDeeplinkQueryUrlTemplate, [config accountName]];
	return [self urlWithParameters:deeplinkQueryURL globalEventParams:nil data:nil,
			@"__tsdqu", url,
			@"__tsdqp", @"iOS",
			nil];
}

+ (NSURL*)makeSimulatedClickURLWithBaseURL:(NSURL*)baseURL idfa:(NSString*)idfa sessionId:(NSString*)sessionId
{
	return [self urlWithParameters:[baseURL absoluteString]
				 globalEventParams:nil
							  data:nil,
			@"__tsredirect", @"0",
			@"__tshardware-ios-idfa", idfa,
			@"__tsul", sessionId,
			nil];
}

+ (NSURL*)makeOfferURL:(TSConfig*)config bundle:(NSString*)bundle insertionPoint:(NSString*)insertionPoint
{
	return [self urlWithParameters:kTSOfferUrlTemplate
				 globalEventParams:nil
							  data:nil,
			@"secret", [config sdkSecret],
			@"bundle", bundle,
			@"insertion_point", insertionPoint,
			nil];
}

+ (NSURL*)makeRewardListURL:(TSConfig*)config sessionId:(NSString*)sessionId
{
	return [self urlWithParameters:kTSRewardUrlTemplate
				 globalEventParams:nil
							  data:nil,
			@"secret", [config sdkSecret],
			@"event_session", sessionId,
			nil];
}

@end
