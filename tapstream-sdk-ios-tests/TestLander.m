//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import <OCMock/OCMock.h>
#import <Specta/Specta.h>
#import <Foundation/Foundation.h>
#import "TSPlatform.h"
//#import "TSLanderStrategy.h"
#import "TSDefaultLanderStrategy.h"
#import "TSTestPersistentStorage.h"


SpecBegin(Lander)

describe(@"Lander", ^{

	it(@"Is invalid given a nil description", ^{
		TSLander* lander = [TSLander landerWithDescription:nil];
		XCTAssertFalse([lander isValid]);
	});

	it(@"Is invalid given an empty description", ^{
		NSString* jsonStr = @"{}";
		NSDictionary* data = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
															 options:1
															   error:nil];
		TSLander* lander = [TSLander landerWithDescription:data];
		XCTAssertFalse([lander isValid]);
	});

	it(@"is invalid given a Null url", ^{
		NSString* jsonStr = @"{\"url\": null}";
		NSDictionary* data = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
															 options:1
															   error:nil];
		TSLander* lander = [TSLander landerWithDescription:data];
		XCTAssertFalse([lander isValid]);
	});

	it(@"is invalid given null data", ^{
		NSString* jsonStr = @"{\"url\": null, \"markup\": null, \"id\": null}";
		NSDictionary* data = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
															 options:1
															   error:nil];
		TSLander* lander = [TSLander landerWithDescription:data];
		XCTAssertFalse([lander isValid]);
	});

	it(@"is invalid given an invalid url", ^{
		NSString* jsonStr = @"{\"url\": \"www.myspace.com\", \"markup\": null, \"id\": 31}";
		NSDictionary* data = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
															 options:1
															   error:nil];
		TSLander* lander = [TSLander landerWithDescription:data];
		XCTAssertFalse([lander isValid]);
	});


	it(@"Is valid given a valid url and id and nil markup", ^{
		NSString* jsonStr = @"{\"url\": \"https://www.myspace.com\", \"markup\": null, \"id\": 31}";
		NSDictionary* data = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
															options:1
															   error:nil];
		TSLander* lander = [TSLander landerWithDescription:data];
		XCTAssertTrue([lander isValid]);
	});

	it(@"Is valid given a wholly valid description", ^{
		NSString* jsonStr = @"{\"url\": null, \"markup\": \"<h1>Ok</h1>\", \"id\": 31}";
		NSDictionary* data = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
															 options:1
															   error:nil];
		TSLander* lander = [TSLander landerWithDescription:data];
		XCTAssertTrue([lander isValid]);
	});
});
SpecEnd
