//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>
#import "TSRequestData.h"

@interface TSEvent : NSObject {
@private
	NSTimeInterval firstFiredTime;
	NSString *uid;
	NSString *name;
	NSString *encodedName;
	BOOL isOneTimeOnly;
	BOOL isTransaction;
	NSString *productId;
	NSMutableDictionary *customFields;
	TSRequestData *postData;
}

@property(nonatomic, strong, readonly) NSString *uid;
@property(nonatomic, strong, readonly) NSString *name;
@property(nonatomic, strong, readonly) NSString *encodedName;
@property(nonatomic, strong, readonly) NSString *productId;
@property(nonatomic, strong, readonly) NSMutableDictionary *customFields;
@property(nonatomic, strong, readonly) TSRequestData *postData;
@property (nonatomic, assign, readonly) BOOL isOneTimeOnly;
@property (nonatomic, assign, readonly) BOOL isTransaction;


+ (instancetype)eventWithName:(NSString *)name oneTimeOnly:(BOOL)oneTimeOnly;

+ (instancetype)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity;

+ (instancetype)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode;

+ (instancetype)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
	base64Receipt:(NSString *)base64Receipt;

- (void)addValue:(NSString *)obj forKey:(NSString *)key;
@end



