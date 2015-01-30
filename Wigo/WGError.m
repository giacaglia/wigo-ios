//
//  WGError.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGError.h"
#import <Crashlytics/Crashlytics.h>
#import "GCDAsyncUdpSocket.h"
#import "WGProfile.h"

#define kPapertrailURL @"logs2.papertrailapp.com"
#define kPapertrailPort 21181

#define kDeviceType @"iphone"
#define kDeviceTypeKey @"device_type"
#define kAppVersionKey @"app_version"
#define kOSVersionKey @"os_version"
#define kDebugKey @"debug"

#define kDismiss 0
#define kRetryButton 1

#define kErrorTitles @[@"Post failed", @"Search failed", @"Delete failed", @"Upload failed", @"Failed to load", @"Login failed", @"Failed to create", @"Could not save", @"Facebook Error"]

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
    GCDAsyncUdpSocket *udpSocket;
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
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
    if ([WGProfile currentUser].id) {
        [userInfo setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:kAppVersionKey];
        [userInfo setObject:kDeviceType forKey:kDeviceTypeKey];
        [userInfo setObject:[[UIDevice currentDevice] systemVersion] forKey:kOSVersionKey];
#if DEBUG
        [userInfo setObject:@YES forKey:kDebugKey];
#endif
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSString *logMessage = [NSString stringWithFormat:@"Error: %@ with Action: %@", [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo], [self titleForActionType: action]];
    
    NSString *formattedLogMessage = [NSString stringWithFormat:@"<22>1 %@ ios user-%@ - - - %@", [dateFormatter stringFromDate:[NSDate date]], [WGProfile currentUser].id, logMessage];
    
    [udpSocket sendData:[formattedLogMessage dataUsingEncoding:NSUTF8StringEncoding] toHost:kPapertrailURL port:kPapertrailPort withTimeout:-1 tag:1];
    
    NSLog(@"%@", formattedLogMessage);
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
