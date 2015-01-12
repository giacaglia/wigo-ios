//
//  WGAnalytics.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGAnalytics.h"

@implementation WGAnalytics

+(void) tagEvent:(NSString *)name {
    [WGAnalytics tagEvent:name withDetails:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
}

+(NSString *) bucketizeUsers:(int) num {
    if (num < 0)   return @"Unknown";
    if (num == 0)  return @"0";
    if (num < 5)   return @"<5";
    if (num < 10)  return @"<10";
    if (num < 30)  return @"<30";
    if (num < 100) return @"30-100";
    return @"100+";
}

+(void) tagEvent:(NSString *)name withDetails:(NSDictionary *)details {
    if (![[WGProfile currentUser] isFetched] || [[WGProfile currentUser].googleAnalyticsEnabled boolValue] == NO) {
        return;
    }
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    WGProfile *profile = [WGProfile currentUser];
    
    // School
    NSString *groupName = profile.group.name;
    if (groupName != nil) {
        [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:groupName forKey:@"School"]];
        [tracker set:[GAIFields customDimensionForIndex:5] value:groupName];
    }
    
    // Going Out
    NSString *goingOut = [profile.isGoingOut boolValue] ? @"Yes" : @"No";
    [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:goingOut forKey:@"Going Out"]];
    [tracker set:[GAIFields customDimensionForIndex:4] value:goingOut];
    
    // Gender
    [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:[profile genderName] forKey:@"Gender"]];
    [tracker set:[GAIFields customDimensionForIndex:1] value:[profile genderName]];
    
    // Following/Followers
    NSString *followingBucket = [self bucketizeUsers:[profile.numFollowing intValue]];
    NSString *followersBucket = [self bucketizeUsers:[profile.numFollowers intValue]];
    [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:followingBucket forKey:@"Following"]];
    [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:followersBucket forKey:@"Followers"]];
    [tracker set:[GAIFields customDimensionForIndex:2] value:followingBucket];
    [tracker set:[GAIFields customDimensionForIndex:3] value:followersBucket];
    
    // is Group Locked
    NSString *locked = [profile.group.locked boolValue] ? @"Yes" : @"No";
    [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:locked forKey:@"Locked"]];
    [tracker set:[GAIFields customDimensionForIndex:6] value:locked];
    
    // is User tapped
    NSString *tapped = [profile.isTapped boolValue] ? @"Yes" : @"No";
    [data addEntriesFromDictionary:[NSDictionary dictionaryWithObject:tapped forKey:@"Tapped"]];
    [tracker set:[GAIFields customDimensionForIndex:7] value:tapped];
    
    //check if is peeking
    if ([[details objectForKey: @"isPeeking"] isEqualToString: @"Yes"]) {
        [tracker set:[GAIFields customDimensionForIndex:8] value:@"Yes"];
    } else {
        [tracker set:[GAIFields customDimensionForIndex:8] value:@"No"];
    }
    
    [data addEntriesFromDictionary:details];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"   // Event category (required)
                                                            action:name         // Event action (required)
                                                            label:nil           // Event label
                                                            value:nil] build]];
}

+(void) tagScreen:(NSString *)name {
    if (![[WGProfile currentUser] isFetched] || [[WGProfile currentUser].googleAnalyticsEnabled boolValue] == NO) {
        return;
    }
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:name];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

+(void) setUser:(WGUser *)user {
    if (![[WGProfile currentUser] isFetched] || [[WGProfile currentUser].googleAnalyticsEnabled boolValue] == NO) {
        return;
    }
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:@"&uid" value:[user.id stringValue]];
    // We are currently using custom dimension 0 to represent the name of the school
    // Note that this is vulnerable to Ben renaming schools via the admin dashboard, but the
    // alternative of having us have all the reports be by school ID as a string seems far too
    // painful to contemplate.
    [tracker set:[GAIFields customDimensionForIndex:5] value:user.group.name];
}

@end
