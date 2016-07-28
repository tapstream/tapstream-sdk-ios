//  Copyright © 2016 Tapstream. All rights reserved.
//  Wraps TSLanderDelegate to record the lander being shown when it completes.

#import "TSLanderDelegateWrapper.h"

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#import <Foundation/Foundation.h>
#import "TSLanderDelegate.h"
#import "TSPlatform.h"

@implementation TSLanderDelegateWrapper
- initWithStrategyAndDelegateAndWindow:(id<TSLanderStrategy>)strategy delegate:(id<TSLanderDelegate>)delegate window:(UIWindow*)window
{
	if((self = [super init]) != nil)
	{
		self.strategy = strategy;
		self.delegate = delegate;
		self.window = window;
	}
	return self;
}
- (void)showedLander:(TSLander*)lander
{
	[self.strategy registerLanderShown:lander];
	[self.delegate showedLander:lander];
}
- (void)dismissedLander
{
	[self.delegate dismissedLander];
	[self.window removeFromSuperview];
	self.window = nil;
}
- (void)submittedLander
{
	[self.delegate submittedLander];
	[self.window removeFromSuperview];
	self.window = nil;
}
@end
#else
@implementation TSLanderDelegateWrapper
@end
#endif
