//  Copyright © 2016 Tapstream. All rights reserved.


#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#define TS_IOS_ONLY
	#define kTSPlatform @"iOS"
#else
	#define TS_MAC_ONLY
	#define kTSPlatform @"Mac"
#endif

#define kTSVersion @"3.2.0"
#define kTSDefaultTimeout 10000
