//  Copyright © 2016 Tapstream. All rights reserved.


#import "TSOfferViewController.h"

@implementation TSOfferViewController

@synthesize offer, delegate;

+ (instancetype)controllerWithOffer:(TSOffer *)offer delegate:(id<TSWordOfMouthDelegate>)delegate
{
    return [[TSOfferViewController alloc] initWithNibName:@"TSOfferView" bundle:nil offer:offer delegate:delegate];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil offer:(TSOffer *)offerVal delegate:(id<TSWordOfMouthDelegate>)delegateVal
{
    if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.offer = offerVal;

        self.delegate = delegateVal;
        ((WKWebView *)self.view).navigationDelegate = self;
        [((WKWebView *)self.view) loadHTMLString:self.offer.markup baseURL:[NSURL URLWithString:@""]];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    ((WKWebView *)self.view).scrollView.scrollEnabled = NO;
    ((WKWebView *)self.view).scrollView.opaque = NO;
    ((WKWebView *)self.view).scrollView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
}


- (void)close
{
    [UIView transitionWithView:self.view.superview
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ [self.view removeFromSuperview]; }
                    completion:NULL];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
       if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
           NSString *url = [navigationAction.request.URL absoluteString];
           if([url isEqualToString:@"close"]) {
               [self close];
               [self.delegate dismissedOffer:NO];
               decisionHandler(WKNavigationActionPolicyCancel);
               return;
           } else if([url isEqualToString:@"accept"]) {
               [self close];
               [self.delegate dismissedOffer:YES];
               decisionHandler(WKNavigationActionPolicyCancel);
               return;
           }
       }

        decisionHandler(WKNavigationActionPolicyAllow);

}

@end
