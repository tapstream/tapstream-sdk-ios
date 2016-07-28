//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSCookieMatchStrategy_h
#define TSCookieMatchStrategy_h


@protocol TSCookieMatchStrategy
- (BOOL)shouldFireCookieMatch;
- (void)startCookieMatch;
- (void)registerCookieMatchFired;
@end
#endif /* TSCookieMatchStrategy_h */
