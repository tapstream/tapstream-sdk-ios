//  Copyright © 2023 Tapstream. All rights reserved.

#import <UIKit/UIKit.h>
#import "TSDefaultAppEventSource.h"


Class TSSKPaymentQueue = nil;
Class TSSKProductsRequest = nil;

static void TSLoadStoreKitClasses(void)
{
	if(TSSKPaymentQueue == nil)
	{
		TSSKPaymentQueue = NSClassFromString(@"SKPaymentQueue");
		TSSKProductsRequest = NSClassFromString(@"SKProductsRequest");
	}	
}


@interface TSRequestWrapper : NSObject<NSCopying>
@property(nonatomic, strong) SKProductsRequest *request;
+ (id)requestWrapperWithRequest:(SKProductsRequest *)req;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (NSUInteger)hash;
@end

@implementation TSRequestWrapper
@synthesize request;
+ (id)requestWrapperWithRequest:(SKProductsRequest *)req
{
	return [[self alloc] initWithRequest:req];
}
- (id)initWithRequest:(SKProductsRequest *)req
{
	if((self = [super init]) != nil)
	{
		self.request = req;
	}
	return self;
}
- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone] initWithRequest:self.request];
}
- (BOOL)isEqual:(id)other
{
	if(self == other)
	{
		return YES;
	}
	if(!other || ![other isKindOfClass:[self class]])
	{
		return NO;
	}
	return self.request == ((TSRequestWrapper *)other).request;
}
- (NSUInteger)hash
{
	return (NSUInteger)self.request;
}
@end





@interface TSDefaultAppEventSource()

@property(nonatomic, strong) id<NSObject> foregroundedEventObserver;
@property(nonatomic, copy) TSOpenHandler onOpen;
@property(nonatomic, copy) TSTransactionHandler onTransaction;
@property(nonatomic, strong) NSMutableDictionary *requestTransactions;
@property(nonatomic, strong) NSMutableDictionary *transactionReceiptSnapshots;

- (id)init;
- (void)dealloc;

@end


@implementation TSDefaultAppEventSource

@synthesize foregroundedEventObserver, onOpen, onTransaction, requestTransactions, transactionReceiptSnapshots;

- (id)init
{
	if((self = [super init]) != nil)
	{
		TSLoadStoreKitClasses();

		self.foregroundedEventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if(self->onOpen != nil)
			{
                self->onOpen();
			}
		}];
		
		if(TSSKPaymentQueue != nil)
		{
			self.requestTransactions = [NSMutableDictionary dictionary];
			[(id)[TSSKPaymentQueue defaultQueue] addTransactionObserver:self];
		}
		self.transactionReceiptSnapshots = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction *transaction in transactions)
	{
		switch(transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
			{
				
				// Load receipt data and stash it for use after the transaction is finished.
				// Note:  We have to grab this data now because consumable purchases get removed from
				// the receipt after the transaction is finished.
				
				NSData *receipt = nil;
				
				// For ios 7 and up, try to get the Grand Unified Receipt.
                NSBundle *mainBundle = [NSBundle mainBundle];
                if ([mainBundle respondsToSelector:@selector(appStoreReceiptURL)])
                {
                    receipt = [NSData dataWithContentsOfURL:[mainBundle appStoreReceiptURL]];
				}
				
				if(receipt && transaction.transactionIdentifier)
				{
					@synchronized(self)
					{
						[self.transactionReceiptSnapshots setObject:receipt forKey:transaction.transactionIdentifier];
					}
				}
			}
			break;
            case SKPaymentTransactionStateFailed:
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateRestored:
            case SKPaymentTransactionStateDeferred:
            break;
            
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
	if(onTransaction != nil)
	{
		NSMutableDictionary *transForProduct = [NSMutableDictionary dictionary];
		for(SKPaymentTransaction *trans in transactions)
		{
			if(trans.transactionState == SKPaymentTransactionStatePurchased)
			{
				[transForProduct setValue:trans forKey:trans.payment.productIdentifier];
			}
		}

		if([transForProduct count] > 0)
		{
			SKProductsRequest *req = [[TSSKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:[transForProduct allKeys]]];
			req.delegate = self;
			@synchronized(self)
			{
				[self.requestTransactions setObject:transForProduct forKey:[TSRequestWrapper requestWrapperWithRequest:req]];
			}
			[req start];
		}
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSMutableDictionary *transactions = nil;
	@synchronized(self)
	{
		TSRequestWrapper *key = [TSRequestWrapper requestWrapperWithRequest:request];
		transactions = [self.requestTransactions objectForKey:key];
		[self.requestTransactions removeObjectForKey:key];
	}
	if(transactions)
	{
		for(SKProduct *product in response.products)
		{
			SKPaymentTransaction *transaction = [transactions objectForKey:product.productIdentifier];
			if(transaction)
			{
				NSData *receipt = nil;
				@synchronized(self)
				{
					receipt = [self.transactionReceiptSnapshots objectForKey:transaction.transactionIdentifier];
					[self.transactionReceiptSnapshots removeObjectForKey:transaction.transactionIdentifier];
				}
				
				NSString *b64Receipt = @"";
				if(receipt)
				{
					b64Receipt = [receipt base64EncodedStringWithOptions:0];
				}
				
				onTransaction(transaction.transactionIdentifier,
					product.productIdentifier,
					(int)transaction.payment.quantity,
					(int)([product.price doubleValue] * 100),
					[product.priceLocale objectForKey:NSLocaleCurrencyCode],
					b64Receipt
					);
            }
		}
	}
}

- (void)setOpenHandler:(TSOpenHandler)handler
{
	self.onOpen = handler;
}

- (void)setTransactionHandler:(TSTransactionHandler)handler
{
	self.onTransaction = handler;
}

- (void)dealloc
{
	if(TSSKPaymentQueue != nil)
	{
		[(id)[TSSKPaymentQueue defaultQueue] removeTransactionObserver:self];
	}

	if(foregroundedEventObserver != nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:foregroundedEventObserver];
	}
}

@end




