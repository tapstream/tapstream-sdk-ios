//  Copyright © 2023 Tapstream. All rights reserved.

#import <Foundation/Foundation.h>
#import "TSTestUtils.h"

void block_until_queue_completed(dispatch_queue_t queue)
{
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);

	// Wait 100 ms to send signal
	double t = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1);
	dispatch_after(t, queue, ^{
		dispatch_semaphore_signal(sem);
	});

	// Wait 1s to receive signal
	double t2 = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
	dispatch_semaphore_wait(sem, t2);
}
