//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSFireEventDelegate_h
#define TSFireEventDelegate_h

#import "TSConfig.h"
#import "TSFireEventStrategy.h"
#import "TSCoreListener.h"
#import "TSHttpClient.h"
#import "TSPlatform.h"
#import "TSEvent.h"
#import "TSResponse.h"

@protocol TSFireEventDelegate
- (void)fireEvent:(TSEvent *)e;
- (void)fireEvent:(TSEvent *)e completion:(void(^)(TSResponse*))completion;
@end

@interface TSDefaultFireEventDelegate : NSObject<TSFireEventDelegate>
+ (instancetype)defaultFireEventDelegateWithConfig:(TSConfig*)config
											 queue:(dispatch_queue_t)queue
										  platform:(id<TSPlatform>)platform
								 fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
										httpClient:(id<TSHttpClient>)httpClient
										  listener:(id<TSCoreListener>)listener;
@end

#endif /* TSFireEventDelegate_h */
