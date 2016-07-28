//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <Specta/Specta.h>

#import "TSPlatform.h"
#import "TSDefaultCookieMatchStrategy.h"
#import "TSTestPersistentStorage.h"

SpecBegin(CookieMatchStrategy)

describe(@"CookieMatchStrategy", ^{
	describe(@"shouldCookieMatch", ^{
		__block TSDefaultCookieMatchStrategy* strat;
		__block id storage;

		beforeEach(^{
			storage = [[TSTestPersistentStorage alloc] init];
			strat = [TSDefaultCookieMatchStrategy cookieMatchStrategyWithStorage:storage];
		});

		it(@"should fire by default", ^{
			XCTAssertTrue([strat shouldFireCookieMatch]);
		});

		it(@"should not fire if it recently fired", ^{
			XCTAssertTrue([strat shouldFireCookieMatch]);
			[strat registerCookieMatchFired];
			XCTAssertFalse([strat shouldFireCookieMatch]);
		});

		it(@"should not fire even close to 1 day since last time", ^{
			double now = [[NSDate date] timeIntervalSince1970];
			[storage setObject:[NSNumber numberWithDouble:(now - 86390.0)] forKey:@"__tapstream_cookie_match_timestamp"];
			XCTAssertFalse([strat shouldFireCookieMatch]);
		});

		it(@"should fire after a day", ^{
			double now = [[NSDate date] timeIntervalSince1970];
			[storage setObject:[NSNumber numberWithDouble:(now - 86400.0)] forKey:@"__tapstream_cookie_match_timestamp"];
			XCTAssertTrue([strat shouldFireCookieMatch]);
		});
	});
});

SpecEnd
