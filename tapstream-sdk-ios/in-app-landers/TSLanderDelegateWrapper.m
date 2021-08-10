//  Copyright © 2016 Tapstream. All rights reserved.
//  Wraps TSLanderDelegate to record the lander being shown when it completes.

#import "TSLanderDelegateWrapper.h"
#import <Foundation/Foundation.h>
#import "TSLanderDelegate.h"
#import "TSPlatform.h"
#import "TSLogging.h"

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
- (void)didFailLoadWithError:(NSError*)error
{
	[TSLogging logAtLevel:kTSLoggingError format:@"An error occurred while loading lander (%@).", error];
	[self.window removeFromSuperview];
	self.window = nil;
}
@end
