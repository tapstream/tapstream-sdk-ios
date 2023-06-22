//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSOfferApiResponse_h
#define TSOfferApiResponse_h

#import "TSOffer.h"
#import "TSResponse.h"

@interface TSOfferApiResponse : NSObject<TSFallable>
@property (strong, readonly) TSOffer* offer;
@property (strong, readonly) TSResponse* response;
@property (strong, readonly) NSError* error;
+ (instancetype)offerApiResponseWithResponse:(TSResponse*)response sessionId:(NSString*)uuid;
+ (instancetype)offerApiResponseWithOffer:(TSOffer*)offer;
@end

#endif /* TSOfferApiResponse_h */
