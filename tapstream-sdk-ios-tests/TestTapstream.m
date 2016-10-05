//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
//#import "TSWordOfMouthController.h"

#import "TSTapstream.h"

SpecBegin(TestTapstream)

describe(@"Tapstream", ^{

	it(@"Dynamically initializes the word of mouth controller", ^{
		TSConfig* conf = [TSConfig configWithAccountName:@"sdktest" sdkSecret:@"somesecret"];
		[TSTapstream createWithConfig:conf];

		id womController = [TSTapstream wordOfMouthController];

		assertThat(womController, notNilValue());
		assertThat(NSStringFromClass([womController class]), is(@"TSWordOfMouthController"));
	});
});

SpecEnd
