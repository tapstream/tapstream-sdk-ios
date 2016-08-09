//  Copyright © 2016 Tapstream. All rights reserved.

#import "TSResponse.h"

@implementation TSResponse

@synthesize status = status;
@synthesize message = message;
@synthesize data = data;

+ (instancetype)responseWithStatus:(int)status message:(NSString *)message data:(NSData *)data
{
	return [[self alloc] initWithStatus:status message:message data:data];
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
