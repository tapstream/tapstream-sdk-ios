//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSRequestData.h"

SpecBegin(RequestData)
describe(@"RequestData", ^{
	it(@"Handles nils", ^{
		TSRequestData* data = [TSRequestData requestData];

		[data appendItemsWithPrefix:@"custom-" keysAndValues:
		 @"my-key", @"my-value",
		 @"my-other-key", nil,
		 @"my-other-other-key", @"my-other-value",
		 nil];

		assertThatInteger([data count], equalToInt(2));
		assertThat([data URLsafeString], is(@"custom-my-key=my-value&custom-my-other-other-key=my-other-value"));
	});
});
SpecEnd
