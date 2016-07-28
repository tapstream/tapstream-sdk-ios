//  Copyright © 2016 Tapstream. All rights reserved.

#import <UIKit/UIKit.h>
#import "TSOffer.h"
#import "TSWordOfMouthDelegate.h"

@interface TSOfferViewController : UIViewController<UIWebViewDelegate>

@property(strong, nonatomic) TSOffer *offer;
@property(assign, nonatomic) id<TSWordOfMouthDelegate> delegate;

+ (id)controllerWithOffer:(TSOffer *)offer delegate:(id<TSWordOfMouthDelegate>)delegate;

@end