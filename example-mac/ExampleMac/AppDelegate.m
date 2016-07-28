//
//  AppDelegate.m
//  ExampleMac
//
//  Created by Adam Bard on 2016-07-26.
//  Copyright © 2016 Tapstream. All rights reserved.
//

#import "AppDelegate.h"
#import "TapstreamMac.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application

	TSConfig* config = [TSConfig configWithAccountName:@"my-acct" sdkSecret:@"my-secret"];
	[TSTapstream createWithConfig:config];
	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
