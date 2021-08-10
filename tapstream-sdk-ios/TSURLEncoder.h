//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>

@interface TSURLEncoder : NSObject

+ (NSString *)encodeStringForQuery:(NSString *)s;
+ (NSString *)encodeStringForPath:(NSString *)s;
+ (NSString *)cleanForQuery:(NSString *)s;
+ (NSString *)cleanForPath:(NSString *)s;

+ (BOOL)checkKeyLength:(NSString*)key;
+ (BOOL)checkValueLength:(NSString*)value;

@end
