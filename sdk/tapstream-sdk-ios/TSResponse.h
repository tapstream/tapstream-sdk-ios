//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>
#import "TSFallable.h"

@interface TSResponse : NSObject<TSFallable> {
@private
	int status;
	NSString *message;
	NSData *data;
}

@property(nonatomic, assign, readonly) int status;
@property(nonatomic, retain, readonly) NSString *message;
@property(nonatomic, retain, readonly) NSData *data;

+ (instancetype)responseWithStatus:(int)status message:(NSString *)message data:(NSData *)data;

- (bool)retryable;
- (bool)succeeded;

@end

