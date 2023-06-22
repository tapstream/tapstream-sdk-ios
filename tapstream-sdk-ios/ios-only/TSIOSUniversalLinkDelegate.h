//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSIOSUniversalLinkDelegate_h
#define TSIOSUniversalLinkDelegate_h

#import "TSUniversalLinkApiResponse.h"
@protocol TSUniversalLinkDelegate
- (void)handleUniversalLink:(NSUserActivity*)userActivity completion:(void(^)(TSUniversalLinkApiResponse*))completion;
@end

@interface TSIOSUniversalLinkDelegate : NSObject<TSUniversalLinkDelegate>
+ (instancetype) universalLinkDelegateWithConfig:(TSConfig*)config
										platform:(id<TSPlatform>)platform
									  httpClient:(id<TSHttpClient>)httpClient;
@end

#endif /* TSIOSUniversalLinkDelegate_h */
