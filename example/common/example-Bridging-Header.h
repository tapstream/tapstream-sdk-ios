//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#import "TapstreamIOS.h"


// Patch the TSTapstream interface to access some internals
@interface TSTapstream()
@property(nonatomic, strong) id<TSHttpClient> httpClient;
@property(nonatomic, strong) TSConfig *config;
@end