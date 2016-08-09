//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import "TSConfig.h"
#import "TSEvent.h"
#import "TSResponse.h"
#import "TSUniversalLinkApiResponse.h"


#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "TSLanderDelegate.h"
#import "TSWordOfMouthController.h"
#import "TSRewardApiResponse.h"
#import "TSOfferApiResponse.h"
#endif


#import "TSCoreListener.h"
#import "TSTimelineApiResponse.h"

@protocol TSApi<NSObject>

- (void)fireEvent:(TSEvent *)event;
- (void)fireEvent:(TSEvent *)event completion:(void(^)(TSResponse*))completion;


// Onboarding Links

- (void)lookupTimeline:(void(^)(TSTimelineApiResponse*))completion;


#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
// In-App Landers -- iOS only

- (void)showLanderIfExistsWithDelegate:(id<TSLanderDelegate>)delegate;

// Word of mouth controller
+ (TSWordOfMouthController*)wordOfMouthController;

#endif

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

// UL support
- (void)handleUniversalLink:(NSUserActivity*)userActivity completion:(void(^)(TSUniversalLinkApiResponse*))completion;

#endif
#endif
@end
