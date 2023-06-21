//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSTimelineApiResponse.h"

@interface TSTimelineApiResponse()
@property(readwrite, strong)NSArray* hits;
@property(readwrite, strong)NSArray* events;
@property(readwrite, strong)NSError* error;
@end

@implementation TSTimelineApiResponse
@synthesize error;
+ (instancetype)timelineApiResponseWithResponse:(TSResponse*)response
{
	TSMaybeError<NSDictionary*>* result = [TSResponse parseJSONResponse:response];
	if([result failed])
	{
		return [[self alloc] initWithError:[result error]];
	}

	NSDictionary* jsonDict = [result get];


	NSArray *hits = [jsonDict objectForKey:@"hits"];
	NSArray *events = [jsonDict objectForKey:@"events"];

	return [[self alloc] initWithHits:hits events:events error:nil];
}

- (instancetype)initWithError:(NSError*)errorVal
{
	return [self initWithHits:nil events:nil error:errorVal];
}

- (instancetype)initWithHits:(NSArray*)hits events:(NSArray*)events error:(NSError*)errorVal
{
	if((self = [self init]) != nil)
	{
		self.hits = hits;
		self.events = events;
		self.error = errorVal;
	}
	return self;
}
- (bool)failed { return [self error] != nil; }

@end
