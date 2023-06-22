//  Copyright © 2023 Tapstream. All rights reserved.

#import "TSOffer.h"

@interface TSOffer()

@property(strong, nonatomic, readwrite) NSDictionary *description;
@property(assign, nonatomic, readwrite) NSUInteger ident;
@property(strong, nonatomic, readwrite) NSString *insertionPoint;
@property(strong, nonatomic, readwrite) NSString *message;
@property(strong, nonatomic, readwrite) NSString *url;
@property(assign, nonatomic, readwrite) NSInteger rewardMinimumInstalls;
@property(strong, nonatomic, readwrite) NSString *rewardSku;
@property(strong, nonatomic, readwrite) NSString *bundle;
@property(assign, nonatomic, readwrite) NSInteger minimumAge;
@property(assign, nonatomic, readwrite) NSInteger rateLimit;
@property(strong, nonatomic, readwrite) NSString *markup;

@end



@implementation TSOffer

@synthesize description, ident, insertionPoint, message, url, rewardMinimumInstalls, rewardSku, bundle, minimumAge, rateLimit, markup;

+ (instancetype)offerWithDescription:(NSDictionary *)descriptionVal uuid:(NSString *)uuid
{
	return [[self alloc] initWithDescription:descriptionVal uuid:uuid];
}

- (id)initWithDescription:(NSDictionary *)descriptionVal uuid:(NSString *)uuid
{
    if(self = [super init]) {
        self.description = descriptionVal;
        self.ident = [[descriptionVal objectForKey:@"id"] unsignedIntegerValue];
        self.insertionPoint = [descriptionVal objectForKey:@"insertion_point"];
        self.message = [descriptionVal objectForKey:@"message"];
        self.url = [descriptionVal objectForKey:@"offer_url"];
        
        if(self.url) {
            self.url = [self.url stringByReplacingOccurrencesOfString:@"SDK_SESSION_ID" withString:uuid];
            if(self.message) {
                self.message = [self.message stringByReplacingOccurrencesOfString:@"OFFER_URL" withString:self.url];
            }
        }
        
        self.rewardMinimumInstalls = [[descriptionVal objectForKey:@"reward_minimum_installs"] integerValue];
        self.rewardSku = [descriptionVal objectForKey:@"reward_sku"];
        self.bundle = [descriptionVal objectForKey:@"bundle"];
        self.minimumAge = [[descriptionVal objectForKey:@"minimum_age"] integerValue];
        self.rateLimit = [[descriptionVal objectForKey:@"rate_limit"] integerValue];
        self.markup = [descriptionVal objectForKey:@"markup"];
    }
    return self;
}

@end
