//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSLanderController_h
#define TSLanderController_h

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#import "TSLanderDelegate.h"
#import "TSLanderDelegateWrapper.h"
#import "TSLander.h"
#import <UIKit/UIKit.h>

@interface TSLanderController : UIViewController<UIWebViewDelegate>
@property(nonatomic, strong) TSLanderDelegateWrapper* delegate;

+ (id)controllerWithLander:(TSLander*)lander delegate:(TSLanderDelegateWrapper*)delegate;
@end

#else
@interface TSLanderController : NSObject
@end
#endif
#endif /* TSLanderController_h */
