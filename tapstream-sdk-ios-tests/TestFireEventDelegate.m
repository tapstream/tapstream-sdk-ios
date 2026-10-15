//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>

#import "TSAppEventSource.h"
#import "TSFireEventDelegate.h"
#import "TSTestUtils.h"
#import "TSDefs.h"
#import "TSDefaultHttpClient.h"

@interface TSEvent()
- (void)prepare:(NSDictionary*)globalEventParams;
@end

@interface TSDefaultHttpClient()
@property(readwrite, strong)NSURLSession* session;
@end

// Fails the first `timeoutsRemaining` requests with NSURLErrorTimedOut (the same
// error NSURLSession reports for a real timeout), then answers 200.
static int timeoutsRemaining = 0;
static int requestCount = 0;
static BOOL respondWithEmptyBody = NO;

@interface TSTimeoutURLProtocol : NSURLProtocol
@end

@implementation TSTimeoutURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request { return YES; }
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request { return request; }
- (void)startLoading
{
	BOOL timeout;
	@synchronized([TSTimeoutURLProtocol class])
	{
		requestCount += 1;
		timeout = timeoutsRemaining > 0;
		if(timeout)
		{
			timeoutsRemaining -= 1;
		}
	}

	if(timeout)
	{
		NSError* error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
		[self.client URLProtocol:self didFailWithError:error];
		return;
	}

	NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
	[self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	if(!respondWithEmptyBody)
	{
		[self.client URLProtocol:self didLoadData:[@"{}" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	[self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end

// Implements only the required TSFireEventStrategy methods, like a strategy
// written before shouldRetryEvent: existed.
@interface TSRequiredOnlyFireEventStrategy : NSObject<TSFireEventStrategy>
@end

@implementation TSRequiredOnlyFireEventStrategy
- (BOOL)shouldFireEvent:(TSEvent*)event { return YES; }
- (int)getDelay { return 0; }
- (void)registerFiringEvent:(TSEvent*)e {}
- (void)registerResponse:(TSResponse*)response forEvent:(TSEvent*)e {}
@end

static TSDefaultHttpClient* timeoutStubbedHttpClient(TSConfig* config)
{
	TSDefaultHttpClient* client = [TSDefaultHttpClient httpClientWithConfig:config];
	NSURLSessionConfiguration* conf = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	conf.protocolClasses = @[[TSTimeoutURLProtocol class]];
	client.session = [NSURLSession sessionWithConfiguration:conf];
	return client;
}

SpecBegin(FireEventDelegate)

describe(@"FireEventDelegate", ^{
	__block TSConfig* config;
	__block dispatch_queue_t queue;
	__block id<TSPlatform> platform;
	__block id<TSHttpClient> httpClient;
	__block TSDefaultFireEventDelegate* fireEventDelegate;
	__block id<TSCoreListener> listener;
	__block id<TSFireEventStrategy> fireEventStrategy;


	beforeEach(^{
		platform = OCMProtocolMock(@protocol(TSPlatform));
		listener = OCMProtocolMock(@protocol(TSCoreListener));
		queue = dispatch_queue_create("testq", DISPATCH_QUEUE_SERIAL);

		fireEventStrategy = OCMProtocolMock(@protocol(TSFireEventStrategy));

		httpClient = OCMProtocolMock(@protocol(TSHttpClient));
		config = [TSConfig configWithAccountName:@"testAccount" sdkSecret:@"sdkSecret"];
		OCMStub([platform getAppName]).andReturn(@"testapp");
		OCMStub([platform getPlatformName]).andReturn(kTSPlatform);

		fireEventDelegate = [TSDefaultFireEventDelegate defaultFireEventDelegateWithConfig:config
																					 queue:queue
																				  platform:platform
																		 fireEventStrategy:fireEventStrategy
																				httpClient:httpClient
																				  listener:listener];
	});

	it(@"Will not fire an event if shouldFireEvent returns false", ^{
		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(false);
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];

		OCMReject([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]);
		[fireEventDelegate fireEvent:event];
		block_until_queue_completed(queue);
	});

	it(@"Calls prepare on the event when it is fired", ^{
		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(false);
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
        assertThat(@(event.isPrepared), isFalse());
        [fireEventDelegate fireEvent:event];
        assertThat(@(event.isPrepared), isTrue());
	});

	it(@"Will only retry retryable fire event responses", ^{
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* errorResponse = [TSResponse responseWithStatus:500 message:@"Error" data:nil];
		TSResponse* badRequestResponse = [TSResponse responseWithStatus:400 message:@"Error" data:nil];
		TSResponse* okResponse = [TSResponse responseWithStatus:200 message:@"OK" data:nil];

		__block int firedCount = 0;

		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
		OCMStub([fireEventStrategy shouldRetryEvent:[OCMArg any]]).andReturn(true);
		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]).andDo(^(NSInvocation *invocation){
			[invocation retainArguments];
			void (^completion)(TSResponse*) = nil;
			[invocation getArgument:&completion atIndex:6];
			firedCount += 1;
			if(firedCount == 1)
			{
				completion(errorResponse);
			}
			else if(firedCount == 2)
			{
				completion(badRequestResponse);
			}
			else
			{
				completion(okResponse);
			}

		});

		OCMReject([fireEventStrategy registerResponse:okResponse forEvent:event]);

		[fireEventDelegate fireEvent:event];
		block_until_queue_completed(queue);

		assertThatInteger(firedCount, equalToInteger(2));
		OCMVerify([fireEventStrategy registerFiringEvent:event]);
		OCMVerify([fireEventStrategy registerResponse:errorResponse forEvent:event]);
		OCMVerify([fireEventStrategy registerResponse:badRequestResponse forEvent:event]);
	});

	it(@"Retries retryable responses when the strategy does not implement shouldRetryEvent", ^{
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* errorResponse = [TSResponse responseWithStatus:500 message:@"Error" data:nil];
		TSResponse* okResponse = [TSResponse responseWithStatus:200 message:@"OK" data:nil];

		__block int firedCount = 0;

		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]).andDo(^(NSInvocation *invocation){
			[invocation retainArguments];
			void (^completion)(TSResponse*) = nil;
			[invocation getArgument:&completion atIndex:6];
			firedCount += 1;
			completion(firedCount == 1 ? errorResponse : okResponse);
		});

		TSDefaultFireEventDelegate* delegate = [TSDefaultFireEventDelegate defaultFireEventDelegateWithConfig:config
																									   queue:queue
																									platform:platform
																						   fireEventStrategy:[[TSRequiredOnlyFireEventStrategy alloc] init]
																								  httpClient:httpClient
																									listener:listener];
		[delegate fireEvent:event];
		block_until_queue_completed(queue);

		assertThatInteger(firedCount, equalToInteger(2));
	});

	it(@"Will not retry a retryable response once the strategy stops allowing retries", ^{
		TSEvent* event = [TSEvent eventWithName:@"myevent" oneTimeOnly:false];
		TSResponse* errorResponse = [TSResponse responseWithStatus:500 message:@"Error" data:nil];

		__block int firedCount = 0;

		OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
		OCMStub([fireEventStrategy shouldRetryEvent:[OCMArg any]]).andReturn(false);
		OCMStub([httpClient request:[OCMArg any] data:[OCMArg any] method:@"POST" timeout_ms:10000 completion:[OCMArg any]]).andDo(^(NSInvocation *invocation){
			[invocation retainArguments];
			void (^completion)(TSResponse*) = nil;
			[invocation getArgument:&completion atIndex:6];
			firedCount += 1;
			completion(errorResponse);
		});

		[fireEventDelegate fireEvent:event];
		block_until_queue_completed(queue);

		assertThatInteger(firedCount, equalToInteger(1));
		OCMVerify([fireEventStrategy shouldRetryEvent:event]);
		OCMVerify([listener reportOperation:@"event-retries-exhausted" arg:event.encodedName]);
	});

	describe(@"on request timeouts", ^{
		beforeEach(^{
			@synchronized([TSTimeoutURLProtocol class])
			{
				timeoutsRemaining = 0;
				requestCount = 0;
				respondWithEmptyBody = NO;
			}
		});

		it(@"HTTP client invokes the completion exactly once for a timed out request", ^{
			@synchronized([TSTimeoutURLProtocol class])
			{
				timeoutsRemaining = 1;
			}
			TSDefaultHttpClient* client = timeoutStubbedHttpClient(config);

			__block int completionCount = 0;
			NSMutableArray<TSResponse*>* responses = [NSMutableArray array];
			[client request:[NSURL URLWithString:@"https://api.tapstream.com/test"] data:nil method:@"POST" timeout_ms:kTSDefaultTimeout completion:^(TSResponse* response){
				@synchronized(responses)
				{
					completionCount += 1;
					[responses addObject:response];
				}
			}];

			[NSThread sleepForTimeInterval:1.0];

			assertThatInteger(completionCount, equalToInteger(1));
			assertThatInteger(responses.firstObject.status, equalToInteger(-1));
			assertThat(@([responses.firstObject retryable]), isTrue());
		});

		it(@"HTTP client reports a success with an empty body as a success, once", ^{
			@synchronized([TSTimeoutURLProtocol class])
			{
				respondWithEmptyBody = YES;
			}
			TSDefaultHttpClient* client = timeoutStubbedHttpClient(config);

			NSMutableArray<TSResponse*>* responses = [NSMutableArray array];
			[client request:[NSURL URLWithString:@"https://api.tapstream.com/test"] data:nil method:@"POST" timeout_ms:kTSDefaultTimeout completion:^(TSResponse* response){
				@synchronized(responses)
				{
					[responses addObject:response];
				}
			}];

			[NSThread sleepForTimeInterval:1.0];

			assertThatInteger(responses.count, equalToInteger(1));
			assertThatInteger(responses.firstObject.status, equalToInteger(200));
			assertThat(@([responses.firstObject succeeded]), isTrue());
		});

		it(@"Retries a timed out event once per timeout instead of fanning out", ^{
			// Three consecutive timeouts followed by success should be exactly 4 requests.
			// With duplicated completions each timeout spawns 2 retries: 1 + 2 + 4 = 7 requests.
			@synchronized([TSTimeoutURLProtocol class])
			{
				timeoutsRemaining = 3;
			}
			OCMStub([fireEventStrategy shouldFireEvent:[OCMArg any]]).andReturn(true);
			OCMStub([fireEventStrategy shouldRetryEvent:[OCMArg any]]).andReturn(true);
			OCMStub([fireEventStrategy getDelay]).andReturn(0);

			TSDefaultFireEventDelegate* delegate = [TSDefaultFireEventDelegate defaultFireEventDelegateWithConfig:config
																									   queue:queue
																									platform:platform
																						   fireEventStrategy:fireEventStrategy
																								  httpClient:timeoutStubbedHttpClient(config)
																									listener:listener];

			[delegate fireEvent:[TSEvent eventWithName:@"myevent" oneTimeOnly:false]];

			[NSThread sleepForTimeInterval:1.5];
			block_until_queue_completed(queue);

			@synchronized([TSTimeoutURLProtocol class])
			{
				assertThatInteger(requestCount, equalToInteger(4));
			}
		});
	});
});

SpecEnd
