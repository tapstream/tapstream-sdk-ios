//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSLanderController.h"

@implementation TSLanderController

+ (id)controllerWithLander:(TSLander*)lander delegate:(TSLanderDelegateWrapper*)delegate
{
    return [[TSLanderController alloc] initWithLander:lander delegate:delegate];
}

- (id)initWithLander: (TSLander*)lander delegate:(TSLanderDelegateWrapper*)delegate
{
    if(self = [super init]) {
        self.delegate = delegate;
        self.lander = lander;
    }
    return self;
}

- (void)dealloc {
    [self.webView stopLoading];
    self.webView.navigationDelegate = nil;
}


- (void)loadView
{
    WKWebView* webView = [[WKWebView alloc] init];
    webView.navigationDelegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = webView;
    self.webView = webView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadContent];
    [self.delegate showedLander:self.lander];
}

- (void)loadContent
{
    if(self.lander.url != nil){
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.lander.url]];
    }else{
        [self.webView loadHTMLString:self.lander.html baseURL:nil];
    }
}

- (void)close
{
    [UIView transitionWithView:self.view.superview
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ [self.view removeFromSuperview]; }
                    completion:NULL];
}

#pragma mark - WKNavigationDelegate
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
