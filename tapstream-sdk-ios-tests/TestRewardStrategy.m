//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSTestPersistentStorage.h"
#import "TSDefaultRewardStrategy.h"

TSReward* mockRewardWithCounts(int c1, int c2)
{
	id reward = OCMClassMock([TSReward class]);
	OCMStub([reward offerIdent]).andReturn(1);
	OCMStub([reward installs]).andReturn(c1);
	OCMStub([reward minimumInstalls]).andReturn(c2);
	return reward;
}

SpecBegin(RewardStrategy)
describe(@"RewardStrategy", ^{
	__block TSTestPersistentStorage* storage;
	__block TSDefaultRewardStrategy* strategy;

	beforeEach(^{
		storage = [[TSTestPersistentStorage alloc] init];
		strategy = [TSDefaultRewardStrategy rewardStrategyWithStorage:storage];
	});

	it(@"Rejects rewards with fewer installs than minimum", ^{
		id reward = mockRewardWithCounts(0, 3);
		assertThatBool([strategy eligible:reward], isFalse());
	});
	it(@"Accepts eligible rewards", ^{
		id reward = mockRewardWithCounts(3, 3);
		assertThatBool([strategy eligible:reward], isTrue());
	});

	it(@"Rejects rewards that have been claimed", ^{
		id reward = mockRewardWithCounts(3, 3);
		[strategy registerClaimedReward:reward];
		reward = mockRewardWithCounts(3, 3);
		assertThatBool([strategy eligible:reward], isFalse());
	});

	it(@"Accepts rewards that have been claimed too few times", ^{
		id reward = mockRewardWithCounts(3, 3);
		[strategy registerClaimedReward:reward];
		reward = mockRewardWithCounts(6, 3);
		assertThatBool([strategy eligible:reward], isTrue());
	});

	it(@"Persists reward counts via storage", ^{
		id reward = mockRewardWithCounts(3, 3);
		[strategy registerClaimedReward:reward];

		// Recycle reward and strategy
		reward = mockRewardWithCounts(6, 3);
		strategy = [TSDefaultRewardStrategy rewardStrategyWithStorage:storage];
		assertThatBool([strategy eligible:reward], isTrue());
	});
});
SpecEnd
