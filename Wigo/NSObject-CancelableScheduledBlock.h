//
//  NSObject-CancelableScheduledBlock.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 8/25/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (CancelableScheduledBlock)

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;
- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay cancelPreviousRequest:(BOOL)cancel;

@end
