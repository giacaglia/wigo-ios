//
//  Profile.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Profile.h"

@implementation Profile

static UIImage *profileImage;
static BOOL isGoingOut;
static NSString *placeGoingOut;
static User *user;
static NSArray *images;
static Party *everyoneParty;
static Party *followingParty;
static Party *notAcceptedFollowingParty;


+ (User *)user {
    if (user == nil) {
        user = [[User alloc] init];
    }
    return user;
}

+ (void)setUser:(User *)newUser {
    user = newUser;
}

+ (Party *)everyoneParty {
    if (everyoneParty == nil) {
        everyoneParty = [[Party alloc] init];
    }
    return everyoneParty;
}

+ (void)setEveryoneParty:(Party *)newEveryoneParty {
    everyoneParty = newEveryoneParty;
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

+ (BOOL)isUserDictionaryProfileUser:(NSDictionary *)userDictionary {
    return [[userDictionary objectForKey:@"id"] isEqualToNumber:[[Profile user] objectForKey:@"id" ]];
}


@end
