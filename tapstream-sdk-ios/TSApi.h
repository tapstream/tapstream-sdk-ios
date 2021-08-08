//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import "TSConfig.h"
#import "TSEvent.h"
#import "TSResponse.h"
#import "TSUniversalLinkApiResponse.h"
#import "TSCoreListener.h"
#import "TSTimelineApiResponse.h"
#import "TSTimelineSummaryResponse.h"

@protocol TSApi<NSObject>

- (void)fireEvent:(TSEvent *)event;
- (void)fireEvent:(TSEvent *)event completion:(void(^)(TSResponse*))completion;

- (NSString*)sessionId;

// Onboarding Links

- (void)lookupTimeline:(void(^)(TSTimelineApiResponse*))completion;
- (void)getTimelineSummary:(void(^)(TSTimelineSummaryResponse*))completion;

// In-App Landers -- iOS only
- (void)showLanderIfExistsWithDelegate:(id)delegate;

// Word of mouth controller
+ (id)wordOfMouthController;

// UL support
- (void)handleUniversalLink:(NSUserActivity*)userActivity completion:(void(^)(TSUniversalLinkApiResponse*))completion;

@end
