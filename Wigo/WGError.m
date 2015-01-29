//
//  WGError.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGError.h"
#import <Crashlytics/Crashlytics.h>

#define kDismiss 0
#define kRetryButton 1

#define kErrorTitles @[@"Post failed", @"Search failed", @"Delete failed", @"Submit failed", @"Request failed", @"Failed to load", @"Cancel Request failed", @"Failed to contact", @"Ignore failed", @"Login failed", @"Failed to create", @"Could not save", @"Wigo cannot connect to the internet"]

#define kMessageKey @"message"

#define kServerErrorDomain @"com.alamofire.error.serialization.response"
#define kServerErrorCodeGeneric -1011

#define kNotFoundStatusCode 404
#define kBadRequestStatusCode 400

#define kServerConnectionFailedMessage @"The Wigo server could not be reached."

#define kNoInternetConnectionMessage   @"The internet connection appears to be offline."
#define kServerTimeoutMessage          @"Timeout occured."

#define kUnknownErrorMessage @"An error has occured."
#define KUnknownErrorMore    @"Please try again later.";

@interface WGError() {
    UIAlertView *errorAlertView;
    WGErrorRetryBlock currentRetryHandler;
}

@end

@implementation WGError

static WGError *sharedWGErrorInstance = nil;

+(WGError *) sharedInstance {
    if (sharedWGErrorInstance == nil) {
        sharedWGErrorInstance = [WGError new];
    }
    
    return sharedWGErrorInstance;
}

-(void) handleError: (NSError *)error actionType: (WGActionType) action retryHandler: (WGErrorRetryBlock) retryHandler {
    if (errorAlertView != nil) { // if alert in progress, ignore other alerts.
        return;
    }
    
    [self logError: error forAction: action];
    
    NSString *titleString = [self titleForActionType: action];
    NSString *messageString;
    NSString *moreString;
    if ([error.userInfo objectForKey:@"wigoCode"] && [[error.userInfo objectForKey:@"wigoCode"] isEqual:@"does_not_exist"]) {
        return;
    }
    if ([error.domain isEqualToString:kServerErrorDomain]) {
        long httpStatus = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
        
        NSString *invalidField = [error.userInfo objectForKey:@"wigoField"];
        
        if (httpStatus == kNotFoundStatusCode) {
            if (invalidField) {
                titleString = [NSString stringWithFormat:@"Invalid %@", invalidField];
                messageString = [NSString stringWithFormat:@"Please enter a valid %@.", invalidField];
            } else {
                titleString    = kUnknownErrorMessage;
                messageString  = KUnknownErrorMore;
            }
            moreString = @"";
        } else if (httpStatus == kBadRequestStatusCode) {
            if (invalidField) {
                titleString = [NSString stringWithFormat:@"Invalid %@", invalidField];
                messageString = [NSString stringWithFormat:@"Please enter a valid %@.", invalidField];
            } else {
                titleString    = kUnknownErrorMessage;
                messageString  = KUnknownErrorMore;
            }
            moreString = @"";
        } else {
            messageString = kUnknownErrorMessage;
            moreString    = KUnknownErrorMore;
        }
    } else {
        if ([[error localizedFailureReason] hasPrefix:@"Exception:"] || [[error localizedDescription] hasPrefix:@"Exception:"]) {
            messageString = @"Internal Error.";
            moreString = @"Please try again!";
        } else {
            messageString = [error localizedDescription];
            moreString = [error localizedFailureReason] ? [error localizedFailureReason] : @"";
        }
    }
    
    // Combine message
    messageString = [NSString stringWithFormat:@"%@ %@", messageString, moreString];
    
    if (retryHandler) {
        currentRetryHandler = retryHandler;
        errorAlertView = [[UIAlertView alloc] initWithTitle: titleString message: messageString delegate: self cancelButtonTitle:@"OK" otherButtonTitles: @"Try Again", nil];
    } else {
        currentRetryHandler = nil;
        errorAlertView = [[UIAlertView alloc] initWithTitle: titleString message: messageString delegate: self cancelButtonTitle: @"OK" otherButtonTitles:nil];
    }
    
    [errorAlertView show];
}

-(void) logError: (NSError *) error forAction: (WGActionType) action{
    NSLog(@"Logged Error: %@ for Action: %@", error, [self titleForActionType: action]);
}

-(NSString *) titleForActionType: (WGActionType) action {
    return [kErrorTitles objectAtIndex: action];
}

#pragma mark - UIAlertView Delegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView != errorAlertView) { //impossible, yet not our alert view
        return;
    }
    
    if (buttonIndex == kRetryButton) {
        if (currentRetryHandler) {
            currentRetryHandler(YES);
        }
    } else if (buttonIndex == kDismiss) {
        if (currentRetryHandler) {
            currentRetryHandler(NO);
        }
    }
    
    errorAlertView = nil;
}

@end
