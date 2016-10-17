//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSTimelineSummaryResponse.h"

TSResponse* responseWithJSONString(NSString* jsonStr)
{
	NSData* data =  [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
	return [TSResponse responseWithStatus:200 message:@"" data:data];
}

SpecBegin(TimelineSummaryResponse)

describe(@"TimelineSummaryResponse", ^{
	NSString* expectedDeeplink = @"testapp://somepath";
	NSString* params = @"{\"testkey\":\"testval\",\"testkey2\":\"testval2\"}";
	NSString* campaigns = @"[\"testcampaign1\",\"testcampaign2\"]";
	NSString* deeplinks = @"[\"testapp://someotherpath\",\"testapp://somepath\"]";

	it(@"it fails on empty response", ^{
		TSResponse* resp = responseWithJSONString(@"");
		TSTimelineSummaryResponse* r = [TSTimelineSummaryResponse timelineSummaryResponseWithResponse:resp];
		assertThatBool([r failed], isTrue());
	});

	it(@"parses the sample response", ^{

		NSString* jsonString = [NSString stringWithFormat:@"{\"deeplinks\": %@,\"hitParams\":%@,\"eventParams\":%@,\"campaigns\":%@,\"latestDeeplink\":\"%@\"}",
								deeplinks,
								params,
								params,
								campaigns,
								expectedDeeplink
								];

		TSResponse* resp = responseWithJSONString(jsonString);
		TSTimelineSummaryResponse* r = [TSTimelineSummaryResponse timelineSummaryResponseWithResponse:resp];
		NSLog(@"%@", [TSError messageForError:[r error]]);
		assertThatBool([r failed], isFalse());

		assertThat([r latestDeeplink], is(expectedDeeplink));
		assertThat([r deeplinks], contains(@"testapp://someotherpath",
										   expectedDeeplink,
										   nil));
		assertThat([r campaigns], contains(@"testcampaign1", @"testcampaign2", nil));
		assertThat([r hitParams], hasEntries(@"testkey", @"testval",
											 @"testkey2", @"testval2",
											 nil));
		assertThat([r eventParams], hasEntries(@"testkey", @"testval",
											   @"testkey2", @"testval2",
											   nil));
	});
});
SpecEnd
