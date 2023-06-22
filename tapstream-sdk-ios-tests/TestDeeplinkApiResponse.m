//  Copyright © 2023 Tapstream. All rights reserved.

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
	NSUInteger timestamp = [[NSDate date] timeIntervalSince1970] * 1000;

	it(@"it fails on empty response", ^{
		TSResponse* resp = responseWithJSONString(@"");
		TSTimelineSummaryResponse* r = [TSTimelineSummaryResponse timelineSummaryResponseWithResponse:resp];
		assertThatBool([r failed], isTrue());
	});

	it(@"it does its best on partial response", ^{
		TSResponse* resp = responseWithJSONString(@"{\"latest_deeplink\":\"somthing\"}");
		TSTimelineSummaryResponse* r = [TSTimelineSummaryResponse timelineSummaryResponseWithResponse:resp];
		assertThatBool([r failed], isFalse());
		assertThatLong([r latestDeeplinkTimestamp], equalToLong(0));
		assertThat([r latestDeeplink], is(@"somthing"));
		assertThat([r deeplinks], nilValue());
		assertThat([r campaigns], nilValue());
		assertThat([r hitParams], nilValue());
		assertThat([r eventParams], nilValue());
	});

	it(@"no longer stores NSNull values", ^{
		TSResponse* resp = responseWithJSONString(@"{\"latest_deeplink\": null, \"deeplinks\": null, \"campaigns\": null, \"hit_params\": null, \"event_params\": null}");
		TSTimelineSummaryResponse* r = [TSTimelineSummaryResponse timelineSummaryResponseWithResponse:resp];
		assertThat([r latestDeeplink], nilValue());
		assertThat([r deeplinks], nilValue());
		assertThat([r campaigns], nilValue());
		assertThat([r hitParams], nilValue());
		assertThat([r eventParams], nilValue());
	});

	it(@"parses the sample response", ^{

		NSString* jsonString = [NSString stringWithFormat:@"{\"deeplinks\": %@,\"hit_params\":%@,\"event_params\":%@,\"campaigns\":%@,\"latest_deeplink\":\"%@\",\"latest_deeplink_timestamp\":%lu}",
								deeplinks,
								params,
								params,
								campaigns,
								expectedDeeplink,
								(unsigned long)timestamp
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

		assertThatLong([r latestDeeplinkTimestamp], equalToLong(timestamp));
	});
});
SpecEnd
