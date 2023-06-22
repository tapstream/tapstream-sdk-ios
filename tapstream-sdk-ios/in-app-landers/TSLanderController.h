//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSLanderController_h
#define TSLanderController_h

#import "TSLanderDelegate.h"
#import "TSLanderDelegateWrapper.h"
#import "TSLander.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface TSLanderController : UIViewController<WKNavigationDelegate>

@property(nonatomic, strong) TSLanderDelegateWrapper* delegate;
@property(nonatomic, strong) TSLander* lander;
@property(nonatomic, strong) WKWebView* webView;

+ (id)controllerWithLander:(TSLander*)lander delegate:(TSLanderDelegateWrapper*)delegate;

@end

#endif /* TSLanderController_h */
