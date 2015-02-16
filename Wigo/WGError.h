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
    WGActionUpload  = 3,
    WGActionLoad    = 4,
    WGActionLogin   = 5,
    WGActionCreate  = 6,
    WGActionSave    = 7,
    WGActionFacebook = 8
} WGActionType;


typedef void (^WGErrorRetryBlock)(BOOL didRetry);

@interface WGError : NSObject <UIAlertViewDelegate>

+ (WGError *) sharedInstance;

- (void) handleError: (NSError *)error actionType: (WGActionType) action retryHandler: (WGErrorRetryBlock) retryHandler;

- (void) logError: (NSError *) error forAction: (WGActionType) action;

@end

