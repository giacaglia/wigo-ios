//
//  NSObject+WGI.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGI.h"

static NSString *sessionID;
static NSDate *closedAppTime;
static WGTracker *tracker;

@implementation WGI : NSObject

+ (WGTracker *)defaultTracker {
    if (tracker == nil) {
        tracker = [WGTracker new];
    }
    return tracker;
}

+ (void)changeSessionID {
    sessionID = [[NSUUID UUID] UUIDString];
}

+ (void)setSessionID {
    if (sessionID == nil ||
        [sessionID isKindOfClass:[NSNull class]]) {
        [WGI changeSessionID];
    }
    WGI.defaultTracker.defaultSessionID = sessionID;
}


#pragma mark - Helper Functions


+ (void)openedTheApp {
    NSDate *timeNow = [NSDate date];
    [WGTracker getTimeNow];
    NSTimeInterval diff = [timeNow timeIntervalSinceDate:closedAppTime];
    if (diff > 300 ||
        closedAppTime == nil) {
        [WGI changeSessionID];
        [WGI setSessionID];
    }
}

+ (void)closedTheApp {
    closedAppTime = [NSDate date];
}

@end