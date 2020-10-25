//  Copyright © 2016 Tapstream. All rights reserved.

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "TSOffer.h"
#import "TSWordOfMouthDelegate.h"

@interface TSOfferViewController : UIViewController<WKNavigationDelegate>

@property(strong, nonatomic) TSOffer *offer;
@property(assign, nonatomic) id<TSWordOfMouthDelegate> delegate;

+ (id)controllerWithOffer:(TSOffer *)offer delegate:(id<TSWordOfMouthDelegate>)delegate;

@end
