//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSLanderStrategy_h
#define TSLanderStrategy_h
#import "TSLander.h"

@protocol TSLanderStrategy<NSObject>

- (BOOL)shouldShowLander:(TSLander*)lander;
- (void)registerLanderShown:(TSLander*)lander;
@end

#endif /* TSLanderStrategy_h */
