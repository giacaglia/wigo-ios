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

@end
