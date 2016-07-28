//  Copyright © 2016 Tapstream. All rights reserved.

#import <OCMock/OCMock.h>
#import <Specta/Specta.h>
#import <Foundation/Foundation.h>
#import "TSPlatform.h"
#import "TSDefaultPlatform.h"
//#import "TSLanderStrategy.h"
#import "TSDefaultLanderStrategy.h"
#import "TSTestPersistentStorage.h"


NSDictionary* testDescription(int ident, NSString* url) {
	return [NSDictionary dictionaryWithObjectsAndKeys:
					   url, @"url",
					   @"<html><p></p>MY_THING</html>", @"markup",
					   [NSNumber numberWithInt:ident], @"id", nil];
}

SpecBegin(TSDefaultLanderStrategy)

describe(@"TSDefaultLanderStrategy", ^{
	__block id<TSPersistentStorage> storage;
	__block id<TSLanderStrategy> strat;

	beforeEach(^{
		storage = [[TSTestPersistentStorage alloc] init];
		strat = [TSDefaultLanderStrategy landerStrategyWithStorage:storage];
	});

	it(@"Does not show invalid landers", ^{
		TSLander* lander = [TSLander landerWithDescription:testDescription(1, @"badurl")];

		XCTAssertFalse([lander isValid]);
		XCTAssertFalse([strat shouldShowLander:lander]);
	});

	it(@"Saves shown status correctly", ^{

		TSLander* lander1 = [TSLander landerWithDescription:testDescription(12,  @"http://myurl.com/mypath")];
		TSLander* lander2 = [TSLander landerWithDescription:testDescription(27,  @"http://myurl.com/mypath2")];

		XCTAssertTrue([lander1 isValid]);
		XCTAssertTrue([lander2 isValid]);

		XCTAssertTrue([strat shouldShowLander:lander1]);
		XCTAssertTrue([strat shouldShowLander:lander2]);

		[strat registerLanderShown:lander1];

		XCTAssertFalse([strat shouldShowLander:lander1]);
		XCTAssertTrue([strat shouldShowLander:lander2]);

		[strat registerLanderShown:lander2];

		XCTAssertFalse([strat shouldShowLander:lander1]);
		XCTAssertFalse([strat shouldShowLander:lander2]);
	});

});

SpecEnd
