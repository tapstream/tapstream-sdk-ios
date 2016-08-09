//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSTapstream.h"

#import "TSLogging.h"
#import "TSURLBuilder.h"


#import "TSDefaultAppEventSource.h"
#import "TSDefaultCookieMatchStrategy.h"
#import "TSDefaultCoreListener.h"
#import "TSDefaultFireEventStrategy.h"
#import "TSDefaultHttpClient.h"
#import "TSDefaultPersistentStorage.h"
#import "TSDefaultPlatform.h"




#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#define kTSPlatform @"iOS"

// iOS: Include WOM and Lander features
#import "TSLanderDelegate.h"
#import "TSLanderController.h"
#import "TSLanderDelegateWrapper.h"
#import "TSDefaultLanderStrategy.h"
#import "TSWordOfMouthDelegate.h"
#import "TSWordOfMouthController.h"

#import "TSDefaultOfferStrategy.h"
#import "TSDefaultRewardStrategy.h"
#import "TSOfferStrategy.h"
#import "TSRewardStrategy.h"
#import "TSOfferViewController.h"

#else
// Mac
#define kTSPlatform @"Mac"

#endif

#define kTSVersion @"3.0.0"
#define kTSDefaultTimeout 10000


static TSTapstream *instance = nil;


@interface TSEvent(hidden)
- (void)prepare:(NSDictionary *)globalEventParams;
- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName;
@end



@interface TSTapstream()

@property(nonatomic, strong) TSConfig *config;
@property(nonatomic, strong) id<TSPlatform> platform;
@property(nonatomic, strong) id<TSCoreListener> listener;
@property(nonatomic, strong) id<TSAppEventSource> appEventSource;
@property(nonatomic, strong) id<TSCookieMatchStrategy> cookieMatchStrategy;

@property(nonatomic, strong) id<TSFireEventStrategy> fireEventStrategy;

@property(nonatomic, strong) id<TSHttpClient> httpClient;

@property(nonatomic, strong) TSRequestData* requestData;
@property(nonatomic, strong) NSString *appName;
@property(nonatomic, strong) NSString *platformName;

@property(nonatomic) dispatch_queue_t queue;
@property(nonatomic) dispatch_semaphore_t cookieMatchFired;
@property(nonatomic) BOOL cookieMatchInProgress;

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@property(nonatomic, strong) id<TSLanderStrategy> landerStrategy;
@property(nonatomic) id wordOfMouthController;
#endif

- (void)makePostArgs;
@end


@implementation TSTapstream

+ (void)createWithConfig:(TSConfig*)config
{
	id<TSCoreListener> listener = [[TSDefaultCoreListener alloc] init];
	return [self createWithConfig:config listener:listener];
}

+ (void)createWithConfig:(TSConfig*)config listener:(id<TSCoreListener>)listener
{
	@synchronized(self)
	{
		if(instance != nil)
		{

			[TSLogging logAtLevel:kTSLoggingWarn format:@"Tapstream Warning: Tapstream already instantiated, it cannot be re-created."];
		}

		id<TSPersistentStorage> storage = [TSDefaultPersistentStorage persistentStorageWithDomain:@"__tapstream"];
		id<TSPlatform> platform = [TSDefaultPlatform platformWithStorage:storage];
		id<TSAppEventSource> appEventSource = [[TSDefaultAppEventSource alloc] init];
		id<TSCookieMatchStrategy> cookieMatchStrategy = [TSDefaultCookieMatchStrategy cookieMatchStrategyWithStorage:storage];

		id<TSFireEventStrategy> fireEventStrategy = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener];
		id<TSHttpClient> httpClient = [TSDefaultHttpClient httpClientWithConfig:config];

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		id<TSLanderStrategy> landerStrategy = [TSDefaultLanderStrategy landerStrategyWithStorage:storage];
		id<TSOfferStrategy> offerStrategy = [TSDefaultOfferStrategy offerStrategyWithStorage:storage];
		id<TSRewardStrategy> rewardStrategy = [TSDefaultRewardStrategy rewardStrategyWithStorage:storage];
		TSWordOfMouthController* womController = [[TSWordOfMouthController alloc] initWithConfig:config
																						platform:platform
																				   offerStrategy:offerStrategy
																				  rewardStrategy:rewardStrategy
																					  httpClient:httpClient];




		instance = [[TSTapstream alloc] initWithPlatform:platform
												listener:listener
										  appEventSource:appEventSource
									 cookieMatchStrategy:cookieMatchStrategy
									   fireEventStrategy:fireEventStrategy
										  landerStrategy:landerStrategy
								   wordOfMouthController:womController
											  httpClient:httpClient
												  config:config];

#else
		instance = [[TSTapstream alloc] initWithPlatform:platform
												listener:listener
										  appEventSource:appEventSource
									 cookieMatchStrategy:cookieMatchStrategy
									   fireEventStrategy:fireEventStrategy
											  httpClient:httpClient
												  config:config];
#endif

		[instance start];
	}
}

