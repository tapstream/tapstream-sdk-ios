//  Copyright © 2016 Tapstream. All rights reserved.

#pragma once
#import <Foundation/Foundation.h>

@interface TSURLEncoder : NSObject

+ (NSString *)encodeStringForQuery:(NSString *)s;
+ (NSString *)encodeStringForPath:(NSString *)s;
+ (NSString *)cleanForQuery:(NSString *)s;
+ (NSString *)cleanForPath:(NSString *)s;
/*
+ (NSString *)stringify:(id)value;
+ (NSString *)stringifyInteger:(int)value;
+ (NSString *)stringifyUnsignedInteger:(uint)value;
+ (NSString *)stringifyDouble:(double)value;
+ (NSString *)stringifyFloat:(float)value;
+ (NSString *)stringifyBOOL:(BOOL)value;
+ (NSString *)stringifyBool:(bool)value;
 */

+ (BOOL)checkKeyLength:(NSString*)key;
+ (BOOL)checkValueLength:(NSString*)value;

@end
