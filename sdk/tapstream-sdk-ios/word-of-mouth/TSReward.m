//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSReward.h"

@interface TSReward()

@property(assign, nonatomic, readwrite) NSUInteger offerIdent;
@property(strong, nonatomic, readwrite) NSString *insertionPoint;
@property(strong, nonatomic, readwrite) NSString *sku;
@property(assign, nonatomic, readwrite) NSInteger installs;
@property(assign, nonatomic, readwrite) NSInteger minimumInstalls;

@end

@implementation TSReward

@synthesize offerIdent, insertionPoint, sku, installs, minimumInstalls;


+ (instancetype)rewardWithDescription:(NSDictionary *)descriptionVal
{
	return [[self alloc] initWithDescription:descriptionVal];
}
- (instancetype)initWithDescription:(NSDictionary *)descriptionVal
{
    if((self = [super init]) != nil) {
        self.offerIdent = [[descriptionVal objectForKey:@"offer_id"] unsignedIntegerValue];
        self.insertionPoint = [descriptionVal objectForKey:@"insertion_point"];
        self.sku = [descriptionVal objectForKey:@"reward_sku"];
        self.installs = [[descriptionVal objectForKey:@"installs"] integerValue];
        self.minimumInstalls = [[descriptionVal objectForKey:@"reward_minimum_installs"] integerValue];
    }
    return self;
}
@end