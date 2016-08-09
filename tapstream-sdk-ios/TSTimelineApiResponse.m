//  Copyright © 2016 Tapstream. All rights reserved.

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


	if([response failed])
	{
		return [[self alloc] initWithError:[response error]];
	}
	
	if(response.data == nil)
	{
		return [[self alloc] initWithError:[TSError errorWithCode:kTSInvalidResponse
														  message:@"Timeline api response was nil."]];
	}

	// Double-check the data for an empty array
	NSString *jsonString = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\[\\s*\\]\\s*$" options:0 error:&error];

	unsigned long numMatches = [regex numberOfMatchesInString:jsonString options:NSMatchingAnchored range:NSMakeRange(0, [jsonString length])];
	
	if(error != nil)
	{
		return [[self alloc] initWithError:error];
	}

	if(numMatches != 0)
	{
		return [[self alloc] initWithError:[TSError errorWithCode:kTSInvalidResponse
														  message:@"Timeline api response was empty."]];
	}

	error = nil;
	NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:response.data
															 options:kNilOptions
															   error:&error];
	if(error != nil)
	{
		return [[self alloc] initWithError:error];
	}

	if(!jsonDict)
	{
		return [[self alloc] initWithError:[TSError errorWithCode:kTSInvalidResponse
														  message:@"Timeline api response was empty."]];
	}

	NSArray *hits = [jsonDict objectForKey:@"hits"];
	NSArray *events = [jsonDict objectForKey:@"events"];

	NSLog(@"Hits: %@", hits);
	NSLog(@"Events: %@", events);
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
