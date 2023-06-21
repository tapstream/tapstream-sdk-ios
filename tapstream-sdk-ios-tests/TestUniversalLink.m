//  Copyright © 2023 Tapstream. All rights reserved.

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import "TSUniversalLinkApiResponse.h"
#import "TSError.h"

SpecBegin(UniversalLinkInit)

describe(@"UniversalLinkInit", ^{

	it(@"Handles an invalid status code", ^{
		TSResponse* r = [TSResponse responseWithStatus:-1 message:nil data:nil];
		TSUniversalLinkApiResponse* ul = [TSUniversalLinkApiResponse universalLinkApiResponseWithResponse:r];

		XCTAssertEqual(ul.status, kTSULUnknown);
		XCTAssert(ul.error != nil);
		XCTAssertEqual(ul.error.code, kTSIOError);
	});

	it(@"Handles a nil 200 response", ^{
		TSResponse* r = [TSResponse responseWithStatus:200 message:nil data:nil];
		TSUniversalLinkApiResponse* ul = [TSUniversalLinkApiResponse universalLinkApiResponseWithResponse:r];

		XCTAssertEqual(ul.status, kTSULUnknown);
		XCTAssert(ul.error != nil);
		XCTAssertEqual(ul.error.code, kTSIOError);
	});

	it(@"Handles invalid JSON", ^{

		TSResponse* r = [TSResponse responseWithStatus:200 message:nil data:[NSKeyedArchiver archivedDataWithRootObject:@""]];
		TSUniversalLinkApiResponse* ul = [TSUniversalLinkApiResponse universalLinkApiResponseWithResponse:r];

		XCTAssertEqual(ul.status, kTSULUnknown);
		XCTAssert(ul.error != nil);
		XCTAssertEqual(ul.error.code, kTSInvalidResponse);
		XCTAssert([ul.error.userInfo valueForKey:@"message"], @"Invalid JSON response");
		XCTAssert([ul.error.userInfo valueForKey:@"cause"] != nil);
	});

	it(@"Handles a blank JSON response", ^{

		TSResponse* r = [TSResponse responseWithStatus:200 message:nil data:[NSKeyedArchiver archivedDataWithRootObject:@""]];
		TSUniversalLinkApiResponse* ul = [TSUniversalLinkApiResponse universalLinkApiResponseWithResponse:r];

		XCTAssertEqual(ul.status, kTSULUnknown);
		XCTAssert(ul.error != nil);
		XCTAssertEqual(ul.error.code, kTSInvalidResponse);
		XCTAssert([ul.error.userInfo valueForKey:@"message"], @"Invalid JSON response");
		XCTAssert([ul.error.userInfo valueForKey:@"cause"] != nil);
	});

	it(@"Handles an invalid JSON response", ^{

		TSResponse* r = [TSResponse responseWithStatus:200 message:nil data:[NSKeyedArchiver archivedDataWithRootObject:@"{]}"]];
		TSUniversalLinkApiResponse* ul = [TSUniversalLinkApiResponse universalLinkApiResponseWithResponse:r];

		XCTAssertEqual(ul.status, kTSULUnknown);
		XCTAssert(ul.error != nil);
		XCTAssertEqual(ul.error.code, kTSInvalidResponse);
	});


});
SpecEnd
