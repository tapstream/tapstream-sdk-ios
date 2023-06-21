//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSError_h
#define TSError_h

#define kTSErrorDomain @"Tapstream"

typedef enum _TSErrorCode {
	kTSIOError = 0,
	kTSInvalidResponse
} TSErrorCode;



@interface TSError : NSObject
+(NSError*)errorWithCode:(TSErrorCode)code message:(NSString*)message;
+(NSError*)errorWithCode:(TSErrorCode)code message:(NSString*)message info:(NSDictionary*)userInfo;
+(NSString*)messageForError:(NSError*)error;
@end


#endif /* TSError_h */
