//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSConfig.h"
#import "TSHttpClient.h"
#import "TSURLBuilder.h"
#import "TSLogging.h"
#import "TSIOSUniversalLinkDelegate.h"

@interface TSIOSUniversalLinkDelegate()
@property(strong, readwrite) TSConfig* config;
@property(strong, readwrite) id<TSHttpClient> httpClient;
@end


@implementation TSIOSUniversalLinkDelegate

+ (instancetype) universalLinkDelegateWithConfig:(TSConfig*)config
									  httpClient:(id<TSHttpClient>)httpClient
{
	return [[self alloc] initWithConfig:config httpClient:httpClient];
}

- (instancetype) initWithConfig:(TSConfig*)config
					 httpClient:(id<TSHttpClient>)httpClient
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		self.httpClient = httpClient;
	}
	return self;
}

- (void)handleUniversalLink:(NSUserActivity*)userActivity completion:(void(^)(TSUniversalLinkApiResponse*))completion
{
	if(![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]
	   || [userActivity webpageURL] == nil)
	{
		completion([TSUniversalLinkApiResponse universalLinkApiResponseWithStatus:kTSULUnknown]);
		return;
	}

	NSURL* url = [userActivity webpageURL];

	// Respond according to deeplink query
	NSURL* deeplinkQueryUrl = [TSURLBuilder makeDeeplinkQueryURL:self.config forURL:[url absoluteString]];

	[self.httpClient request:deeplinkQueryUrl
				  completion:^(TSResponse* response){

					  TSUniversalLinkApiResponse* ul = [TSUniversalLinkApiResponse universalLinkApiResponseWithResponse:response];

					  // Fire simulated click if Tapstream recognizes the link
					  if (ul.status != kTSULUnknown){
						  NSURL* simulatedClickUrl = [TSURLBuilder makeSimulatedClickURL:url];


						  [self.httpClient asyncSafariRequest:simulatedClickUrl
												   completion:^(TSResponse* response){

													   if (response.status >= 200 && response.status < 300){
														   [TSLogging logAtLevel:kTSLoggingInfo format:@"Universal link simulated click succeeded for url %@", url];
													   }else{
														   [TSLogging logAtLevel:kTSLoggingWarn format:@"Universal link simulated click failed for url %@", url];
													   }
												   }];
					  }

					  if(completion != nil)
					  {
						  completion(ul);
					  }
				  }];
	
}
@end