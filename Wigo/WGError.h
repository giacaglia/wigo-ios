//
//  WGError.h
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

typedef enum {
    WGActionPost    = 0,
    WGActionSearch  = 1,
    WGActionDelete  = 2,
    WGActionSubmit  = 3,
    WGActionRequest = 4,
    WGActionLoad    = 5,
    WGActionCancel  = 6,
    WGActionAccept  = 7,
    WGActionIgnore  = 8,
    WGActionLogin   = 9,
    WGActionCreate  = 10,
    WGActionSave    = 11,
    WGActionCore    = 12
} WGActionType;


typedef void (^WGErrorRetryBlock)(BOOL didRetry);

@interface WGError : NSObject <UIAlertViewDelegate>

+ (WGError *) sharedInstance;

- (void) handleError: (NSError *)error actionType: (WGActionType) action retryHandler: (WGErrorRetryBlock) retryHandler;

- (void) logError: (NSError *) error forAction: (WGActionType) action;

@end

