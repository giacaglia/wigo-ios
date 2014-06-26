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


+ (UIImage *)getProfileImage {
    return [user coverImage];
}

+ (BOOL)isGoingOut {
    return isGoingOut;
}

+ (void)setIsGoingOut:(BOOL)varIsGoingOut {
    isGoingOut = varIsGoingOut;
}

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




@end
