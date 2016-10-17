//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSError.h"

@implementation TSError

+(NSError*)errorWithCode:(TSErrorCode)code message:(NSString*)message
{

	return [NSError errorWithDomain:kTSErrorDomain
						code:code
						userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, @"message", nil]];
}
+(NSError*)errorWithCode:(TSErrorCode)code message:(NSString*)message info:(NSDictionary*)userInfo
{
	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:userInfo];
	[info setObject:message forKey:@"message"];
	return [NSError errorWithDomain:kTSErrorDomain
							   code:code
						   userInfo:info];
}

+(NSString*)messageForError:(NSError*)error
{
	NSString* message = [[error userInfo] objectForKey:@"NSDebugDescription"];
	if(message != nil){
		return message;
	}
	return [[error userInfo] objectForKey:@"message"];
}


@end