+ (instancetype)instance
{
	@synchronized(self)
	{
		NSAssert(instance != nil, @"You must first call +createWithConfig:config:");
		return instance;
	}
}

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (id)wordOfMouthController
{
	return [[TSTapstream instance] wordOfMouthController];
}
#endif

- (id)initWithPlatform:(id<TSPlatform>)platform
			  listener:(id<TSCoreListener>)listener
		appEventSource:(id<TSAppEventSource>)appEventSource
   cookieMatchStrategy:(id<TSCookieMatchStrategy>)cookieMatchStrategy
	 fireEventStrategy:(id<TSFireEventStrategy>)fireEventStrategy
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		landerStrategy:(id<TSLanderStrategy>)landerStrategy
 wordOfMouthController:(TSWordOfMouthController*)womController
#endif
			httpClient:(id<TSHttpClient>)httpClient
				config:(TSConfig *)config
{
	if((self = [super init]) != nil)
	{

		self.platform = platform;
		self.listener = listener;
		self.config = config;
		self.appEventSource = appEventSource;
		self.cookieMatchStrategy = cookieMatchStrategy;

		self.fireEventStrategy = fireEventStrategy;
		self.httpClient = httpClient;
		self.config = config;

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		self.landerStrategy = landerStrategy;

		// Collect the IDFA, if the Advertising Framework is available
		if(!config.idfa && config.autoCollectIdfa){
			config.idfa = [self.platform getIdfa];
		}

		self.wordOfMouthController = womController;
#endif

		self.requestData = nil;
		self.platformName = [kTSPlatform lowercaseString];

		self.queue = dispatch_queue_create("Tapstream Internal Queue", DISPATCH_QUEUE_CONCURRENT);
		self.cookieMatchFired = dispatch_semaphore_create(0);

	}
	return self;
}

- (void)makePostArgs
{
	if(self.requestData == nil)
	{
		self.requestData = [TSRequestData new];
	}

	NSString *bundleId = self.config.hardcodedBundleId ? self.config.hardcodedBundleId : [self.platform getBundleIdentifier];
	// Use developer-provided values (if available) for stricter validation, otherwise get values from bundle
	NSString *shortVersion = self.config.hardcodedBundleShortVersionString ? self.config.hardcodedBundleShortVersionString : [self.platform getBundleShortVersion];

	[self.requestData appendItemsWithPrefix:@"" keysAndValues:
	 @"secret", self.config.sdkSecret,
	 @"sdkversion", kTSVersion,
	 @"hardware", self.config.hardware,
	 @"hardware-odin1", self.config.odin1,
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	 @"hardware-open-udid", self.config.openUdid,
	 @"hardware-ios-udid", self.config.udid,
	 @"hardware-ios-idfa", self.config.idfa,
	 @"hardware-ios-secure-udid", self.config.secureUdid,
#else
	 @"hardware-mac-serial-number", self.config.serialNumber,
#endif
	 @"uuid", [self.platform getSessionId],
	 @"platform", kTSPlatform,
	 @"vendor", [self.platform getManufacturer],
	 @"model", [self.platform getModel],
	 @"os", [self.platform getOs],
	 @"os-build", [self.platform getOsBuild],
	 @"resolution", [self.platform getResolution],
	 @"locale", [self.platform getLocale],
	 @"app-name", [self.platform getAppName],
	 @"app-version", [self.platform getAppVersion],
	 @"package-name", [self.platform getPackageName],
	 @"gmtoffset", [NSString stringWithFormat:@"%ld", (long)[[NSTimeZone systemTimeZone] secondsFromGMT]],

	 // Fields necessary for receipt validation
	 @"receipt-guid", [self.platform getComputerGUID],
	 @"receipt-bundle-id", bundleId,
	 @"receipt-short-version", shortVersion,
	 nil];
}

