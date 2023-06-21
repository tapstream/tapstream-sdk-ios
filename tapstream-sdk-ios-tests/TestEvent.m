//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>
#import <OCMock/OCMock.h>

#import "TSEvent.h"

@interface TSRequestData()
@property(strong, readonly) NSDictionary* items;
@end

@interface TSEvent(hidden)
- (void)prepare:(NSDictionary *)globalEventParams;
@end;

SpecBegin(Event)

describe(@"Event", ^{
	it(@"Can be initialized with a name and OTO flag", ^{
		TSEvent* event = [TSEvent eventWithName:@"my-event" oneTimeOnly:false];
		assertThat([event name], is(@"my-event"));
		assertThatBool([event isTransaction], isFalse());
		assertThatBool([event isOneTimeOnly], isFalse());
		assertThatInteger([[event customFields] count], equalToInteger(0));
		assertThatInteger([[event postData] count], equalToInteger(0));
		assertThat([event productId], nilValue());
	});

	it(@"Can be initialized with a transaction id, product id, and quantity", ^{
		NSString* transactionId = @"order123abc";
		NSString* productId = @"com.product.sku";
		int qty = 2;

		TSEvent* event = [TSEvent eventWithTransactionId:transactionId
											   productId:productId
												quantity:qty];
		assertThat([event name], is(@""));
		assertThatBool([event isTransaction], isTrue());
		assertThatBool([event isOneTimeOnly], isFalse());
		assertThatInteger([[event customFields] count], equalToInteger(0));

		assertThatInteger([[event postData] count], equalToInteger(3));
		assertThat([[event postData] items],
				   hasEntries(@"purchase-transaction-id", transactionId,
							  @"purchase-product-id", productId,
							  @"purchase-quantity", @"2",
							  nil));
	});

	it(@"Can be initialized with a transaction id, product id, quantity, price, and currency", ^{

		 NSString* transactionId = @"order123abc";
		 NSString* productId = @"com.product.sku";
		 int qty = 2;
		 int priceInCents = 299;
		 NSString* currency = @"USD";

		TSEvent* event = [TSEvent eventWithTransactionId:transactionId
											   productId:productId
												quantity:qty
											priceInCents:priceInCents
												currency:currency];

		assertThat([event name], is(@""));
		assertThatBool([event isTransaction], isTrue());
		assertThatBool([event isOneTimeOnly], isFalse());
		assertThatInteger([[event customFields] count], equalToInteger(0));

		assertThatInteger([[event postData] count], equalToInteger(5));
		assertThat([[event postData] items],
				   hasEntries(@"purchase-transaction-id", transactionId,
							  @"purchase-product-id", productId,
							  @"purchase-quantity", @"2",
							  @"purchase-price", @"299",
							  @"purchase-currency", currency,
							  nil));
	});

	it(@"Will accept a receipt body", ^{
		NSString* transactionId = @"order123abc";
		NSString* productId = @"com.product.sku";
		int qty = 2;
		int priceInCents = 299;
		NSString* currency = @"USD";
		NSString* receipt = @"BASE64ENCODEDRECEIPT";

		TSEvent* event = [TSEvent eventWithTransactionId:transactionId
											   productId:productId
												quantity:qty
											priceInCents:priceInCents
												currency:currency
										   base64Receipt:receipt];

		assertThat([event name], is(@""));
		assertThatBool([event isTransaction], isTrue());
		assertThatBool([event isOneTimeOnly], isFalse());
		assertThatInteger([[event customFields] count], equalToInteger(0));


		assertThatInteger([[event postData] count], equalToInteger(6));
		assertThat([[event postData] items],
				   hasEntries(@"purchase-transaction-id", transactionId,
							  @"purchase-product-id", productId,
							  @"purchase-quantity", @"2",
							  @"purchase-price", @"299",
							  @"purchase-currency", currency,
							  @"receipt-body", receipt,
							  nil));
	});


	describe(@"Event prepare method", ^{
		__block double now;
		__block NSString* nowstr;
		__block TSEvent* event;
		__block id dateCls;

		beforeAll(^{
			now = [[NSDate date] timeIntervalSince1970];
			dateCls = OCMClassMock([NSDate class]);
			OCMStub([dateCls date]).andReturn(dateCls);
			OCMStub([dateCls timeIntervalSince1970]).andReturn(now);
			nowstr = [NSString stringWithFormat:@"%f", now*1000];
		});

		afterAll(^{
			[dateCls stopMocking];
		});

		beforeEach(^{
			event = [TSEvent eventWithName:@"my-event" oneTimeOnly:false];
		});

		it(@"ignores null values", ^{
			[event addValue:nil forKey:@"someKey"];
			assertThatInteger([[event customFields] count], equalToInteger(0));
			[event addValue:@"someValue" forKey:nil];
			assertThatInteger([[event customFields] count], equalToInteger(0));
		});

		it(@"Will accept custom values and percent-encode them on prepare", ^{
			[event addValue:@"value" forKey:@"string"];
			[event addValue:@"my value" forKey:@"my&=key"];
			assertThatInteger([[event customFields] count], equalToInteger(2));
			assertThat([event customFields], hasEntries(@"string", is(@"value"),
														@"my&=key", is(@"my value"),
														nil));

			assertThat([event postData], isEmpty());
			[event prepare:nil];
			assertThat([[event postData] items],
					   hasEntries(@"custom-string", @"value",
								  @"created-ms", nowstr,
								  @"custom-my&=key", @"my value",
								  nil));
		});

		it(@"Will reject too-long keys and values", ^{
			NSMutableString* longKey = [[NSMutableString alloc] init];
			NSMutableString* longValue = [[NSMutableString alloc] init];

			for(int ii=0; ii<512; ii++)
			{
				[longKey appendString:@"k"];
				[longValue appendString:@"v"];
			}
			assertThatInteger([longValue length], equalToInteger(512));
			assertThatInteger([longKey length], equalToInteger(512));

			[event addValue:@"my-value" forKey:longKey];
			[event addValue:longValue forKey:@"my-key"];
			[event prepare:nil];

			assertThatInteger([[event postData] count], equalToInteger(1));
			assertThat([[event postData] items],
					   hasEntries(@"created-ms", nowstr, nil));
		});
	});
});

SpecEnd





/*

 @property(nonatomic, strong, readonly) NSString *uid;
 @property(nonatomic, strong, readonly) NSString *name;
 @property(nonatomic, strong, readonly) NSString *encodedName;
 @property(nonatomic, strong, readonly) NSString *productId;
 @property(nonatomic, strong, readonly) NSMutableDictionary *customFields;
 @property(nonatomic, strong, readonly) NSArray *postData;
 @property (nonatomic, assign, readonly) BOOL isOneTimeOnly;
 @property (nonatomic, assign, readonly) BOOL isTransaction;


 + (id)eventWithName:(NSString *)name oneTimeOnly:(BOOL)oneTimeOnly;

 + (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity;

 + (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode;

 + (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
	base64Receipt:(NSString *)base64Receipt;

 - (void)addValue:(NSObject *)obj forKey:(NSString *)key;


*/
