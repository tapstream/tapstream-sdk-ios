//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSLanderDelegateWrapper_h
#define TSLanderDelegateWrapper_h

#import "TSLanderDelegate.h"

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TSLanderStrategy.h"

@interface TSLanderDelegateWrapper : NSObject<TSLanderDelegate>
@property(nonatomic, strong) id<TSLanderStrategy> strategy;
@property(nonatomic, strong) id<TSLanderDelegate> delegate;
@property(nonatomic, strong) UIWindow* window;
- initWithStrategyAndDelegateAndWindow:(id<TSLanderStrategy>)strategy
							  delegate:(id<TSLanderDelegate>)delegate
								window:(UIWindow*)window;
- (void)didFailLoadWithError:(NSError*)error;
@end
#else
@interface TSLanderDelegateWrapper : NSObject<TSLanderDelegate>
@end
#endif
#endif /* TSLanderDelegateWrapper_h */
