//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSEvent.h"
#import "TSPlatform.h"

#import "TSConfig.h"
#import "TSIOSStartupDelegate.h"
#import "TSURLBuilder.h"
#import "TSLogging.h"
#import "TSAppEventSource.h"
#import "TSIOSFireEventDelegate.h"

@interface TSDefaultStartupDelegate()
- (void) fireOpenEvent;
- (void) fireInstallEvent;
- (NSString*) openEventName;
@end

@interface TSIOSStartupDelegate()
@property(strong, readwrite) TSConfig* config;
@property(strong, readwrite) dispatch_queue_t queue;


@property(strong, readwrite) id<TSPlatform> platform;

@property(strong, readwrite) TSIOSFireEventDelegate* fireEventDelegate;
@property(strong, readwrite) id<TSAppEventSource> appEventSource;

// Delegate normal open and install events to the default impl
@property(strong, readwrite) TSDefaultStartupDelegate* defaultDelegate;
@end


@implementation TSIOSStartupDelegate
+ (instancetype)iOSStartupDelegateWithConfig:(TSConfig*)config
									   queue:(dispatch_queue_t)queue
									platform:(id<TSPlatform>)platform
						   fireEventDelegate:(TSIOSFireEventDelegate*)fireEventDelegate
							  appEventSource:(id<TSAppEventSource>)appEventSource

{
	TSDefaultStartupDelegate* defaultDelegate = [TSDefaultStartupDelegate
												 defaultStartupDelegateWithConfig:config
												 platform:platform
												 fireEventDelegate:fireEventDelegate
												 appEventSource:appEventSource];
	return [[self alloc] initWithConfig:config
								  queue:queue
							   platform:platform
					  fireEventDelegate:fireEventDelegate
						 appEventSource:appEventSource
						defaultDelegate:defaultDelegate];
}

- (instancetype) initWithConfig:(TSConfig*)config
						  queue:(dispatch_queue_t)queue
					   platform:(id<TSPlatform>)platform
			  fireEventDelegate:(TSIOSFireEventDelegate*)fireEventDelegate
				 appEventSource:(id<TSAppEventSource>)appEventSource
				defaultDelegate:(TSDefaultStartupDelegate*)defaultDelegate
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		self.queue = queue;
		self.platform = platform;
		self.fireEventDelegate = fireEventDelegate;
		self.appEventSource = appEventSource;
		self.defaultDelegate = defaultDelegate;
	}
	return self;
}


- (void)start
{

	// Fire install event if first run
	if([self.platform isFirstRun] && self.config.fireAutomaticInstallEvent)
	{
		[self.defaultDelegate fireInstallEvent];
	}


	// Fire open event

	if(self.config.fireAutomaticOpenEvent)
	{
		__unsafe_unretained __block TSDefaultStartupDelegate* defaultDelegate = self.defaultDelegate;

		[defaultDelegate fireOpenEvent];

		// Subscribe to be notified whenever the app enters the foreground
		[self.appEventSource setOpenHandler:^() {
			[defaultDelegate fireOpenEvent];
		}];
	}

	if(self.config.fireAutomaticIAPEvents)
	{
		__unsafe_unretained TSIOSStartupDelegate* me = self;
		[self.appEventSource setTransactionHandler:^(NSString *transactionId, NSString *productId, int quantity, int priceInCents, NSString *currencyCode, NSString *base64Receipt) {
			[me.fireEventDelegate fireEvent:[TSEvent eventWithTransactionId:transactionId
												productId:productId
												 quantity:quantity
											 priceInCents:priceInCents
												 currency:currencyCode
											base64Receipt:base64Receipt]];
		}];
	}
}


@end
