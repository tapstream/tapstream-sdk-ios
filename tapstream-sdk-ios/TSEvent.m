//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSEvent.h"
#import <sys/time.h>
#import <stdio.h>
#import <stdlib.h>
#import "TSLogging.h"
#import "TSURLEncoder.h"

@interface TSEvent()
@end


@implementation TSEvent

@synthesize uid, name, encodedName, isOneTimeOnly, isTransaction, productId, customFields, postData;
+ (instancetype)eventWithName:(NSString *)eventName oneTimeOnly:(BOOL)oneTimeOnlyArg
{
	return [[self alloc] initWithName:eventName oneTimeOnly:oneTimeOnlyArg];
}

+ (instancetype)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
{
	return [[self alloc] initWithTransactionId:transactionId productId:productId quantity:quantity];
}

+ (instancetype)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
{
	return [[self alloc] initWithTransactionId:transactionId productId:productId quantity:quantity priceInCents:priceInCents currency:currencyCode];
}

+ (instancetype)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
	base64Receipt:(NSString *)base64Receipt
{
	return [[self alloc] initWithTransactionId:transactionId productId:productId quantity:quantity priceInCents:priceInCents currency:currencyCode base64Receipt:base64Receipt];
}

- (instancetype)initWithName:(NSString *)eventName
	oneTimeOnly:(BOOL)oneTimeOnlyArg
{
	if((self = [super init]) != nil)
	{
		firstFiredTime = 0;
		uid = [self makeUid];
		[self setName:eventName];
		postData = [TSRequestData new];
		isOneTimeOnly = oneTimeOnlyArg;
		isTransaction = NO;
		customFields = [NSMutableDictionary dictionaryWithCapacity:16];
	}
	return self;
}

- (instancetype)initWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productIdVal
	quantity:(int)quantity
{
	if((self = [super init]) != nil)
	{
		name = @"";
		firstFiredTime = 0;
		uid = [self makeUid];
		productId = productIdVal;
		postData = [TSRequestData new];
		isOneTimeOnly = NO;
		isTransaction = YES;
		customFields = [NSMutableDictionary dictionaryWithCapacity:16];

		[self.postData appendItemsWithPrefix:@"" keysAndValues:
		 @"purchase-transaction-id", transactionId,
		 @"purchase-product-id", productIdVal,
		 @"purchase-quantity", [NSString stringWithFormat:@"%d", quantity],
		 nil];
	}
	return self;
}

- (instancetype)initWithTransactionId:(NSString *)transactionId
				  productId:(NSString *)productIdVal
				   quantity:(int)quantity
			   priceInCents:(int)priceInCents
				   currency:(NSString *)currencyCode
{
	if((self = [self initWithTransactionId:transactionId
								 productId:productIdVal
								  quantity:quantity]) != nil)
	{
		[self.postData appendItemsWithPrefix:@"" keysAndValues:
		 @"purchase-price", [NSString stringWithFormat:@"%d", priceInCents],
		 @"purchase-currency", currencyCode,
		 nil];
	}

	return self;
}

- (instancetype)initWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productIdVal
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
	base64Receipt:(NSString *)base64Receipt
{
	if((self = [self initWithTransactionId:transactionId
								 productId:productIdVal
								  quantity:quantity
							  priceInCents:priceInCents
								  currency:currencyCode]) != nil)
	{
		[self.postData appendItemWithPrefix:@"" key:@"receipt-body" value:base64Receipt];
	}
	return self;
}

- (NSString *)makeUid
{
	NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
	return [NSString stringWithFormat:@"%.0f:%f", t*1000, arc4random() / (float)0x10000000];
}

- (void)setName:(NSString *)eventName
{
	name = [[[eventName lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"." withString:@"_"];

	encodedName = [TSURLEncoder encodeStringForPath:name];
}

- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName
{
	NSString *eventName = [NSString stringWithFormat:@"%@-%@-purchase-%@", platformName, [appName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], productId];
	[self setName:eventName];
}

- (void)addValue:(NSString *)obj forKey:(NSString *)key
{
	if(key != nil && obj != nil) {
		[self.customFields setObject:obj forKey:key];
	}
}

- (void)prepare:(NSDictionary *)globalEventParams
{
	// Only record the time of the first fire attempt
	if(firstFiredTime == 0)
	{
		firstFiredTime = [[NSDate date] timeIntervalSince1970];

		for(NSString *key in globalEventParams)
		{
			if([self.customFields objectForKey:key] == nil)
			{
				[self addValue:[globalEventParams valueForKey:key] forKey:key];
			}
		}

		[postData appendItemWithPrefix:@"" key:@"created-ms" value:[NSString stringWithFormat:@"%f", firstFiredTime*1000]];
		
		for(NSString *key in self.customFields)
		{
			[postData appendItemWithPrefix:@"custom-" key:key value:[self.customFields objectForKey:key]];
		}
	}
}


@end
