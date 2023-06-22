//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSConfig.h"
#import "TSPlatform.h"
#import "TSStartupDelegate.h"

#import "TSEvent.h"


@interface TSDefaultStartupDelegate()
@property(strong, readwrite) TSConfig* config;
@property(strong, readwrite) NSString* platformName;
@property(strong, readwrite) NSString* appName;

@property(strong, readwrite) id<TSPlatform> platform;


@property(strong, readwrite) id<TSFireEventDelegate> fireEventDelegate;
@property(strong, readwrite) id<TSAppEventSource> appEventSource;
@end


@implementation TSDefaultStartupDelegate

+ (instancetype) defaultStartupDelegateWithConfig:(TSConfig*)config
										 platform:(id<TSPlatform>)platform
								fireEventDelegate:(id<TSFireEventDelegate>)fireEventDelegate
								   appEventSource:(id<TSAppEventSource>)appEventSource
{

	return [[self alloc] initWithConfig:config
							   platform:platform
			fireEventDelegate:fireEventDelegate
						 appEventSource:appEventSource];
}

- (instancetype) initWithConfig:(TSConfig*)config
					   platform:(id<TSPlatform>)platform
			  fireEventDelegate:(id<TSFireEventDelegate>)fireEventDelegate
				 appEventSource:(id<TSAppEventSource>)appEventSource
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		self.platform = platform;
		self.platformName = [platform getPlatformName];
		self.appName = [platform getAppName];
		self.fireEventDelegate = fireEventDelegate;
		self.appEventSource = appEventSource;
	}
	return self;
}


- (void) start
{
	// Fire install event if first run
	if([self.platform isFirstRun] && self.config.fireAutomaticInstallEvent)
	{
		[self fireInstallEvent];
	}


	// Fire open event
	if(self.config.fireAutomaticOpenEvent)
	{
		__unsafe_unretained TSDefaultStartupDelegate* me = self;
		[self fireOpenEvent];

		// Subscribe to be notified whenever the app enters the foreground
		[self.appEventSource setOpenHandler:^() {
			[me fireOpenEvent];
		}];
	}

	if(self.config.fireAutomaticIAPEvents)
	{
		__unsafe_unretained TSDefaultStartupDelegate* me = self;
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

- (void) fireInstallEvent
{
	[self.fireEventDelegate fireEvent:[TSEvent eventWithName:[self installEventName] oneTimeOnly:YES]];
	[self.platform registerFirstRun];
}


- (void) fireOpenEvent
{
	[self.fireEventDelegate fireEvent:[TSEvent eventWithName:[self openEventName] oneTimeOnly:NO]];
}


// Name formatting


- (NSString*)formatEventName:(NSString*)eventType
{
	return [NSString stringWithFormat:@"%@-%@-%@", self.platformName, self.appName, eventType];
}


- (NSString*)openEventName
{
	NSString *eventName = self.config.openEventName;
	if(eventName == nil)
	{
		eventName = [self formatEventName:@"open"];
	}
	return eventName;
}


- (NSString*)installEventName
{
	NSString *eventName = self.config.installEventName;
	if(eventName == nil)
	{
		eventName = [self formatEventName:@"install"];
	}
	return eventName;
}
@end
