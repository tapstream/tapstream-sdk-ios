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
#import "TSDefs.h"

#import "TSTimelineLookupDelegate.h"


#ifdef TS_IOS_ONLY

#import "TSIOSStartupDelegate.h"
#import "TSIOSFireEventDelegate.h"
#import "TSIOSShowLanderDelegate.h"
#import "TSIOSUniversalLinkDelegate.h"

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

#endif

#ifdef TS_MAC_ONLY
// Mac
#import "TSStartupDelegate.h"
#endif



static TSTapstream *instance = nil;


@interface TSEvent(hidden)
- (void)prepare:(NSDictionary *)globalEventParams;
- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName;
@end



@interface TSTapstream()
@property(nonatomic, strong) id<TSStartupDelegate> startupDelegate;
@property(nonatomic, strong) id<TSFireEventDelegate> fireEventDelegate;
@property(nonatomic, strong) id<TSTimelineLookupDelegate> timelineLookupDelegate;

#ifdef TS_IOS_ONLY

@property(nonatomic, strong) id<TSShowLanderDelegate> showLanderDelegate;
@property(nonatomic, strong) id<TSUniversalLinkDelegate> universalLinkDelegate;
@property(nonatomic) id wordOfMouthController;

#endif
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

#ifdef TS_IOS_ONLY
		// Collect the IDFA, if the Advertising Framework is available
		if(!config.idfa && config.autoCollectIdfa){
			config.idfa = [platform getIdfa];
		}
#endif

		dispatch_queue_t queue = dispatch_queue_create("Tapstream Internal Queue", DISPATCH_QUEUE_CONCURRENT);

		id<TSAppEventSource> appEventSource = [[TSDefaultAppEventSource alloc] init];


		id<TSFireEventStrategy> fireEventStrategy = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener];
		id<TSHttpClient> httpClient = [TSDefaultHttpClient httpClientWithConfig:config];


		TSDefaultTimelineLookupDelegate* timelineLookupDelegate = [TSDefaultTimelineLookupDelegate
																   timelineLookupDelegateWithConfig:config
																   queue:queue
																   platform:platform
																   httpClient:httpClient];
#ifdef TS_IOS_ONLY
		id<TSCookieMatchStrategy> cookieMatchStrategy = [TSDefaultCookieMatchStrategy cookieMatchStrategyWithStorage:storage];
		id<TSLanderStrategy> landerStrategy = [TSDefaultLanderStrategy landerStrategyWithStorage:storage];
		id<TSOfferStrategy> offerStrategy = [TSDefaultOfferStrategy offerStrategyWithStorage:storage];
		id<TSRewardStrategy> rewardStrategy = [TSDefaultRewardStrategy rewardStrategyWithStorage:storage];
		TSWordOfMouthController* womController = [[TSWordOfMouthController alloc]
												  initWithConfig:config
												  platform:platform
												  offerStrategy:offerStrategy
												  rewardStrategy:rewardStrategy
												  httpClient:httpClient];

		TSIOSFireEventDelegate* fireEventDelegate = [TSIOSFireEventDelegate
													 iosFireEventDelegateWithConfig:config
													 queue:queue
													 platform:platform
													 fireEventStrategy:fireEventStrategy
													 cookieMatchStrategy:cookieMatchStrategy
													 httpClient:httpClient
													 listener:listener];



		TSIOSStartupDelegate* startupDelegate = [TSIOSStartupDelegate
												 iOSStartupDelegateWithConfig:config
												 queue:queue
												 platform:platform
												 fireEventDelegate:fireEventDelegate
												 appEventSource:appEventSource];



		TSIOSShowLanderDelegate* showLanderDelegate = [TSIOSShowLanderDelegate
													   showLanderDelegateWithConfig:config
													   platform:platform
													   landerStrategy:landerStrategy
													   httpClient:httpClient];

		TSIOSUniversalLinkDelegate* universalLinkDelegate = [TSIOSUniversalLinkDelegate
															 universalLinkDelegateWithConfig:config
															 httpClient:httpClient];



		instance = [[TSTapstream alloc] initWithFireEventDelegate:fireEventDelegate
												  startupDelegate:startupDelegate
										   timelineLookupDelegate:timelineLookupDelegate
											   showLanderDelegate:showLanderDelegate
											universalLinkDelegate:universalLinkDelegate
											wordOfMouthController:womController];

#else
		TSDefaultFireEventDelegate* fireEventDelegate = [TSDefaultFireEventDelegate
														 defaultFireEventDelegateWithConfig:config
														 queue:queue
														 platform:platform
														 fireEventStrategy:fireEventStrategy
														 httpClient:httpClient
														 listener:listener];
		TSDefaultStartupDelegate* startupDelegate = [TSDefaultStartupDelegate
													 defaultStartupDelegateWithConfig:config
													 platform:platform
													 fireEventDelegate:fireEventDelegate
													 appEventSource:appEventSource];

		instance = [[TSTapstream alloc] initWithFireEventDelegate:fireEventDelegate
												  startupDelegate:startupDelegate
										   timelineLookupDelegate:timelineLookupDelegate];
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


- (id)initWithFireEventDelegate:(id<TSFireEventDelegate>)fireEventDelegate
				startupDelegate:(id<TSStartupDelegate>)startupDelegate
		 timelineLookupDelegate:(id<TSTimelineLookupDelegate>)timelineLookupDelegate
#ifdef TS_IOS_ONLY
			 showLanderDelegate:(id<TSShowLanderDelegate>)showLanderDelegate
		  universalLinkDelegate:(id<TSUniversalLinkDelegate>)universalLinkDelegate
		  wordOfMouthController:(TSWordOfMouthController*)womController
#endif
{
	if((self = [super init]) != nil)
	{
		self.fireEventDelegate = fireEventDelegate;
		self.startupDelegate = startupDelegate;
		self.timelineLookupDelegate = timelineLookupDelegate;
#ifdef TS_IOS_ONLY
		self.showLanderDelegate = showLanderDelegate;
		self.universalLinkDelegate = universalLinkDelegate;
		self.wordOfMouthController = womController;
#endif
	}
	return self;
}

- (void)start
{
	[self.startupDelegate start];
}


- (void)fireEvent:(TSEvent *)e
{
	[self fireEvent:e completion:nil];
}

- (void)fireEvent:(TSEvent *)e completion:(void(^)(TSResponse*))completion
{
	[self.fireEventDelegate fireEvent:e completion:completion];
}

- (void)lookupTimeline:(void(^)(TSTimelineApiResponse *))completion
{
	[self.timelineLookupDelegate lookupTimeline:completion];
}


// IOS-only features

#ifdef TS_IOS_ONLY
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
/* Universal link handling -- iOS 8+ only */

- (void)handleUniversalLink:(NSUserActivity*)userActivity completion:(void(^)(TSUniversalLinkApiResponse*))completion
{
	[self.universalLinkDelegate handleUniversalLink:userActivity completion:completion];
}

#endif
#endif

+ (id)wordOfMouthController
{
	return [[TSTapstream instance] wordOfMouthController];
}

- (void)showLanderIfExistsWithDelegate:(id<TSLanderDelegate>)delegate
{
	[self.showLanderDelegate showLanderIfExistsWithDelegate:delegate];
}
#endif



@end
