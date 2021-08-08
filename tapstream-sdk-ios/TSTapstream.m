//  Copyright © 2016 Tapstream. All rights reserved.


#import "TSTapstream.h"

#import "TSLogging.h"
#import "TSURLBuilder.h"
#import "TSDefaultAppEventSource.h"
#import "TSDefaultCoreListener.h"
#import "TSDefaultFireEventStrategy.h"
#import "TSDefaultHttpClient.h"
#import "TSDefaultPersistentStorage.h"
#import "TSDefaultPlatform.h"
#import "TSDefs.h"
#import "TSTimelineLookupDelegate.h"
#import "TSIOSStartupDelegate.h"
#import "TSIOSFireEventDelegate.h"
#import "TSIOSUniversalLinkDelegate.h"
#import "TSShowLanderDelegate.h"


static TSTapstream *instance = nil;


@interface TSEvent(hidden)
- (void)prepare:(NSDictionary *)globalEventParams;
- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName;
@end



@interface TSTapstream()
@property(nonatomic, strong) id<TSPlatform> platform;
@property(nonatomic, strong) id<TSStartupDelegate> startupDelegate;
@property(nonatomic, strong) id<TSFireEventDelegate> fireEventDelegate;
@property(nonatomic, strong) id<TSTimelineLookupDelegate> timelineLookupDelegate;
@property(nonatomic, strong) id showLanderDelegate;
@property(nonatomic, strong) id universalLinkDelegate;
@property(nonatomic) id wordOfMouthController;
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

		// Collect the IDFA, if the Advertising Framework is available
		if(!config.idfa && config.autoCollectIdfa){
			config.idfa = [platform getIdfa];
		}

		dispatch_queue_t queue = dispatch_queue_create("Tapstream Internal Queue", DISPATCH_QUEUE_CONCURRENT);

		id<TSAppEventSource> appEventSource = [[TSDefaultAppEventSource alloc] init];


		id<TSFireEventStrategy> fireEventStrategy = [TSDefaultFireEventStrategy fireEventStrategyWithStorage:storage listener:listener];
		id<TSHttpClient> httpClient = [TSDefaultHttpClient httpClientWithConfig:config];


		TSDefaultTimelineLookupDelegate* timelineLookupDelegate = [TSDefaultTimelineLookupDelegate
																   timelineLookupDelegateWithConfig:config
																   queue:queue
																   platform:platform
																   httpClient:httpClient];

		TSIOSFireEventDelegate* fireEventDelegate = [TSIOSFireEventDelegate
													 iosFireEventDelegateWithConfig:config
													 queue:queue
													 platform:platform
													 fireEventStrategy:fireEventStrategy
													 httpClient:httpClient
													 listener:listener];


		TSIOSStartupDelegate* startupDelegate = [TSIOSStartupDelegate
												 iOSStartupDelegateWithConfig:config
												 queue:queue
												 platform:platform
												 fireEventDelegate:fireEventDelegate
												 appEventSource:appEventSource];


		// Optional components

		// In-App Landers
		id landerStrategy = nil;
		id landerStrategyCls = NSClassFromString(@"TSDefaultLanderStrategy");
		id showLanderDelegateCls = NSClassFromString(@"TSIOSShowLanderDelegate");
		id<TSShowLanderDelegate> showLanderDelegate = nil;

		if(landerStrategyCls != nil && showLanderDelegateCls != nil)
		{
			SEL sel = NSSelectorFromString(@"landerStrategyWithStorage:");
			IMP imp = [landerStrategyCls methodForSelector:sel];
			landerStrategy = ((id (*)(id, SEL, id<TSPersistentStorage>))imp)(landerStrategyCls, sel, storage);

			sel = NSSelectorFromString(@"showLanderDelegateWithConfig:platform:landerStrategy:httpClient:");
			imp = [showLanderDelegateCls methodForSelector:sel];

			showLanderDelegate = ((id (*)(id, SEL, TSConfig*, id<TSPlatform>, id, id<TSHttpClient>))imp)(showLanderDelegateCls, sel, config, platform, landerStrategy, httpClient);
		}


		// Word of Mouth
		id offerStrategy = nil;
		id offerStrategyCls = NSClassFromString(@"TSDefaultOfferStrategy");
		id rewardStrategy = nil;
		id rewardStrategyCls = NSClassFromString(@"TSDefaultRewardStrategy");
		id womController = nil;
		id womControllerCls = NSClassFromString(@"TSWordOfMouthController");
		if(offerStrategyCls != nil && rewardStrategyCls != nil && womControllerCls != nil)
		{
			SEL sel = NSSelectorFromString(@"offerStrategyWithStorage:");
			IMP imp = [offerStrategyCls methodForSelector:sel];
			offerStrategy = ((id (*)(id, SEL, id<TSPersistentStorage>))imp)(offerStrategyCls, sel, storage);

			sel = NSSelectorFromString(@"rewardStrategyWithStorage:");
			imp = [rewardStrategyCls methodForSelector:sel];
			rewardStrategy = ((id (*)(id, SEL, id<TSPersistentStorage>))imp)(rewardStrategyCls, sel, storage);

			id womControllerTmp = [womControllerCls alloc];
			sel = NSSelectorFromString(@"initWithConfig:platform:offerStrategy:rewardStrategy:httpClient:");
			imp = [womControllerTmp methodForSelector:sel];
			womController = ((id (*)(id, SEL, TSConfig*, id<TSPlatform>, id, id, id<TSHttpClient>))imp)(
				womControllerTmp, sel, config, platform, offerStrategy, rewardStrategy, httpClient
			);

		}




		TSIOSUniversalLinkDelegate* universalLinkDelegate = [TSIOSUniversalLinkDelegate
															 universalLinkDelegateWithConfig:config
															 platform:platform
															 httpClient:httpClient];

		instance = [[TSTapstream alloc] initWithPlatform:platform
									   fireEventDelegate:fireEventDelegate
										 startupDelegate:startupDelegate
								timelineLookupDelegate:timelineLookupDelegate
									showLanderDelegate:showLanderDelegate
								   universalLinkDelegate:universalLinkDelegate
								   wordOfMouthController:womController];

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