- (void)start
{

	// Cache app name and generate post args
	self.appName = [self.platform getAppName];
	if(self.appName == nil)
	{
		self.appName = @"";
	}

	[self makePostArgs];


	// Fire install event if first run
	if([self.platform isFirstRun])
	{
		BOOL firingCookieMatch = false;
		if(self.config.attemptCookieMatch) // cookie match replaces initial install and open events
		{
			NSString *eventName = self.config.installEventName;
			if(eventName == nil)
			{
				eventName = [NSString stringWithFormat:@"%@-%@-install", self.platformName, self.appName];
			}

			NSURL* url = [TSURLBuilder makeCookieMatchURL:self.config
												eventName:eventName
													 data:self.requestData];
			__unsafe_unretained TSTapstream* me = self;

			void (^completion)(TSResponse*) = ^(TSResponse* response){
				[me.cookieMatchStrategy registerCookieMatchFired];
				dispatch_semaphore_signal(me.cookieMatchFired);
			};
			firingCookieMatch = [self.httpClient asyncSafariRequest:url completion:completion];
			if(firingCookieMatch){
				// Block queue until cookie match fired or for 10 seconds
				dispatch_barrier_async(self.queue, ^{
					dispatch_semaphore_wait(self.cookieMatchFired,
											dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10));
					[self.platform registerFirstRun];
					[TSLogging logAtLevel:kTSLoggingInfo format:@"Cookie Match Complete"];
				});
			}

		}

		if(!firingCookieMatch && self.config.fireAutomaticInstallEvent)
		{
			if(self.config.installEventName != nil)
			{
				[self fireEvent:[TSEvent eventWithName:self.config.installEventName oneTimeOnly:YES]];
			}
			else
			{
				NSString *eventName = [NSString stringWithFormat:@"%@-%@-install", self.platformName, self.appName];
				[self fireEvent:[TSEvent eventWithName:eventName oneTimeOnly:YES]];
			}
			[self.platform registerFirstRun];
		}
	}


	// Fire open event
	__unsafe_unretained TSTapstream* me = self;
	if(self.config.fireAutomaticOpenEvent)
	{
		// Fire the initial open event
		if(self.config.openEventName != nil)
		{
			[self fireEvent:[TSEvent eventWithName:self.config.openEventName oneTimeOnly:NO]];
		}
		else
		{
			NSString *eventName = [NSString stringWithFormat:@"%@-%@-open", self.platformName, self.appName];
			[self fireEvent:[TSEvent eventWithName:eventName oneTimeOnly:NO]];
		}

		// Subscribe to be notified whenever the app enters the foreground
		[self.appEventSource setOpenHandler:^() {
			if(me.config.openEventName != nil)
			{
				[me fireEvent:[TSEvent eventWithName:me.config.openEventName oneTimeOnly:NO]];
			}
			else
			{
				NSString *eventName = [NSString stringWithFormat:@"%@-%@-open", me.platformName, me.appName];
				[me fireEvent:[TSEvent eventWithName:eventName oneTimeOnly:NO]];
			}
		}];
	}

	if(self.config.fireAutomaticIAPEvents)
	{
		[self.appEventSource setTransactionHandler:^(NSString *transactionId, NSString *productId, int quantity, int priceInCents, NSString *currencyCode, NSString *base64Receipt) {
			[me fireEvent:[TSEvent eventWithTransactionId:transactionId
				productId:productId
				quantity:quantity
				priceInCents:priceInCents
				currency:currencyCode
				base64Receipt:base64Receipt]];
		}];
	}
}

