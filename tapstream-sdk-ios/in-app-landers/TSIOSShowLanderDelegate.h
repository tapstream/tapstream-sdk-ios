//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSIOSShowLanderDelegate_h
#define TSIOSShowLanderDelegate_h

#import "TSLanderStrategy.h"
#import "TSShowLanderDelegate.h"

@interface TSIOSShowLanderDelegate : NSObject<TSShowLanderDelegate>
+ (instancetype) showLanderDelegateWithConfig:(TSConfig*)config
									 platform:(id<TSPlatform>)platform
							   landerStrategy:(id<TSLanderStrategy>)landerStrategy
								   httpClient:(id<TSHttpClient>)httpClient;
@end

#endif /* TSIOSShowLanderDelegate_h */
