//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

#import "TSOfferApiResponse.h"

@interface TSOfferApiResponse()
@property (strong, readwrite) TSOffer* offer;
@property (strong, readwrite) TSResponse* response;
@property (strong, readwrite) NSError* error;
@end


@implementation TSOfferApiResponse
@synthesize error, offer, response;
+ (instancetype)offerApiResponseWithResponse:(TSResponse*)response sessionId:(NSString*)uuid
{
	NSError* error;

	if([response failed])
	{
		return [[self alloc] initWithResponse:response offer:nil error:[response error]];
	}

	if(response.data == nil)
	{
		error = [TSError errorWithCode:kTSInvalidResponse message:@"Offer endpoint returned a nil response"];
		return [[self alloc] initWithResponse:response offer:nil error:error];
	}

	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:response.data options:0 error:&error];
	if(error != nil)
	{
		return [[self alloc] initWithResponse:response offer:nil error:error];
	}
	if(json == nil) {
		error = [TSError errorWithCode:kTSInvalidResponse message:@"Offer endpoint returned invalid JSON"];
		return [[self alloc] initWithResponse:response offer:nil error:error];
	}

	TSOffer* offer = [TSOffer offerWithDescription:json uuid:uuid];

	return [[self alloc] initWithResponse:response offer:offer error:nil];
}
+ (instancetype)offerApiResponseWithOffer:(TSOffer*)offer
{
	TSResponse* mockedResponse = [TSResponse responseWithStatus:200 message:@"Stub response for cached offer" data:nil];
	return [[self alloc] initWithResponse:mockedResponse offer:offer error:nil];
}

- (instancetype)initWithResponse:(TSResponse*)responseVal offer:(TSOffer*)offerVal error:(NSError*)errorVal
{
	if((self = [self init]) != nil)
	{
		self.response = responseVal;
		self.offer = offerVal;
		self.error = errorVal;
	}
	return self;
}

- (bool)failed { return error != nil; }
@end