- (id)initWithPlatform:(id<TSPlatform>)platform
		fireEventDelegate:(id<TSFireEventDelegate>)fireEventDelegate
				startupDelegate:(id<TSStartupDelegate>)startupDelegate
		 timelineLookupDelegate:(id<TSTimelineLookupDelegate>)timelineLookupDelegate
			 showLanderDelegate:(id<TSShowLanderDelegate>)showLanderDelegate
		  universalLinkDelegate:(id<TSUniversalLinkDelegate>)universalLinkDelegate
		  wordOfMouthController:(id)womController
{
	if((self = [super init]) != nil)
	{
		self.platform = platform;
		self.fireEventDelegate = fireEventDelegate;
		self.startupDelegate = startupDelegate;
		self.timelineLookupDelegate = timelineLookupDelegate;
		self.showLanderDelegate = showLanderDelegate;
		self.universalLinkDelegate = universalLinkDelegate;
		self.wordOfMouthController = womController;
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

- (NSString*)sessionId
{
	return [self.platform getSessionId];
}

- (void)lookupTimeline:(void(^)(TSTimelineApiResponse *))completion
{
	[self.timelineLookupDelegate lookupTimeline:completion];
}

- (void)getTimelineSummary:(void(^)(TSTimelineSummaryResponse*))completion
{
	[self.timelineLookupDelegate getTimelineSummary:completion];
}

- (void)handleUniversalLink:(NSUserActivity*)userActivity completion:(void(^)(TSUniversalLinkApiResponse*))completion
{
	[self.universalLinkDelegate handleUniversalLink:userActivity completion:completion];
}

+ (id)wordOfMouthController
{
	return [[TSTapstream instance] wordOfMouthController];
}

- (void)showLanderIfExistsWithDelegate:(id)delegate
{
	[self.showLanderDelegate showLanderIfExistsWithDelegate:delegate];
}

@end
