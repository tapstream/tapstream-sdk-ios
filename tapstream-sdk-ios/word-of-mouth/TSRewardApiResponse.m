//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSRewardApiResponse.h"


@interface TSRewardApiResponse()
@property (strong, readwrite) NSArray<TSReward*>* rewards;
@property (strong, readwrite) TSResponse* response;
@property (strong, readwrite) NSError* error;
@end


@implementation TSRewardApiResponse
@synthesize error;
+ (instancetype)rewardApiResponseWithResponse:(TSResponse*)response strategy:(id<TSRewardStrategy>)strategy
{
	NSMutableArray<TSReward*>* rewards = [NSMutableArray arrayWithCapacity:32];

	if([response failed])
	{
		return [[self alloc] initWithResponse:response rewards:rewards error:[response error]];
	}

	NSError* error;
	NSArray *json = [NSJSONSerialization JSONObjectWithData:response.data options:0 error:&error];
	if(error != nil)
	{
		return [[self alloc] initWithResponse:response rewards:rewards error:error];
	}

	if(!json) {
		error = [TSError errorWithCode:kTSInvalidResponse message:@"Invalid JSON returned by reward endpoint"];
		return [[self alloc] initWithResponse:response rewards:rewards error:error];
	}

	// Populate rewards
	[json enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		TSReward* reward = [TSReward rewardWithDescription:(NSDictionary *)obj];
		if([strategy eligible:reward]){
			[rewards addObject:reward];
		}
	}];

	return [[self alloc] initWithResponse:response rewards:rewards error:nil];
}

- (instancetype)initWithResponse:(TSResponse*)responseVal
						 rewards:(NSArray<TSReward*>*)rewardsVal
						   error:(NSError*)errorVal
{
	if((self = [self init]) != nil)
	{
		self.response = responseVal;
		self.rewards = rewardsVal;
		self.error = errorVal;
	}
	return self;
}

- (bool)failed { return [self error] != nil; }
@end
