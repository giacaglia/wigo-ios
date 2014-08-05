//
//  EventAnalytics.m
//  Classy
//
//  Created by Dennis Doughty on 7/25/14.
//  Copyright (c) 2014 WiGo. All rights reserved.
//

#import "EventAnalytics.h"
#import "Globals.h"

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
    }
    
    [data addEntriesFromDictionary:details];
    [[LocalyticsSession shared] tagEvent:name attributes:data];
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
