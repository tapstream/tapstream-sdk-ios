//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
#import "TSTestPersistentStorage.h"
#import "TSDefaultOfferStrategy.h"

@interface TSOffer()
@property(assign, nonatomic, readwrite) NSInteger minimumAge;
@property(assign, nonatomic, readwrite) NSInteger rateLimit;
@end


@interface TSDefaultOfferStrategy()
@property(assign, nonatomic, readwrite) NSDate* installDate;
@end


NSDictionary* offerDescription(int ident, NSString* bundle) {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			bundle, @"bundle",
			@"<html><p></p>MY_THING</html>", @"markup",
			[NSNumber numberWithInt:ident], @"id", nil];
}

SpecBegin(OfferStrategy)
describe(@"OfferStrategy", ^{
	__block id<TSPersistentStorage> storage;
	__block TSDefaultOfferStrategy* strategy;

	beforeEach(^{
		storage = [[TSTestPersistentStorage alloc] init];
		strategy = [TSDefaultOfferStrategy offerStrategyWithStorage:storage];
	});

	it(@"Returns nil for uncached offers", ^{
		assertThat([strategy cachedOffer:@"inspot" sessionId:@""], nilValue());
	});

	it(@"Will store offers between instantiations", ^{
		TSOffer* offer = [TSOffer offerWithDescription:offerDescription(26, @"mybundle") uuid:@"myuuid"];
		[strategy registerOfferRetrieved:offer forInsertionPoint:@"inspot"];

		strategy = [TSDefaultOfferStrategy offerStrategyWithStorage:storage];
		TSOffer* otherOffer = [strategy cachedOffer:@"inspot" sessionId:@"myuuid"];
		assertThatInteger(otherOffer.ident, equalToInteger(offer.ident));
		assertThat(otherOffer.description, is(offer.description));
		assertThat(otherOffer.markup, is(offer.markup));
	});


	it(@"Cannot show offers to users younger than minimumAge", ^{

		TSOffer* offer = [TSOffer offerWithDescription:offerDescription(26, @"mybundle") uuid:@"myuuid"];
		offer.minimumAge = 3600;  // Must be one hour old

		assertThatBool([strategy eligible:offer], isFalse());

		NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
		strategy.installDate = [NSDate dateWithTimeIntervalSince1970:(now - 3601)];

		assertThatBool([strategy eligible:offer], isTrue());

	});

	it(@"Cannot show the same offer more than rateLimit seconds apart", ^{
		TSOffer* offer = [TSOffer offerWithDescription:offerDescription(26, @"mybundle") uuid:@"myuuid"];

		// Cannot show offers more frequently than the rateLimit
		assertThatBool([strategy eligible:offer], isTrue());
		[strategy registerOfferShown:offer];

		// Can normally show back-to-back offers if rateLimit is 0 or nil
		assertThatBool([strategy eligible:offer], isTrue());

		offer.rateLimit = 60; // Do not show more than once per minute
		assertThatBool([strategy eligible:offer], isFalse());
	});
});
SpecEnd

/*
 - (bool)eligible:(TSOffer*)offer;
 - (TSOffer*)cachedOffer:(NSString*)insertionPoint;
 - (void)registerOfferRetrieved:(TSOffer *)offer forInsertionPoint:(NSString*)insertionPoint;
 - (void)registerOfferShown:(TSOffer *)offer;
*/
