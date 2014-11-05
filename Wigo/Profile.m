//
//  Profile.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Profile.h"
#import "KeychainItemWrapper.h"

@implementation Profile

static UIImage *profileImage;
static NSString *placeGoingOut;
static User *user;
static NSArray *images;
static Party *everyoneParty;
static Party *followingParty;
static Party *notAcceptedFollowingParty;
static BOOL googleAnalyticsEnabled;
static BOOL localyticsEnabled;
static NSNumber *lastUserRead;
static NSString *stringAwsKey;
static NSString *cdnPrefix;


+ (User *)user {
    if (user == nil) {
        user = [[User alloc] init];
    }
    return user;
}

+ (void)setUser:(User *)newUser {
    if (newUser) {
        User *oldUser = [self user];
        user = newUser;
        if ([oldUser key]) {
            [user setKey:[oldUser key]];
            NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:@"key"];
            if (key.length == 0) {
                [[NSUserDefaults standardUserDefaults] setObject:[oldUser key] forKey:@"key"];
            }
        }
        [newUser updateUserAnalytics];
    }
}

+ (void)setLastUserJoined:(NSNumber *)newLastUserJoined {
    lastUserRead = newLastUserJoined;
}

+ (NSNumber *)lastUserJoined {
    return lastUserRead;
}

+ (Party *)followingParty {
    if (followingParty == nil) {
        followingParty = [[Party alloc] init];
    }
    return followingParty;
}

+ (void)setFollowingParty:(Party *)newFollowingParty {
    followingParty = newFollowingParty;
}

+ (Party *)notAcceptedFollowingParty {
    if (notAcceptedFollowingParty == nil) {
        notAcceptedFollowingParty = [[Party alloc] init];
    }
    return notAcceptedFollowingParty;
}

+ (void)setNotAcceptedFollowingParty:(Party *)newFollowingParty {
    notAcceptedFollowingParty = newFollowingParty;
}

+ (BOOL) localyticsEnabled {
    return localyticsEnabled;
}

+ (void) setLocalyticsEnabled:(BOOL)enabled {
    localyticsEnabled = enabled;
}

+ (BOOL) googleAnalyticsEnabled {
    return googleAnalyticsEnabled;
}

+ (void) setGoogleAnalyticsEnabled:(BOOL)enabled {
    googleAnalyticsEnabled = enabled;
}

+ (BOOL)isUserDictionaryProfileUser:(NSDictionary *)userDictionary {
    if (userDictionary && [Profile user] && [[[Profile user] allKeys] containsObject:@"id"]) {
        return [[userDictionary objectForKey:@"id"] isEqualToNumber:[[Profile user] objectForKey:@"id"]];
    }
    return NO;
}

+ (NSString *)awsKey {
    if (stringAwsKey) return stringAwsKey;
    NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:@"awsKey"];
    if (key) {
        stringAwsKey = key;
        return key;
    }
    else return nil;
}

+ (void)setAwsKey:(NSString *)awsKey {
    if (awsKey) {
        [[NSUserDefaults standardUserDefaults] setObject:awsKey forKey:@"awsKey"];
        stringAwsKey = awsKey;
    }
}

+ (NSString *)cdnPrefix {
    if (cdnPrefix) return cdnPrefix;
    else {
        cdnPrefix = [[NSUserDefaults standardUserDefaults] objectForKey:@"cdnPrefix"];
        if (cdnPrefix) return cdnPrefix;
        return @"wigo-uploads.s3.amazonaws.com/";
    }
}

+(void)setCDNPrefix:(NSString *)newCdnPrefix {
    if (newCdnPrefix) {
        [[NSUserDefaults standardUserDefaults] setObject:newCdnPrefix forKey:@"cdnPrefix"];
        cdnPrefix = newCdnPrefix;
    }
}



@end
