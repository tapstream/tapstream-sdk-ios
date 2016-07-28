//
//  Header.m
//  example
//
//  Created by Adam Bard on 2016-05-13.
//  Copyright © 2016 Tapstream. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Header.h"
#import <Tapstream_iOS/TSTapstream.h>

@implementation Header

+ (id)doAThing
{
	[TSTapstream createWithAccountName:@"TAPSTREAM_ACCOUNT_NAME" developerSecret:@"TAPSTREAM_SDK_SECRET" config:config];

}

@end

