//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSTimelineApiResponse.h"

SpecBegin(TimelineApiResponse)
describe(@"TimelineApiResponse", ^{
	it(@"Will reject an empty JSON string", ^{
		NSString* jsonStr = @"";
		NSData* data =  [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:data];
		TSTimelineApiResponse* resp = [TSTimelineApiResponse timelineApiResponseWithResponse:response];

		assertThatBool([resp failed], isTrue());
	});

	it(@"Will reject an empty JSON array", ^{
		NSString* jsonStr = @"[]";
		NSData* data =  [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:data];
		TSTimelineApiResponse* resp = [TSTimelineApiResponse timelineApiResponseWithResponse:response];
		assertThatBool([resp failed], isTrue());
	});
	it(@"Will reject an invalid JSON input", ^{
		NSString* jsonStr = @"[{]";
		NSData* data =  [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:data];
		TSTimelineApiResponse* resp = [TSTimelineApiResponse timelineApiResponseWithResponse:response];
		assertThatBool([resp failed], isTrue());
	});


	it(@"Will accept a blank response", ^{
		NSString* jsonStr = @"{\"hits\":[], \"events\":[]}";
		NSData* data =  [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
		TSResponse* response = [TSResponse responseWithStatus:200 message:@"" data:data];
		TSTimelineApiResponse* resp = [TSTimelineApiResponse timelineApiResponseWithResponse:response];

		assertThatBool([resp failed], isFalse());

		assertThatInteger([[resp hits] count], equalToInteger(0));
		assertThatInteger([[resp events] count], equalToInteger(0));
	});
});
SpecEnd
