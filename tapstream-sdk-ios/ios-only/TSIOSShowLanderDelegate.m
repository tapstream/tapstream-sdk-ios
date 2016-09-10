//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "TSDefs.h"
#import "TSLanderDelegate.h"
#import "TSLanderDelegateWrapper.h"
#import "TSLanderController.h"
#import "TSURLBuilder.h"
#import "TSHttpClient.h"
#import "TSConfig.h"
#import "TSPlatform.h"
#import "TSLanderStrategy.h"
#import "TSIOSShowLanderDelegate.h"
#import "TSLogging.h"


@interface TSIOSShowLanderDelegate()
@property(strong, readwrite) TSConfig* config;
@property(strong, readwrite) id<TSLanderStrategy> landerStrategy;
@property(strong, readwrite) id<TSPlatform> platform;
@property(strong, readwrite) id<TSHttpClient> httpClient;
@end


@implementation TSIOSShowLanderDelegate

+ (instancetype) showLanderDelegateWithConfig:(TSConfig*)config
									 platform:(id<TSPlatform>)platform
							   landerStrategy:(id<TSLanderStrategy>)landerStrategy
								   httpClient:(id<TSHttpClient>)httpClient
{
	return [[self alloc] initWithConfig:config
							   platform:platform
						 landerStrategy:landerStrategy
							 httpClient:httpClient];
}

- (instancetype) initWithConfig:(TSConfig*)config
					   platform:(id<TSPlatform>)platform
				 landerStrategy:(id<TSLanderStrategy>)landerStrategy
					 httpClient:(id<TSHttpClient>)httpClient
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		self.platform = platform;
		self.landerStrategy = landerStrategy;
		self.httpClient = httpClient;
	}
	return self;
}

- (void)showLander:(TSLander*)lander withDelegate:(id<TSLanderDelegate>)delegate
{
	// Must run display code on main queue
	dispatch_async(dispatch_get_main_queue(), ^{
		UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

		TSLanderDelegateWrapper* wrappedDelegate = [[TSLanderDelegateWrapper alloc] initWithStrategyAndDelegateAndWindow:self.landerStrategy delegate:delegate window:window];
		TSLanderController* c = [TSLanderController controllerWithLander:lander delegate:wrappedDelegate];

		window.rootViewController = c;
		window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		window.opaque = NO;
		window.backgroundColor = [UIColor clearColor];

		[window makeKeyAndVisible];
	});
}

- (void)showLanderIfExistsWithDelegate:(id<TSLanderDelegate>)delegate
{
	NSURL* url = [TSURLBuilder makeLanderURL:self.config sessionId:[self.platform getSessionId]];

	[self.httpClient request:url
						data:nil
					  method:@"GET"
				  timeout_ms:kTSDefaultTimeout
				  completion:^(TSResponse* response)
	 {
		 NSData* data = [response data];

		 [TSLogging logAtLevel:kTSLoggingInfo
						format:@"Lander request complete (status %d)",
		  [response status]];

		 if(data == nil || [response failed])
		 {
			 return;
		 }

		 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		 if(!json)
		 {
			 return;
		 }

		 TSLander* lander = [TSLander landerWithDescription:json];
		 if(!lander || ![self.landerStrategy shouldShowLander:lander])
		 {
			 return;
		 }

		 [self showLander:lander withDelegate:delegate];
	 }];
}

@end