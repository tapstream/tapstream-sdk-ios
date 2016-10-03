//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSResponse.h"
#import "TSRequestData.h"


@protocol TSHttpClient<NSObject>
- (void)request:(NSURL *)url completion:(void(^)(TSResponse*))completion;
- (void)request:(NSURL *)url data:(TSRequestData *)data method:(NSString *)method timeout_ms:(int)timeout_ms tries:(int)tries completion:(void(^)(TSResponse*))completion;
- (void)request:(NSURL *)url data:(TSRequestData *)data method:(NSString *)method timeout_ms:(int)timeout_ms completion:(void(^)(TSResponse*))completion;
@end;
