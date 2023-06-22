//  Copyright © 2023 Tapstream. All rights reserved.

#import "TSResponse.h"

@implementation TSResponse

@synthesize status = status;
@synthesize message = message;
@synthesize data = data;

+ (instancetype)responseWithStatus:(int)status message:(NSString *)message data:(NSData *)data
{
	return [[self alloc] initWithStatus:status message:message data:data];
}

+ (TSMaybeError<NSDictionary*>*)parseJSONResponse:(TSResponse*)response
{

	if([response failed])
	{
		return [TSMaybeError withError:[response error]];
	}

	if(response.data == nil)
	{
		return [TSMaybeError withError:[TSError errorWithCode:kTSInvalidResponse
													  message:@"Api response was nil."]];
	}

	// Double-check the data for an empty array
	NSString *jsonString = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\[\\s*\\]\\s*$" options:0 error:&error];

	unsigned long numMatches = [regex numberOfMatchesInString:jsonString options:NSMatchingAnchored range:NSMakeRange(0, [jsonString length])];

	if(error != nil)
	{
		return [TSMaybeError withError:error];
	}

	if(numMatches != 0)
	{
		return [TSMaybeError withError:[TSError errorWithCode:kTSInvalidResponse
														  message:@"Api response was empty."]];
	}

	NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:response.data
															 options:kNilOptions
															   error:&error];
	if(error != nil)
	{
		return [TSMaybeError withError:error];
	}
	if(!jsonDict)
	{
		return [TSMaybeError withError:[TSError errorWithCode:kTSInvalidResponse
														  message:@"Api response was empty."]];
	}

	return [TSMaybeError withObject:jsonDict];
}

- (instancetype)initWithStatus:(int)statusVal message:(NSString *)messageVal data:(NSData *)dataVal
{
	if((self = [super init]) != nil)
	{
		status = statusVal;
		message = messageVal;
		data = dataVal;
	}
	return self;
}

- (bool)failed
{
	return self.status < 200 || self.status >= 300;
}

- (bool)retryable
{
	return self.status < 0 || (self.status >= 500 && self.status < 600);
}

- (bool)succeeded
{
	return ![self failed];
}

- (NSError*)error
{
	if([self failed])
	{
		return [TSError errorWithCode:kTSInvalidResponse message:self.message];
	}
	return nil;
}




@end
