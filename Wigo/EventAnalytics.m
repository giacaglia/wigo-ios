//
//  EventAnalytics.m
//  Classy
//
//  Created by Dennis Doughty on 7/25/14.
//  Copyright (c) 2014 WiGo. All rights reserved.
//

#import "EventAnalytics.h"
#import "Globals.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

@implementation EventAnalytics

+(void) tagEvent:(NSString *)name {
    [EventAnalytics tagEvent:name withDetails:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
}

+(void) tagEvent:(NSString *)name withDetails:(NSDictionary *)details {
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    
    User *profileUser = [Profile user];
    
    if (profileUser != nil) {
        NSString *groupName = profileUser.groupName;
        if (groupName != nil) {
            [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:groupName forKey:@"School"]];
        }
        NSString *goingOut = profileUser.isGoingOut ? @"Yes" : @"No";
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:goingOut forKey:@"Going Out"]];
        
        // number of following
        NSString *followingBucket;
        int following = [[profileUser numberOfFollowing] intValue];
        
        if (following < 0) {
            followingBucket = @"Unknown";
        } else if (following == 0) {
            followingBucket = @"0";
        } else if (following < 5) {
            followingBucket = @"<5";
        } else if (following < 10) {
            followingBucket = @"<10";
        } else if (following < 30) {
            followingBucket = @"<30";
        } else if (following < 100) {
            followingBucket = @"30-100";
        } else {
            followingBucket = @"100+";
        }
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:followingBucket forKey:@"Following"]];
    }
    
    [data addEntriesFromDictionary:details];
    [[LocalyticsSession shared] tagEvent:name attributes:data];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:name  // Event action (required)
                                                           label:nil          // Event label
                                                           value:nil] build]];
}

+(void) tagScreen:(NSString *)name {
    [[LocalyticsSession shared] tagScreen:name];
}

+(void) tagGroup:(NSString *)name {
    // We are currently using custom dimension 0 to represent the name of the school
    // Note that this is vulnerable to Ben renaming schools via the admin dashboard, but the
    // alternative of having us have all the reports be by school ID as a string seems far too
    // painful to contemplate.
    [[LocalyticsSession shared] setCustomDimension:0 value:name];
}

+(void) tagUser:(NSString *)user {
    [[LocalyticsSession shared] setCustomerId:user];
}

@end
