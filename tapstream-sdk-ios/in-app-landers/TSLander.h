//  Copyright © 2023 Tapstream. All rights reserved.

#ifndef TSLander_h
#define TSLander_h

@interface TSLander : NSObject
@property(assign, nonatomic, readonly) NSUInteger ident;
@property(strong, nonatomic, readonly) NSString *html;
@property(strong, nonatomic, readonly) NSURL *url;
+ (instancetype)landerWithDescription:(NSDictionary*)descriptionVal;
- (BOOL)isValid;
@end

#endif /* TSLander_h */
