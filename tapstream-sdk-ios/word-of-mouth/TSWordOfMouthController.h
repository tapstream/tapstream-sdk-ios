//  Copyright © 2023 Tapstream. All rights reserved.


#import <UIKit/UIKit.h>
#import "TSOffer.h"
#import "TSReward.h"
#import "TSWordOfMouthDelegate.h"
#import "TSConfig.h"
#import "TSPlatform.h"
#import "TSRewardStrategy.h"
#import "TSOfferStrategy.h"
#import "TSHttpClient.h"
#import "TSRewardApiResponse.h"
#import "TSOfferApiResponse.h"

@interface TSWordOfMouthController : NSObject<TSWordOfMouthDelegate>

@property(assign) id<TSWordOfMouthDelegate> delegate;

- (instancetype)initWithConfig:(TSConfig*)config
					  platform:(id<TSPlatform>)platform
				 offerStrategy:(id<TSOfferStrategy>)offerStrategy
				rewardStrategy:(id<TSRewardStrategy>)rewardStrategy
					httpClient:(id<TSHttpClient>)httpClient;

/**
 @brief Checks if there is an offer than can be shown from the code location indicated by insertionPoint.
 @param insertionPoint A string identifying a certain location within the flow of your application.
 @param completion Block that receives a TSOffer if a valid one exists. This callback is run on the main thread.
 */
- (void)getOfferForInsertionPoint:(NSString*)insertionPoint completion:(void(^)(TSOfferApiResponse*))completion;

/**
 @brief Displays the specified offer to your user.
 @param offer The offer to show
 @param parentViewController The view controller that will be used to show the offer views.
 */
- (void)showOffer:(TSOffer *)offer parentViewController:(UIViewController *)parentViewController;

/**
 @brief Request an array of awards that should be delivered to this user.
 For each reward in the returned array, deliver the reward, and then call consumeReward, passing
 the reward in question as an argument.
 @param completion Block that receives a list of claimable TSRewards instances.  This callback is run on the main thread.
 */
- (void)getRewardList:(void(^)(TSRewardApiResponse*))completion;

/**
 @brief Consumes a reward.  Call this once you have delivered the reward to your user.  After a reward
 is consumed, it will not be returned again in the getRewardList array.
 @param reward The reward to consume.
 */
- (void)consumeReward:(TSReward *)reward;

@end
