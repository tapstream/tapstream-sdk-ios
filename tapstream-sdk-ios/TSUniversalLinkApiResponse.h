//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSUniversalLink_h
#define TSUniversalLink_h

#import "TSResponse.h"
#import "TSFallable.h"

typedef enum _TSUniversalLinkStatus
{
	kTSULValid = 0,
	kTSULDisabled,
	kTSULUnknown
} TSUniversalLinkStatus;

@interface TSUniversalLinkApiResponse : NSObject<TSFallable>

@property(nonatomic, strong, readonly) NSURL* deeplinkURL;
@property(nonatomic, strong, readonly) NSURL* fallbackURL;
@property(nonatomic, readonly) TSUniversalLinkStatus status;
@property(nonatomic, strong, readonly) NSError* error;

+ (instancetype)universalLinkApiResponseWithResponse:(TSResponse*)response;
+ (instancetype)universalLinkApiResponseWithStatus:(TSUniversalLinkStatus)status;
@end


#endif /* TSUniversalLink_h */
