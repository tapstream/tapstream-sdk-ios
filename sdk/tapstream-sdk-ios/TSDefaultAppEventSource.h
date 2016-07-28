//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "TSAppEventSource.h"

@interface TSDefaultAppEventSource : NSObject<TSAppEventSource, SKPaymentTransactionObserver, SKProductsRequestDelegate> {
@private
	id<NSObject> foregroundedEventObserver;
	TSOpenHandler onOpen;
	TSTransactionHandler onTransaction;
	NSMutableDictionary *requestTransactions;
	NSMutableDictionary *transactionReceiptSnapshots;
}

- (void)setOpenHandler:(TSOpenHandler)handler;
- (void)setTransactionHandler:(TSTransactionHandler)handler;

@end
