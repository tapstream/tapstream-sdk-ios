//  Copyright © 2016 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSMaybeError.h"

@interface TSMaybeError()
@property(strong, readwrite) id obj;
@property(strong, readwrite) NSError* error;
@end


@implementation TSMaybeError
@synthesize error;
+ (instancetype)withObject:(id)obj
{
	return [[self alloc] initWithObject:obj error:nil];
}

+ (instancetype)withError:(NSError*)err
{
	return [[self alloc] initWithObject:nil error:err];
}

- (instancetype)initWithObject:(id)obj error:(NSError*)err
{
	if((self = [super init]) != nil)
	{
		error = err;
		self.obj = obj;
	}
	return self;
}

- (id)get
{
	return self.obj;
}

- (bool)failed{ return error != nil; }
@end
