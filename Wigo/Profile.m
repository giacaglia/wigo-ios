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
            KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"WiGo" accessGroup:nil];
            NSData *keyData = (NSData *)[keychainItem objectForKey:(__bridge id)kSecValueData];
            NSString *key = [[NSString alloc] initWithData:keyData
                                                  encoding:NSUTF8StringEncoding];
            if (key.length == 0) {
                NSData *newKeyData = [[oldUser key] dataUsingEncoding:NSUTF8StringEncoding];
                [keychainItem setObject:newKeyData forKey:(__bridge id)(kSecValueData)];
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
    if (userDictionary && [Profile user]) {
        return [[userDictionary objectForKey:@"id"] isEqualToNumber:[[Profile user] objectForKey:@"id"]];
    }
    return NO;
}



@end
