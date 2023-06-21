//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

@interface TSOffer : NSObject

@property(strong, nonatomic, readonly) NSDictionary *description;
@property(assign, nonatomic, readonly) NSUInteger ident;
@property(strong, nonatomic, readonly) NSString *insertionPoint;
@property(strong, nonatomic, readonly) NSString *message;
@property(strong, nonatomic, readonly) NSString *url;
@property(assign, nonatomic, readonly) NSInteger rewardMinimumInstalls;
@property(strong, nonatomic, readonly) NSString *rewardSku;
@property(strong, nonatomic, readonly) NSString *bundle;
@property(assign, nonatomic, readonly) NSInteger minimumAge;
@property(assign, nonatomic, readonly) NSInteger rateLimit;
@property(strong, nonatomic, readonly) NSString *markup;

+ (instancetype)offerWithDescription:(NSDictionary *)description uuid:(NSString *)uuid;

@end
