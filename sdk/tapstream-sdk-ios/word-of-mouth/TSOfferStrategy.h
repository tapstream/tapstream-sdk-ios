//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSOfferStrategy_h
#define TSOfferStrategy_h

#import "TSOffer.h"

@protocol TSOfferStrategy
- (bool)eligible:(TSOffer*)offer;
- (TSOffer*)cachedOffer:(NSString*)insertionPoint sessionId:(NSString*)uuid;
- (void)registerOfferRetrieved:(TSOffer *)offer forInsertionPoint:(NSString*)insertionPoint;
- (void)registerOfferShown:(TSOffer *)offer;
@end


#endif /* TSOfferStrategy_h */
