//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSIOSFireEventDelegate_h
#define TSIOSFireEventDelegate_h

#import "TSPlatform.h"
#import "TSHttpClient.h"
#import "TSConfig.h"
#import "TSCookieMatchStrategy.h"
#import "TSFireEventStrategy.h"
#import "TSCoreListener.h"
#import "TSLogging.h"
#import "TSAppEventSource.h"
#import "TSIOSFireEventDelegate.h"
#import "TSFireEventDelegate.h"

@interface TSIOSFireEventDelegate : NSObject<TSFireEventDelegate>
+ (instancetype)iosFireEventDelegateWithConfig:(TSConfig*)config
										 queue:(dispatch_queue_t)queue
									  platform:(id<TSPlatform>)platform
							 fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
						   cookieMatchStrategy:(id<TSCookieMatchStrategy>)cookieMatchStrategy
									httpClient:(id<TSHttpClient>)httpClient
									  listener:(id<TSCoreListener>)listener;
- (BOOL)fireCookieMatch:(NSString*)eventName completion:(void(^)(TSResponse*))completion;
@end

#endif /* TSIOSFireEventDelegate_h */
