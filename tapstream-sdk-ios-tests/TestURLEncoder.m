//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSURLEncoder.h"

SpecBegin(URLEncoder)
describe(@"URLEncoder", ^{
	it(@"Encodes query string components", ^{
		NSString* encoded = [TSURLEncoder encodeStringForQuery:@"asdf&/xyz"];
		assertThat(encoded, is(@"asdf%26/xyz"));
	});
	it(@"Encodes path components", ^{
		NSString* encoded = [TSURLEncoder encodeStringForPath:@"asdf&/xyz"];
		assertThat(encoded, is(@"asdf&%2Fxyz"));
	});
});
SpecEnd
