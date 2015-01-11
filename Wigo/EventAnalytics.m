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
#import "GAIFields.h"

@implementation EventAnalytics

+(void) tagEvent:(NSString *)name {
    [EventAnalytics tagEvent:name withDetails:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
}

+(NSString *) bucketizeUsers:(int) num {
    // number of following
    if (num < 0)        { return @"Unknown"; }
    else if (num == 0)  { return @"0"; }
    else if (num < 5)   { return @"<5"; }
    else if (num < 10)  { return @"<10"; }
    else if (num < 30)  { return @"<30"; }
    else if (num < 100) { return @"30-100"; } 
    else {                return @"100+"; }
}

+(void) tagEvent:(NSString *)name withDetails:(NSDictionary *)details {
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];

    id<GAITracker> tracker;
    if ([Profile googleAnalyticsEnabled]) {
        tracker = [[GAI sharedInstance] defaultTracker];
    }
    
    User *profileUser = [Profile user];
    
    if (profileUser != nil) {
        // School
        NSString *groupName = profileUser.groupName;
        if (groupName != nil) {
            [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:groupName forKey:@"School"]];
            [tracker set:[GAIFields customDimensionForIndex:5] value:groupName];
        }

        // Going Out
        NSString *goingOut = profileUser.isGoingOut ? @"Yes" : @"No";
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:goingOut forKey:@"Going Out"]];
        [tracker set:[GAIFields customDimensionForIndex:4] value:goingOut];

        // Gender
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:profileUser.gender forKey:@"Gender"]];
        [tracker set:[GAIFields customDimensionForIndex:1] value:profileUser.gender];
        
        // Following/Followers
        NSString *followingBucket = [self bucketizeUsers:[[profileUser numberOfFollowing] intValue]];
        NSString *followersBucket = [self bucketizeUsers:[[profileUser numberOfFollowers] intValue]];
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:followingBucket forKey:@"Following"]];
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:followersBucket forKey:@"Followers"]];
        [tracker set:[GAIFields customDimensionForIndex:2] value:followingBucket];
        [tracker set:[GAIFields customDimensionForIndex:3] value:followersBucket];

        // is Group Locked
        NSString *locked = [profileUser isGroupLocked] ? @"Yes" : @"No";
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:locked forKey:@"Locked"]];
        [tracker set:[GAIFields customDimensionForIndex:6] value:locked];
        
        // is User tapped
        NSString *tapped = [profileUser isTapped] ? @"Yes" : @"No";
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:tapped forKey:@"Tapped"]];
        [tracker set:[GAIFields customDimensionForIndex:7] value:tapped];
    }
    
    
    //check if is peeking
    if ([[details objectForKey: @"isPeeking"] isEqualToString: @"Yes"]) {
        [tracker set:[GAIFields customDimensionForIndex:8] value:@"Yes"];
    } else {
        [tracker set:[GAIFields customDimensionForIndex:8] value:@"No"];
    }

    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:name  // Event action (required)
                                                           label:nil          // Event label
                                                           value:nil] build]];
}

+(void) tagScreen:(NSString *)name {
    
    if ([Profile googleAnalyticsEnabled]) {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:name];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
}

+(void) tagGroup:(NSString *)name {
    // We are currently using custom dimension 0 to represent the name of the school
    // Note that this is vulnerable to Ben renaming schools via the admin dashboard, but the
    // alternative of having us have all the reports be by school ID as a string seems far too
    // painful to contemplate.
    id<GAITracker> tracker;
    if ([Profile googleAnalyticsEnabled]) {
        tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:[GAIFields customDimensionForIndex:5] value:name];
    }
}

+(void) tagUser:(NSString *)user {
    
    if ([Profile googleAnalyticsEnabled]) {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:@"&uid" value:user];
    }
}

@end
