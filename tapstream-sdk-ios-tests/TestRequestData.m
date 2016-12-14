//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSRequestData.h"

void populateRequestData(TSRequestData* data, int n){
	for(int ii = 0; ii < n; ii++){
		[data appendItemsWithPrefix:@"" keysAndValues:
		 [NSString stringWithFormat:@"key-%0d", ii],
		 [NSString stringWithFormat:@"val-%0d", ii],
		 nil];
	}
}

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
	
	it(@"Can tolerate asynchronous changes", ^{
		TSRequestData* data = [TSRequestData requestData];

		dispatch_queue_t q = dispatch_queue_create("testq", DISPATCH_QUEUE_CONCURRENT);

		dispatch_async(q, ^{
			for(int jj=0; jj<10000; jj++){
				[data URLsafeString];

			}
		});

		populateRequestData(data, 100000);

	});

	it(@"Won't deadlock in an item-copying loop", ^{
		TSRequestData* data1 = [TSRequestData requestData];
		TSRequestData* data2 = [TSRequestData requestData];

		populateRequestData(data1, 10000);
		populateRequestData(data2, 10000);

		dispatch_queue_t q = dispatch_queue_create("testq", DISPATCH_QUEUE_CONCURRENT);
		for(int ii = 0; ii < 100; ii++){
			dispatch_async(q, ^{
				[data1 appendItemsFromRequestData:data2];
			});
			dispatch_async(q, ^{
				[data2 appendItemsFromRequestData:data1];
			});
		}
	});
});
SpecEnd
