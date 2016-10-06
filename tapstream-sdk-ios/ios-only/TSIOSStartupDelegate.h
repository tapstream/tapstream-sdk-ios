//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSIOSStartupDelegate_h
#define TSIOSStartupDelegate_h


#import "TSPlatform.h"
#import "TSHttpClient.h"
#import "TSConfig.h"

#import "TSAppEventSource.h"
#import "TSIOSFireEventDelegate.h"
#import "TSStartupDelegate.h"

@interface TSIOSStartupDelegate : NSObject<TSStartupDelegate>
+ (instancetype)iOSStartupDelegateWithConfig:(TSConfig*)config
									   queue:(dispatch_queue_t)queue
									platform:(id<TSPlatform>)platform
						   fireEventDelegate:(TSIOSFireEventDelegate*)fireEventDelegate
							  appEventSource:(id<TSAppEventSource>)appEventSource;
@end

#endif /* TSIOSStartupDelegate_h */
