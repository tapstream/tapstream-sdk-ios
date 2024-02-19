//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSDefs.h"
#import "TSURLBuilder.h"
#import "TSLogging.h"
#import "TSConfig.h"
#import "TSPlatform.h"
#import "TSFireEventStrategy.h"
#import "TSHttpClient.h"
#import "TSCoreListener.h"
#import "TSFireEventDelegate.h"


@interface TSEvent(hidden)
- (void)prepare:(NSDictionary *)globalEventParams;
- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName;
@end



@interface TSDefaultFireEventDelegate()
@property(strong, readwrite) TSConfig* config;
@property(readwrite) dispatch_queue_t queue;
@property(strong, readwrite) NSString* appName;
@property(strong, readwrite) NSString* platformName;
@property(strong, readwrite) id<TSPlatform> platform;
@property(strong, readwrite) id<TSFireEventStrategy> fireEventStrategy;
@property(strong, readwrite) id<TSHttpClient> httpClient;
@property(strong, readwrite) TSRequestData* requestData;

@property(strong, readwrite) id<TSCoreListener> listener;
@end


@implementation TSDefaultFireEventDelegate
+ (instancetype)defaultFireEventDelegateWithConfig:(TSConfig*)config
							   queue:(dispatch_queue_t)queue
							platform:(id<TSPlatform>)platform
				   fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
						  httpClient:(id<TSHttpClient>)httpClient
							listener:(id<TSCoreListener>)listener
{
	return [[self alloc] initWithConfig:config
								  queue:queue
							   platform:platform
					  fireEventStrategy:fireEventStrategy
							 httpClient:httpClient
							   listener:listener];
}

- (instancetype)initWithConfig:(TSConfig*)config
		   queue:(dispatch_queue_t)queue
		platform:(id<TSPlatform>)platform
fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
	  httpClient:(id<TSHttpClient>)httpClient
		listener:(id<TSCoreListener>)listener
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		self.queue = queue;
		self.platform = platform;
		self.appName = [platform getAppName];
		self.platformName = [platform getPlatformName];
		self.fireEventStrategy = fireEventStrategy;
		self.httpClient = httpClient;
		self.listener = listener;
		self.requestData = [TSDefaultFireEventDelegate buildRequestData:platform config:config];
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
		[e.postData appendItemsFromRequestData:self.requestData];

		if(![self.fireEventStrategy shouldFireEvent:e])
		{
			return;
		}

		int delay = [self.fireEventStrategy getDelay];

		dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * delay);
		dispatch_after(dispatchTime, self.queue, ^{
			[self.fireEventStrategy registerFiringEvent:e];
			NSURL* url = [TSURLBuilder makeEventURL:self.config eventName:e.encodedName];
			[self.httpClient request:url data:e.postData method:@"POST" timeout_ms:kTSDefaultTimeout completion:^(TSResponse* response){
				[self.fireEventStrategy registerResponse:response forEvent:e];
				[self handleEventRequestResponse:e response:response];

				if(completion != nil)
				{
					completion(response);
				}
			}];
		});
	}
}

- (void)handleEventRequestResponse:(TSEvent*)e response:(TSResponse*)response
{
	if([response failed])
	{
		if(response.status < 0)
		{
			[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, error=%@", response.message];
		}
		else if(response.status == 404)
		{
			[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, http code %d\nDoes your event name contain characters that are not url safe? This event will not be retried.", response.status];
		}
		else if(response.status == 403)
		{
			[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, http code %d\nAre your account name and application secret correct?  This event will not be retried.", response.status];
		}
		else
		{
			NSString *retryMsg = @"";
			if(![response retryable])
			{
				retryMsg = @"  This event will not be retried.";
			}
			[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, http code %d.%@", response.status, retryMsg];
		}

		[self.listener reportOperation:@"event-failed" arg:e.encodedName];
		if([response retryable])
		{
			[self.listener reportOperation:@"retry" arg:e.encodedName];
			[self.listener reportOperation:@"job-ended" arg:e.encodedName];
			[self fireEvent:e];
			return;
		}
	}
	else
	{
		[TSLogging logAtLevel:kTSLoggingInfo format:@"Tapstream fired event named \"%@\"", e.name];
		[self.listener reportOperation:@"event-succeeded" arg:e.encodedName];
	}

	[self.listener reportOperation:@"job-ended" arg:e.encodedName];
}




+ (TSRequestData*)buildRequestData:(id<TSPlatform>)platform config:(TSConfig*)config
{
	TSRequestData* requestData = [TSRequestData requestData];

	NSString *bundleId = config.hardcodedBundleId ? config.hardcodedBundleId : [platform getBundleIdentifier];
	// Use developer-provided values (if available) for stricter validation, otherwise get values from bundle
	NSString *shortVersion = config.hardcodedBundleShortVersionString ? config.hardcodedBundleShortVersionString : [platform getBundleShortVersion];

	[requestData appendItemsWithPrefix:@"" keysAndValues:
	 @"secret", config.sdkSecret,
	 @"sdkversion", kTSVersion,

	 @"hardware-ios-idfa", config.idfa,
	 @"hardware", config.externalIdentity,
     
	 @"uuid", [platform getSessionId],
	 @"platform", [platform getPlatformName],
	 @"model", [platform getModel],
	 @"os", [platform getOs],
	 @"app-name", [platform getAppName],
	 @"app-version", [platform getAppVersion],
	 @"package-name", [platform getPackageName],

	 // Fields necessary for receipt validation
	 @"receipt-guid", [platform getComputerGUID],
	 @"receipt-bundle-id", bundleId,
	 @"receipt-short-version", shortVersion,
	 nil];
	
	return requestData;
}


@end
