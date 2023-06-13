//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSDefaultRewardStrategy.h"
#import "TSLogging.h"


#define kTSRewardConsumptionCounts @"__tapstream_reward_consumption_counts"

@interface TSDefaultRewardStrategy()
@property(strong, readwrite)id<TSPersistentStorage>storage;
@property(strong, nonatomic) NSMutableDictionary *rewardConsumptionCounts;
@end

@interface TSReward()
-(void)consume;
@end

@implementation TSDefaultRewardStrategy
+ (instancetype)rewardStrategyWithStorage:(id<TSPersistentStorage>)storage
{
	return [[self alloc] initWithStorage:storage];
}
- (instancetype)initWithStorage:(id<TSPersistentStorage>)storage
{
	if((self = [self init]) != nil)
	{
		self.storage = storage;

		NSDictionary *consumptionCounts = [self.storage objectForKey:kTSRewardConsumptionCounts];
		self.rewardConsumptionCounts = [NSMutableDictionary dictionaryWithDictionary:consumptionCounts ? consumptionCounts : [NSDictionary dictionary]];
	}
	return self;
}

- (long)quantity:(TSReward*)reward
{
	@synchronized(self.rewardConsumptionCounts) {
		NSNumber *consumedVal = [self.rewardConsumptionCounts objectForKey:[[NSNumber numberWithInteger:reward.offerIdent] stringValue]];

		NSInteger consumed = consumedVal != nil ? [consumedVal integerValue] : 0;

		long rewardCount = [reward installs] / [reward minimumInstalls];
		long quantity = MAX(0, rewardCount - consumed);


		return quantity;
	}

}

- (bool)eligible:(TSReward*)reward
{
	// Calculate quantity for each reward, and only return those with a positive quantity
	long quantity = [self quantity:reward];

	if(quantity > 0){

		[TSLogging logAtLevel:kTSLoggingInfo
					   format:@"Eligible reward: %@", [reward sku]];
	}else{
		[TSLogging logAtLevel:kTSLoggingInfo
					   format:@"Reward not eligible: %@", [reward sku]];
	}

	return quantity > 0;
}

- (void)registerClaimedReward:(TSReward*)reward
{
	long quantity = [self quantity:reward];
	if(reward && quantity > 0) {
		[TSLogging logAtLevel:kTSLoggingInfo
					   format:@"Consuming reward '%@' ...", [reward sku]];
		@synchronized(self.rewardConsumptionCounts) {
			NSString *key = [[NSNumber numberWithInteger:reward.offerIdent] stringValue];
			NSNumber *consumedVal = [self.rewardConsumptionCounts objectForKey:key];
			NSInteger consumed = consumedVal != nil ? [consumedVal integerValue] : 0;
			consumed += quantity;
			[self.rewardConsumptionCounts setObject:[NSNumber numberWithInteger:consumed] forKey:key];
			[self.storage setObject:self.rewardConsumptionCounts forKey:kTSRewardConsumptionCounts];
		}
	}
}
@end
