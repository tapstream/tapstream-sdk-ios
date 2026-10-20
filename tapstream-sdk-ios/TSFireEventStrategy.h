//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSFireEventStrategy_h
#define TSFireEventStrategy_h

#import "TSResponse.h"
#import "TSEvent.h"

@protocol TSFireEventStrategy<NSObject>
- (BOOL)shouldFireEvent:(TSEvent*)event;
- (int)getDelay;
- (void)registerFiringEvent:(TSEvent*)e;
- (void)registerResponse:(TSResponse*)response forEvent:(TSEvent*)e;
@optional
// Called for a retryable failure. Returns whether the event should be retried,
// and counts the retry if so. Strategies that don't implement it retry without limit.
- (BOOL)shouldRetryEvent:(TSEvent*)e;
@end

#endif /* TSFireEventStrategy_h */
