//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSURLBuilder_h
#define TSURLBuilder_h

#import "TSConfig.h"
#import "TSRequestData.h"


@interface TSURLBuilder : NSObject

+ (NSURL*) urlWithParameters:(NSString*)baseUrl globalEventParams:(NSDictionary*)params data:(TSRequestData*)data, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSURL*)makeEventURL:(TSConfig*)config eventName:(NSString*)eventName;
+ (NSURL*)makeConversionURL:(TSConfig*)config sessionId:(NSString*)sessionId;
+ (NSURL*)makeLanderURL:(TSConfig*)config sessionId:(NSString*)sessionId;
+ (NSURL*)makeCookieMatchURL:(TSConfig*)config eventName:(NSString*)eventName data:(TSRequestData*)data;
+ (NSURL*)makeDeeplinkQueryURL:(TSConfig*)config forURL:(NSString*)url;
+ (NSURL*)makeSimulatedClickURL:(NSURL*)baseURL;
+ (NSURL*)makeOfferURL:(TSConfig*)config bundle:(NSString*)bundle insertionPoint:(NSString*)insertionPoint;
+ (NSURL*)makeRewardListURL:(TSConfig*)config sessionId:(NSString*)sessionId;
@end

#endif /* Header_h */
