//  Copyright © 2016 Tapstream. All rights reserved.

#ifndef TSPostData_h
#define TSPostData_h


@interface TSRequestData : NSObject
//@property(readonly, strong)NSArray<NSURLQueryItem*>* items;
+ (instancetype)requestData;
- (NSUInteger)count;
- (void)appendItemWithPrefix:(NSString *)prefix key:(NSString *)key value:(NSString *)value;
- (void)appendItemsWithPrefix:(NSString*)prefix keysAndValues:(NSString*)key, ... NS_REQUIRES_NIL_TERMINATION;
- (void)appendItemsFromRequestData:(TSRequestData*)other;
- (NSString*) URLsafeString;

@end

#endif /* TSPostData_h */
