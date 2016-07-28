//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSDefaultHttpClient_h
#define TSDefaultHttpClient_h
#import "TSConfig.h"
#import "TSHttpClient.h"

@interface TSDefaultHttpClient:NSObject<TSHttpClient>
@property(readonly, strong)TSConfig* config;
@property(readonly, strong)NSURLSession* session;

+ httpClientWithConfig:(TSConfig*)config;
@end

#endif /* TSDefaultHttpClient_h */
