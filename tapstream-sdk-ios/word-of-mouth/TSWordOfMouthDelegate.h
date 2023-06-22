//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>

@protocol TSWordOfMouthDelegate <NSObject>

- (void)showedOffer:(NSUInteger)offerId;
- (void)dismissedOffer:(BOOL)accepted;
- (void)showedSharing:(NSUInteger)offerId;
- (void)dismissedSharing;
- (void)completedShare:(NSUInteger)offerId socialMedium:(NSString *)medium;

@end