- (void)sendEventRequest:(TSEvent*)e completion:(void(^)(TSResponse*))completion{
	__unsafe_unretained TSTapstream* me = self;

	[self.fireEventStrategy registerFiringEvent:e];
	[e.postData appendItemsFromRequestData:self.requestData];

	//TSRequestData* data = [self.requestData requestDataByAppendingItemsFromRequestData:e.postData];

	void (^fireEvent)() = ^{
		NSURL* url = [TSURLBuilder makeEventURL:me.config eventName:e.encodedName];
		[me.httpClient request:url data:e.postData method:@"POST" timeout_ms:kTSDefaultTimeout completion:completion];
	};

	if(self.config.attemptCookieMatch && [self.cookieMatchStrategy shouldFireCookieMatch])
	{
		[self.cookieMatchStrategy startCookieMatch];


		NSURL* url = [TSURLBuilder makeCookieMatchURL:self.config eventName:e.name data:e.postData];


		// SFSafariViewController must run on main thread
		dispatch_async(dispatch_get_main_queue(), ^{
			BOOL firingCookieMatch = [self.httpClient asyncSafariRequest:url completion:^(TSResponse* response){
				if(me != nil){
					[me.cookieMatchStrategy registerCookieMatchFired];
					dispatch_semaphore_signal(me.cookieMatchFired);

					if (response == nil){
						completion([TSResponse responseWithStatus:-1 message:@"Request incomplete" data:nil]);
					}else{
						dispatch_async(me.queue, ^{
							completion(response);
						});
					}
				}
			}];

			if (!firingCookieMatch){
				dispatch_async(self.queue, fireEvent);
			}
		});
	}else{
		dispatch_async(self.queue, fireEvent);
	}
}



- (void)handleEventRequestResponse:(TSEvent*)e response:(TSResponse*)response
{

	[self.fireEventStrategy registerResponse:response forEvent:e];

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

- (void)fireEvent:(TSEvent *)e
{
	[self fireEvent:e completion:nil];
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
			[self sendEventRequest:e completion:^(TSResponse* response){
				[self handleEventRequestResponse:e response:response];
				if(completion != nil)
				{
					completion(response);
				}
			}];
		});
	}
}

- (void)lookupTimeline:(void(^)(TSTimelineApiResponse *))completion
{
	if(completion == nil)
	{
		return;
	}

    dispatch_async(self.queue, ^{
		[self lookupTimeline:[completion copy] tries:3 timeout_ms:kTSDefaultTimeout];
    });
}

- (void)lookupTimeline:(void(^)(TSTimelineApiResponse *))completion tries:(int)tries timeout_ms:(int)timeout_ms
{
	NSURL* url = [TSURLBuilder makeConversionURL:self.config sessionId:[self.platform getSessionId]];
	[self.httpClient request:url data:nil method:@"GET" timeout_ms:timeout_ms tries:tries completion:^(TSResponse* response){
		if([response failed] && ![response retryable])
		{
			[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: 4XX while getting conversion data"];
		}

		// Run completion on the main thread
		dispatch_async(dispatch_get_main_queue(), ^{
			completion([TSTimelineApiResponse timelineApiResponseWithResponse:response]);
		});

	}];
}

- (void)dispatchOnQueue:(void(^)())completion
{
	dispatch_async(self.queue, completion);
}


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
/* Universal link handling -- iOS 8+ only */

- (void)handleUniversalLink:(NSUserActivity*)userActivity completion:(void(^)(TSUniversalLinkApiResponse*))completion
{
	if(![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]
	   || [userActivity webpageURL] == nil)
	{
		completion([TSUniversalLinkApiResponse universalLinkApiResponseWithStatus:kTSULUnknown]);
		return;
	}

	 NSURL* url = [userActivity webpageURL];

	// Respond according to deeplink query
	NSURL* deeplinkQueryUrl = [TSURLBuilder makeDeeplinkQueryURL:self.config forURL:[url absoluteString]];

	[self.httpClient request:deeplinkQueryUrl
				  completion:^(TSResponse* response){

					  TSUniversalLinkApiResponse* ul = [TSUniversalLinkApiResponse universalLinkApiResponseWithResponse:response];

					  // Fire simulated click if Tapstream recognizes the link
					  if (ul.status != kTSULUnknown){
						  NSURL* simulatedClickUrl = [TSURLBuilder makeSimulatedClickURL:url];


						  [self.httpClient asyncSafariRequest:simulatedClickUrl
												   completion:^(TSResponse* response){

													   if (response.status >= 200 && response.status < 300){
														   [TSLogging logAtLevel:kTSLoggingInfo format:@"Universal link simulated click succeeded for url %@", url];
													   }else{
														   [TSLogging logAtLevel:kTSLoggingWarn format:@"Universal link simulated click failed for url %@", url];
													   }
												   }];
					  }
					  
					  if(completion != nil)
					  {
						  completion(ul);
					  }
				  }];

}

#endif
#endif


#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (void)fetchLanderIfNotShown:(void(^)(TSLander*))completion
{

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
#endif



@end
