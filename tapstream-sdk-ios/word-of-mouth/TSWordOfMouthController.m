//  Copyright © 2023 Tapstream. All rights reserved.

#import "TSWordOfMouthController.h"

#import "TSOfferViewController.h"
#import "TSTapstream.h"
#import "TSLogging.h"
#import "TSOfferStrategy.h"
#import "TSRewardStrategy.h"
#import "TSHttpClient.h"
#import "TSURLBuilder.h"

#define kTSInstallDateKey @"__tapstream_install_date"
#define kTSLastOfferImpressionTimesKey @"__tapstream_last_offer_impression_times"


@interface TSWordOfMouthController()

@property(strong, nonatomic) TSConfig* config;
@property(nonatomic, strong) id<TSOfferStrategy> offerStrategy;
@property(nonatomic, strong) id<TSRewardStrategy> rewardStrategy;
@property(strong, nonatomic) id<TSHttpClient> httpClient;
@property(strong, nonatomic) id<TSPlatform> platform;

@end



@implementation TSWordOfMouthController


- (instancetype)initWithConfig:(TSConfig*)config
					  platform:(id<TSPlatform>)platform
				 offerStrategy:(id<TSOfferStrategy>)offerStrategy
				rewardStrategy:(id<TSRewardStrategy>)rewardStrategy
					httpClient:(id<TSHttpClient>)httpClient
{
    if(self = [super init]) {
		self.config = config;
		self.platform = platform;
		self.offerStrategy = offerStrategy;
		self.rewardStrategy = rewardStrategy;
		self.httpClient = httpClient;
    }
    return self;
}

- (void)getOfferForInsertionPoint:(NSString *)insertionPoint completion:(void (^)(TSOfferApiResponse *))callback
{
	[TSLogging logAtLevel:kTSLoggingInfo
				   format:@"Requesting offer for insertion point '%@'", insertionPoint];

	if(callback == nil)
	{
		return;
	}

	// First, check for cached offer
	NSString* sessionId = [self.platform getSessionId];
	TSOffer *offer = [self.offerStrategy cachedOffer:insertionPoint sessionId:sessionId];

	if(offer != nil) {
		if([self.offerStrategy eligible:offer])
		{
			callback([TSOfferApiResponse offerApiResponseWithOffer:offer]);
		}
		else
		{
			TSResponse* ineligibleResponse = [TSResponse responseWithStatus:-1 message:@"Cached offer is not eligible" data:nil];
			callback([TSOfferApiResponse offerApiResponseWithResponse:ineligibleResponse sessionId:sessionId]);
		}
		return;
	}

	NSURL* url = [TSURLBuilder makeOfferURL:self.config
									 bundle:[self.platform getBundleIdentifier]
							 insertionPoint:insertionPoint];

	[self.httpClient request:url completion:^(TSResponse* response){

        [TSLogging logAtLevel:kTSLoggingInfo
                       format:@"Offers request complete (status %d)", [response status]];

		TSOfferApiResponse* offerResponse = [TSOfferApiResponse
											 offerApiResponseWithResponse:response
											 sessionId:[self.platform getSessionId]];
		if([offerResponse failed])
		{
			[TSLogging logAtLevel:kTSLoggingWarn format:[TSError messageForError:[offerResponse error]]];
		}
		else
		{
			[self.offerStrategy registerOfferRetrieved:[offerResponse offer] forInsertionPoint:insertionPoint];

			if(![self.offerStrategy eligible:[offerResponse offer]])
			{
				// Replace offerResponse with invalidated one
				TSResponse* ineligibleResponse = [TSResponse responseWithStatus:-1 message:@"Cached offer is not eligible" data:nil];
				offerResponse = [TSOfferApiResponse offerApiResponseWithResponse:ineligibleResponse sessionId:sessionId];
				[TSLogging logAtLevel:kTSLoggingInfo format:@"Offer id=%d ineligible", [offer ident]];
			}
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			callback(offerResponse);
		});

	}];

}


- (void)getRewardList:(void(^)(TSRewardApiResponse*))completion
{

	NSURL* url = [TSURLBuilder makeRewardListURL:self.config sessionId:[self.platform getSessionId]];
	[self.httpClient request:url completion:^(TSResponse* response){
		TSRewardApiResponse* rewardResponse = [TSRewardApiResponse rewardApiResponseWithResponse:response strategy:self.rewardStrategy];
		if(![rewardResponse failed])
		{
			[TSLogging logAtLevel:kTSLoggingInfo
						   format:@"Checking %d returned potential rewards for quantity",
			 [[rewardResponse rewards] count]];
		}

		if(completion) {
			dispatch_sync(dispatch_get_main_queue(), ^() {
				completion(rewardResponse);
			});
		}
	}];
}

- (void)consumeReward:(TSReward*)reward
{
	[self.rewardStrategy registerClaimedReward:reward];
}

- (void)showOffer:(TSOffer *)offer parentViewController:(UIViewController *)parentViewController;
{
    if(!NSClassFromString(@"WKWebView")){
        [TSLogging logAtLevel:kTSLoggingWarn
                       format:@"WKWebView class not found. Not showing WoM popup. Is the WebKit Framework enabled?"];
        return;
    }
    
    if (!offer) {
        return;
    }
    
    TSOfferViewController* offerViewController = [TSOfferViewController controllerWithOffer: offer delegate:self];
    [parentViewController presentViewController:offerViewController animated:YES completion:nil];
    [self showedOffer:offer.ident];
    [self.offerStrategy registerOfferShown:(TSOffer*)offer];
}


#pragma mark - TSWordOfMouthDelegate
- (void)showedOffer:(NSUInteger)offerId
{
    [self.delegate showedOffer:offerId];
}

- (void)dismissedOffer:(BOOL)accepted
{
    [self.delegate dismissedOffer:accepted];
}

- (void)showedSharing:(NSUInteger)offerId
{
    [self.delegate showedSharing:offerId];
}

- (void)dismissedSharing
{
    [self.delegate dismissedSharing];
}

- (void)completedShare:(NSUInteger)offerId socialMedium:(NSString *)medium
{
    [self.delegate completedShare:offerId socialMedium:medium];
}


@end
