//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSConfig.h"
#import "TSEvent.h"
#import "TSRequestData.h"
#import "TSResponse.h"
#import "TSFireEventStrategy.h"
#import "TSIOSFireEventDelegate.h"
#import "TSURLBuilder.h"
#import "TSHttpClient.h"
#import "TSLogging.h"
#import "TSPlatform.h"

#define kTSDefaultTimeout 10000

@interface TSEvent(hidden)
- (void)prepare:(NSDictionary *)globalEventParams;
- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName;
@end

@interface TSDefaultFireEventDelegate()
@property(strong, readwrite) TSRequestData* requestData;
- (void)handleEventRequestResponse:(TSEvent*)e response:(TSResponse*)response;
@end

@interface TSIOSFireEventDelegate()
@property(strong, readwrite) TSConfig* config;
@property(strong, readwrite) dispatch_queue_t queue;
@property(strong, readwrite) NSString* appName;
@property(strong, readwrite) NSString* platformName;
@property(strong, readwrite) id<TSPlatform> platform;
@property(strong, readwrite) id<TSFireEventStrategy> fireEventStrategy;
@property(strong, readwrite) id<TSHttpClient> httpClient;


@property(strong, readwrite) TSDefaultFireEventDelegate* defaultFireEventDelegate;
@end


@implementation TSIOSFireEventDelegate

// Public interface

+ (instancetype)iosFireEventDelegateWithConfig:(TSConfig*)config
										 queue:(dispatch_queue_t)queue
									  platform:(id<TSPlatform>)platform
							 fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
									httpClient:(id<TSHttpClient>)httpClient
									  listener:(id<TSCoreListener>)listener
{

	TSDefaultFireEventDelegate* defaultDelegate = [TSDefaultFireEventDelegate
												   defaultFireEventDelegateWithConfig:config
												   queue:queue
												   platform:platform
												   fireEventStrategy:fireEventStrategy
												   httpClient:httpClient
												   listener:listener];

	return [[self alloc] initWithConfig:config
								  queue:queue
							   platform:platform
			fireEventStrategy:fireEventStrategy
							 httpClient:httpClient
						defaultDelegate:defaultDelegate
			];
}

- (instancetype)initWithConfig:(TSConfig*)config
						 queue:(dispatch_queue_t)queue
					  platform:(id<TSPlatform>)platform
			 fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
					httpClient:(id<TSHttpClient>)httpClient
			   defaultDelegate:(TSDefaultFireEventDelegate*)defaultDelegate
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		self.queue = queue;
		self.appName = [platform getAppName];
		self.platformName = [platform getPlatformName];
		self.platform = platform;
		self.fireEventStrategy = fireEventStrategy;
		self.httpClient = httpClient;
		self.defaultFireEventDelegate = defaultDelegate;
	}
	return self;
}


- (void)fireEvent:(TSEvent *)e
{
	return [self fireEvent:e completion:nil];
}

- (void)fireEvent:(TSEvent *)e completion:(void(^)(TSResponse*))completion
{
	@synchronized(self)
	{
		if(e.isTransaction)
		{
			[e setTransactionNameWithAppName:self.appName platform:self.platformName];
		}

		// Add global event params if they have not yet been added
		// Notify the event that we are going to fire it so it can record the time and bake its post data
		[e prepare:self.config.globalEventParams];

		if(![self.fireEventStrategy shouldFireEvent:e])
		{
			return;
		}

		int delay = [self.fireEventStrategy getDelay];

		dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * delay);
		dispatch_after(dispatchTime, self.queue, ^{
			[self.fireEventStrategy registerFiringEvent:e];
			[self sendEventRequest:e completion:^(TSResponse* response){
				[self.fireEventStrategy registerResponse:response forEvent:e];
				[self.defaultFireEventDelegate handleEventRequestResponse:e response:response];

				if(completion != nil)
				{
					completion(response);
				}
			}];
		});
	}
}

- (void)sendEventRequest:(TSEvent*)e completion:(void(^)(TSResponse*))completion{
	__unsafe_unretained TSIOSFireEventDelegate* me = self;
	[e.postData appendItemsFromRequestData:[self.defaultFireEventDelegate requestData]];

	dispatch_async(self.queue, ^{
		NSURL* url = [TSURLBuilder makeEventURL:me.config eventName:e.encodedName];
		[me.httpClient request:url data:e.postData method:@"POST" timeout_ms:kTSDefaultTimeout completion:completion];
	});

}
@end
