//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSStartupDelegate_h
#define TSStartupDelegate_h

#import "TSPlatform.h"
#import "TSConfig.h"
#import "TSFireEventDelegate.h"
#import "TSAppEventSource.h"

@protocol TSStartupDelegate
- (void)start;
@end

@interface TSDefaultStartupDelegate : NSObject<TSStartupDelegate>
+ (instancetype) defaultStartupDelegateWithConfig:(TSConfig*)config
										 platform:(id<TSPlatform>)platform
								fireEventDelegate:(id<TSFireEventDelegate>)fireEventDelegate
								   appEventSource:(id<TSAppEventSource>)appEventSource;
@end

#endif /* TSStartupDelegate_h */
