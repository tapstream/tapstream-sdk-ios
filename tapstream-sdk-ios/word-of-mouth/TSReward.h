//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

@interface TSReward : NSObject

@property(assign, nonatomic, readonly) NSUInteger offerIdent;
@property(strong, nonatomic, readonly) NSString *insertionPoint;
@property(strong, nonatomic, readonly) NSString *sku;
@property(assign, nonatomic, readonly) NSInteger installs;
@property(assign, nonatomic, readonly) NSInteger minimumInstalls;

+ (instancetype) rewardWithDescription:(NSDictionary *)description;

@end
