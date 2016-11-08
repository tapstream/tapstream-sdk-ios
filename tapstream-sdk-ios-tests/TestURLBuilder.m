//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSConfig.h"
#import "TSURLBuilder.h"


SpecBegin(URLBuilder)

describe(@"URLBuilder", ^{

	__block TSConfig* config;
	__block NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:@"val&1", @"k 1", @"val2", @"k2", nil];
	__block NSString* accountName = @"testapp";
	__block NSString* sdkSecret = @"mysdksecret1234567890";

	beforeEach(^{
		config = [TSConfig configWithAccountName:accountName sdkSecret:sdkSecret];
		config.globalEventParams = [params mutableCopy];
	});


	describe(@"urlwithparameters", ^{
		it(@"functions with no arguments", ^{
			NSURL* url = [TSURLBuilder urlWithParameters:@"http://myurl.com/mypath"
									   globalEventParams:nil
													data:nil, nil];

			assertThat([url absoluteString], is(@"http://myurl.com/mypath?"));
		});

		it(@"correctly renders global event params", ^{
			NSURL* url = [TSURLBuilder urlWithParameters:@"http://myurl.com/mypath"
									   globalEventParams:params
													data:nil, nil];
			assertThat([url path], is(@"/mypath"));
			assertThat([url host], is(@"myurl.com"));
			NSArray* items = [[NSURLComponents componentsWithString:[url absoluteString]] queryItems];
			for(NSURLQueryItem* item in items)
			{
				NSString* key = [item name];
				NSString* val = [item value];
				NSLog(@"%@, %@", key, val);
			}
			assertThat(items,
					   containsInAnyOrder(
						  [NSURLQueryItem queryItemWithName:@"custom-k 1" value:@"val&1"],
						  [NSURLQueryItem queryItemWithName:@"custom-k2" value:@"val2"],
						  nil
					   ));

		});
		it(@"correctly renders extra data", ^{
			TSRequestData* data = [TSRequestData new];
			[data appendItemsWithPrefix:@"" keysAndValues:
			 @"my&item", @"my&value",
			 nil];

			NSURL* url = [TSURLBuilder urlWithParameters:@"http://myurl.com/mypath"
									   globalEventParams:nil
													data:data, nil];
			assertThat([url absoluteString],
					   is(@"http://myurl.com/mypath?my%26item=my%26value"));
		});

		it(@"correctly renders varargs", ^{
			NSURL* url = [TSURLBuilder urlWithParameters:@"http://myurl.com/mypath"
									   globalEventParams:nil
													data:nil,
						  @"my&key1", @"my&val1",
						  nil];


			assertThat([url absoluteString],
					   is(@"http://myurl.com/mypath?my%26key1=my%26val1"));
		});
	});

	describe(@"makecookiematchurl", ^{
		it(@"correctly renders a cookie match url", ^{

			NSURL* url = [TSURLBuilder makeCookieMatchURL:config eventName:@"my/Event" data:nil];
			NSURLComponents* components = [NSURLComponents componentsWithString:[url absoluteString]];
			assertThat([components percentEncodedPath], is(@"/testapp/event/my%2FEvent/"));
			assertThat([components host], is(@"api.taps.io"));
			assertThat([components queryItems],
					   containsInAnyOrder(
										  [NSURLQueryItem queryItemWithName:@"custom-k 1" value:@"val&1"],
										  [NSURLQueryItem queryItemWithName:@"custom-k2" value:@"val2"],
										  [NSURLQueryItem queryItemWithName:@"cookiematch" value:@"true"],
										  nil
										  ));

		});
	});

	describe(@"makeEventURL", ^{
		it(@"correctly renders and event url", ^{
			NSURL* url = [TSURLBuilder makeEventURL:config eventName:@"myEvent"];


			assertThat([url path], is(@"/testapp/event/myEvent"));
			assertThat([url host], is(@"api.tapstream.com"));
		});
		it(@"escapes the event name", ^{
			NSURL* url = [TSURLBuilder makeEventURL:config eventName:@"my/Event"];
			NSURLComponents* components = [NSURLComponents componentsWithString:[url absoluteString]];
			assertThat([components percentEncodedPath], is(@"/testapp/event/my%2FEvent/"));
		});
	});


	describe(@"makeConversionUrl", ^{
		it(@"correctly renders a conversion url", ^{
			NSString* sessionId = @"my-session-id";

			NSURL* url = [TSURLBuilder makeConversionURL:config sessionId:sessionId];

			assertThat([url path], is(@"/v1/timelines/lookup"));
			assertThat([url host], is(@"reporting.tapstream.com"));
			assertThat([url scheme], is(@"https"));

			assertThat([[NSURLComponents componentsWithString:[url absoluteString]] queryItems],
					   containsInAnyOrder(
										  [NSURLQueryItem queryItemWithName:@"secret" value:sdkSecret],
										  [NSURLQueryItem queryItemWithName:@"event_session" value:sessionId],
										  [NSURLQueryItem queryItemWithName:@"blocking" value:@"true"],
										  nil
										  ));
		});
	});
	describe(@"makeTimelineSummaryUrl", ^{
		it(@"correctly renders a timeline summary url url", ^{
			NSString* sessionId = @"my-session-id";

			NSURL* url = [TSURLBuilder makeTimelineSummaryURL:config sessionId:sessionId];

			assertThat([url path], is(@"/v1/timelines/summary"));
			assertThat([url host], is(@"reporting.tapstream.com"));
			assertThat([url scheme], is(@"https"));

			assertThat([[NSURLComponents componentsWithString:[url absoluteString]] queryItems],
					   containsInAnyOrder(
										  [NSURLQueryItem queryItemWithName:@"secret" value:sdkSecret],
										  [NSURLQueryItem queryItemWithName:@"event_session" value:sessionId],
										  [NSURLQueryItem queryItemWithName:@"blocking" value:@"true"],
										  nil
										  ));
		});
	});

	describe(@"makeOfferUrl", ^{
		it(@"correctly renders an offer url", ^{
			NSURL* url = [TSURLBuilder makeOfferURL:config bundle:@"my&bundle" insertionPoint:@"my&insertionpoint"];
			assertThat([[NSURLComponents componentsWithString:[url absoluteString]] queryItems],
					   containsInAnyOrder(
										  [NSURLQueryItem queryItemWithName:@"secret" value:sdkSecret],
										  [NSURLQueryItem queryItemWithName:@"bundle" value:@"my&bundle"],
										  [NSURLQueryItem queryItemWithName:@"insertion_point" value:@"my&insertionpoint"],
										  nil
										  ));

		});
	});

	describe(@"makeRewardUrl", ^{
		it(@"correctly renders a reward url", ^{
			NSURL* url = [TSURLBuilder makeRewardListURL:config sessionId:@"my&session"];
			assertThat([url absoluteString],
					   is(@"https://app.tapstream.com/api/v1/word-of-mouth/rewards/?event_session=my%26session&secret=mysdksecret1234567890"));

		});
	});

	describe(@"simulatedClickURL", ^{
		it(@"correctly renders a simulated click url", ^{

			NSURL* baseURL = [NSURL URLWithString:@"https://www.myapp.com/somepage"];
			NSURL* url = [TSURLBuilder makeSimulatedClickURLWithBaseURL:baseURL
																   idfa:@"my-idfa"
															  sessionId:@"my-session-id"];
			assertThat([[NSURLComponents componentsWithString:[url absoluteString]] queryItems],
					   containsInAnyOrder(
										  [NSURLQueryItem queryItemWithName:@"__tsul" value:@"my-session-id"],
										  [NSURLQueryItem queryItemWithName:@"__tshardware-ios-idfa" value:@"my-idfa"],
										  [NSURLQueryItem queryItemWithName:@"__tsredirect" value:@"0"],
										  nil
										  ));


		});
	});
});
SpecEnd
