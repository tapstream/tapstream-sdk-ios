//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
//#import "TSWordOfMouthController.h"

#import "TSTapstream.h"

SpecBegin(TestTapstream)

describe(@"Tapstream", ^{
	__block TSConfig* conf = [TSConfig configWithAccountName:@"sdktest" sdkSecret:@"somesecret"];


	it(@"Dynamically initializes the word of mouth controller", ^{

		[TSTapstream createWithConfig:conf];

		id womController = [TSTapstream wordOfMouthController];

		assertThat(womController, notNilValue());
		assertThat(NSStringFromClass([womController class]), is(@"TSWordOfMouthController"));

	});

	it(@"exposes the session id", ^{
		[TSTapstream createWithConfig:conf];

		assertThat([[TSTapstream instance] sessionId], notNilValue());
	});
});

SpecEnd
