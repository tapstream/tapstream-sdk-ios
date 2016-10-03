//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSDefaultHttpClient.h"



#ifndef kTSDefaultTimeout
#define kTSDefaultTimeout 10000
#endif

@interface TSDefaultHttpClient()
@property(readwrite, strong)TSConfig* config;
@property(readwrite, strong)NSURLSession* session;
@end

@implementation TSDefaultHttpClient
+ (instancetype)httpClientWithConfig:(TSConfig*)config
{
	return [[self alloc] initWithConfig:config];
}

- (instancetype)initWithConfig:(TSConfig*)config
{
	if((self = [self init]) != nil)
	{
		self.config = config;
		NSURLSessionConfiguration* conf = [NSURLSessionConfiguration ephemeralSessionConfiguration];
		[conf setDiscretionary:false];

		self.session = [NSURLSession sessionWithConfiguration:conf];
	}
	return self;
}

- (void)request:(NSURL *)url completion:(void(^)(TSResponse*))completion
{
	[self request:url data:nil method:@"GET" timeout_ms:kTSDefaultTimeout completion:completion];
}

- (void)request:(NSURL *)url data:(TSRequestData *)data method:(NSString *)method timeout_ms:(int)timeout_ms completion:(void(^)(TSResponse*))completion
{
	[self request:url data:data method:method timeout_ms:timeout_ms tries:1 completion:completion];
}

- (void)request:(NSURL *)url data:(TSRequestData *)data method:(NSString *)method timeout_ms:(int)timeout_ms tries:(int)tries completion:(void(^)(TSResponse*))completion
{

	NSString* postBody = nil;
	if(data != nil)
	{
		postBody = [data URLsafeString];
	}

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPMethod:method];
	[request setTimeoutInterval:timeout_ms / 1000.];

	NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable urlResponse, NSError * _Nullable error) {

		NSHTTPURLResponse* response = (NSHTTPURLResponse*) urlResponse;

		if(response.statusCode < 200 || (response.statusCode >= 500 && response.statusCode < 600))
		{
			// retryable
			if(tries > 1)
			{
				[self request:url data:data method:method timeout_ms:timeout_ms tries:(tries - 1) completion:completion];
				return;
			}
		}
		if(responseData == nil || !response)
		{
			if(error != nil)
			{
				NSString *msg = [NSString stringWithFormat:@"%@", error];
				completion([TSResponse responseWithStatus:-1 message:msg data:nil]);
			}
			completion([TSResponse responseWithStatus:-1 message:@"Unknown" data:nil]);
		}
		completion([TSResponse responseWithStatus:(int)response.statusCode message:[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode] data:responseData]);

	}];

	[dataTask resume];


}

@end
