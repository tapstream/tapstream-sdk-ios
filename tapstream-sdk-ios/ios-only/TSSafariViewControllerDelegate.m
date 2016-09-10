//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSSafariViewControllerDelegate.h"
#import "TSLogging.h"
#import "TSResponse.h"

@implementation TSSafariViewControllerDelegate

+ (BOOL)presentSafariViewControllerWithURLAndCompletion:(NSURL*)url completion:(void (^)(TSResponse*))completion
{
	Class safControllerClass = NSClassFromString(@"SFSafariViewController");
	if(safControllerClass != nil){
		UIViewController* safController = [[safControllerClass alloc] initWithURL:url];

		if(safController != nil){
			TSSafariViewControllerDelegate* me = [[TSSafariViewControllerDelegate alloc] init];

			me.safController = safController;

			me.completion = completion;

			me.hiddenWindow = [[UIWindow alloc] initWithFrame:CGRectZero];
			me.hiddenWindow.rootViewController = me;
			me.hiddenWindow.hidden = true;

			me.view.hidden = YES;

			[safController performSelector:@selector(setDelegate:) withObject:me];

			dispatch_async(dispatch_get_main_queue(), ^{
				[me addChildViewController:safController];
				[me.view addSubview:safController.view];
				[safController didMoveToParentViewController:me];
				[me.hiddenWindow makeKeyAndVisible];
			});
			return true;
		}
	}else{
		[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream could not load SFSafariViewController, is Safari Services framework enabled?"];
	}
	return false;
}

- (void)safariViewController:(id)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully
{
	__unsafe_unretained UIWindow* window = self.hiddenWindow;
	__unsafe_unretained void (^completion)(TSResponse*) = self.completion;

	dispatch_async(dispatch_get_main_queue(), ^{
		[controller willMoveToParentViewController:nil];
		[((UIViewController*)controller).view removeFromSuperview];
		[controller removeFromParentViewController];

		[window removeFromSuperview];

		if(completion != nil){
			TSResponse* response;
			if(didLoadSuccessfully) {
				response = [TSResponse
							responseWithStatus:200
							message:[NSHTTPURLResponse localizedStringForStatusCode:200]
							data:nil];
			}else{
				response = [TSResponse
							responseWithStatus:-1
							message:@"An error occurred presenting Safari View controller"
							data:nil];
			}

			completion(response);
		}
	});
}

@end