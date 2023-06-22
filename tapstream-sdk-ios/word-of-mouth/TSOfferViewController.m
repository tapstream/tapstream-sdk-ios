//  Copyright © 2023 Tapstream. All rights reserved.


#import "TSOfferViewController.h"

@implementation TSOfferViewController

+ (instancetype)controllerWithOffer:(TSOffer *)offer delegate:(id<TSWordOfMouthDelegate>)delegate {
    TSOfferViewController *controller =  [[TSOfferViewController alloc] initWithOffer: offer delegate:delegate];
    return controller;
}

- (instancetype)initWithOffer:(TSOffer *)offer delegate: (id<TSWordOfMouthDelegate>)delegate  {
    if (self = [super init]) {
        self.delegate = delegate;
        self.offer = offer;
    }
    return self;
}

- (void)dealloc {
    [self.webView stopLoading];
    self.webView.navigationDelegate = nil;
}

- (void)loadView {
    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.opaque = NO;
    self.webView.scrollView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = self.webView;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self loadContent];
}

- (void)loadContent {
    [self.webView loadHTMLString:self.offer.markup baseURL:nil];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)offerAccepted {
    [self.delegate dismissedOffer:YES];
    
    UIActivityViewController* avc = [[UIActivityViewController alloc]
                                     initWithActivityItems:@[self.offer.message]
                                     applicationActivities:nil];
    
    avc.completionWithItemsHandler = ^(NSString* activityType, BOOL completed, NSArray* items, NSError* error){
        
        if (completed) {
            NSString* cleanedType = activityType;
            
            if([activityType isEqualToString:UIActivityTypeMail]){
                cleanedType = @"email";
            }else if([activityType isEqualToString:UIActivityTypeMessage]){
                cleanedType = @"messaging";
            }else if([activityType isEqualToString:UIActivityTypePostToFacebook]){
                cleanedType = @"facebook";
            }else if([activityType isEqualToString:UIActivityTypePostToTwitter]){
                cleanedType = @"twitter";
            }
            
            [self.delegate completedShare:self.offer.ident socialMedium:cleanedType];
            [self close];
        }
        
        [self.delegate dismissedSharing];
        
    };
    
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:avc animated:YES completion:nil];
        [self.delegate showedSharing:self.offer.ident];
    }
    else if ([self respondsToSelector:@selector(popoverPresentationController)])
    {
        avc.popoverPresentationController.sourceView = self.view;
        [self presentViewController:avc animated:YES completion:nil];
        [self.delegate showedSharing:self.offer.ident];
    }
    
}

- (void)offerRejected {
    [self close];
    [self.delegate dismissedOffer:NO];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSString *url = [navigationAction.request.URL absoluteString];
        if([url isEqualToString:@"close"]) {
            [self offerRejected];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        } else if([url isEqualToString:@"accept"]) {
            [self offerAccepted];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
