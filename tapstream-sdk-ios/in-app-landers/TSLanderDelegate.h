//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSLanderDelegate_h
#define TSLanderDelegate_h

#import <Foundation/Foundation.h>
#import "TSLander.h"

@protocol TSLanderDelegate<NSObject>

- (void)showedLander:(TSLander*)lander;
- (void)dismissedLander;
- (void)submittedLander;

@end


#endif /* TSLanderDelegate_h */
