//
//  NSObject-CancelableScheduledBlock.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 8/25/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "NSObject-CancelableScheduledBlock.h"

@implementation NSObject (CancelableScheduledBlock)

- (void)delayedAddOperation:(NSOperation *)operation {
    [[NSOperationQueue currentQueue] addOperation:operation];
}

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay {
    [self performSelector:@selector(delayedAddOperation:)
               withObject:[NSBlockOperation blockOperationWithBlock:block]
               afterDelay:delay];
}

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay cancelPreviousRequest:(BOOL)cancel {
    if (cancel) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    [self performBlock:block afterDelay:delay];
}

@end