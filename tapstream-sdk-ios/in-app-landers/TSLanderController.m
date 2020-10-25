//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSLanderController.h"

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@implementation TSLanderController

+ (id)controllerWithLander:(TSLander*)lander delegate:(TSLanderDelegateWrapper*)delegate
{
	NSBundle* bund = [NSBundle bundleForClass:TSLanderController.self];
	return [[TSLanderController alloc] initWithNibName:@"TSLanderView" bundle:bund lander:lander delegate:delegate];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil lander:(TSLander*)lander  delegate:(TSLanderDelegateWrapper*)delegate
{
	if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.delegate = delegate;
        
        ((WKWebView *)self.view).navigationDelegate = self;
        
        if(lander.url != nil){
            [((WKWebView *)self.view) loadRequest:[NSURLRequest requestWithURL:lander.url]];
        }else{
            [((WKWebView *)self.view) loadHTMLString:lander.html baseURL:nil];
        }

        [self.delegate showedLander:lander];
	}
	return self;
}

- (void)close
{
	[((WKWebView *) self.view) loadHTMLString:@"" baseURL:nil];
	[UIView transitionWithView:self.view.superview
					  duration:0.3
					   options:UIViewAnimationOptionTransitionCrossDissolve
					animations:^{ [self.view removeFromSuperview]; }
					completion:NULL];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self close];
    [self.delegate didFailLoadWithError:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSString *url = [navigationAction.request.URL absoluteString];
        if([url hasSuffix:@"close"]) {
            [self close];
            [self.delegate dismissedLander];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}


@end
#else
@implementation TSLanderController
@end
#endif
