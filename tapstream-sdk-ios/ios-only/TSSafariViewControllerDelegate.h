//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSResponse.h"

#if (TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
#import <UIKit/UIKit.h>


@interface TSSafariViewControllerDelegate : UIViewController

@property(nonatomic, strong) NSURL* url;
@property(nonatomic, copy) void (^completion)(TSResponse*);
@property(nonatomic, strong) UIWindow* hiddenWindow;
@property(nonatomic, strong) UIViewController* safController;

+ (BOOL)presentSafariViewControllerWithURLAndCompletion:(NSURL*)url completion:(void (^)(TSResponse*))completion;
@end
#else

@interface TSSafariViewControllerDelegate : NSObject
+ (BOOL)presentSafariViewControllerWithURLAndCompletion:(NSURL*)url completion:(void (^)(TSResponse*))completion;
@end
#endif