//
//  WGUser.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGUser.h"

#define kIdKey @"id"
#define kKeyKey @"key"
#define kPrivacyKey @"privacy" //: "public",
#define kIsFollowerKey @"is_follower" //: false,
#define kNumFollowingKey @"num_following" //: 10,
#define kIsTappedKey @"is_tapped" //: false,
#define kIsBlockedKey @"is_blocked" //: false,
#define kIsBlockingKey @"is_blocking" //: false,
#define kBioKey @"bio" //: "I go out. But mostly in the mornings. ",
#define kImageKey @"image" //: null,
#define kCreatedKey @"created" //: "2014-12-14 21:41:58",
#define kIsFollowingKey @"is_following" //: false,
#define kLastNameKey @"last_name" //: "Elman",
#define kIsFollowingRequestedKey @"is_following_requested" //: false,
#define kIsGoingOutKey @"is_goingout" //: false,
#define kPropertiesKey @"properties" //: {},
#define kIsFavoriteKey @"is_favorite" //: false,
#define kFirstNameKey @"first_name" //: "Josh",
#define kGenderKey @"gender" //: "male",
#define kFacebookIdKey @"facebook_id" //: "10101301503877593",
#define kNumFollowersKey @"num_followers" //: 5,
#define kUsernameKey @"username" //: "jelman"
#define kIsAttendingKey @"is_attending" //: {},
#define kGroupKey @"group" //: {},
#define kGroupRankKey @"group_rank" //: 60

#define kGenderMaleValue @"male"
#define kGenderFemaleValue @"female"

#define kPrivacyPublicValue @"public"
#define kPrivacyPrivateValue @"private"

@interface WGUser()

@end


static WGUser *currentUser = nil;

@implementation WGUser

+ (void)setCurrentUser:(WGUser *)user {
    currentUser = user;
#warning TODO: is this the correct way to set the key?
    [[NSUserDefaults standardUserDefaults] setObject:user.key forKey:@"key"];
}

+ (WGUser *)currentUser {
    return currentUser;
}

+(WGUser *)serialize:(NSDictionary *)json {
    WGUser *newWGUser = [WGUser new];
    
    newWGUser.className =               @"user";
    newWGUser.id =                      [json st_integerForKey:kIdKey];
    newWGUser.key =                     [json st_stringForKey:kKeyKey];
    
    newWGUser.privacy =                 [json st_stringForKey:kPrivacyKey];
    /* if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPublicValue]) {
        newWGUser.privacy =             PUBLIC;
    } else if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPrivateValue]) {
        newWGUser.privacy =             PRIVATE;
    } else {
        newWGUser.privacy =             OTHER;
    } */
    
    newWGUser.numFollowing =            [json st_integerForKey:kNumFollowingKey];
    
    if ([json valueForKey:kIsFollowerKey]) {
        newWGUser.isFollower =              [NSNumber numberWithBool: [json st_boolForKey:kIsFollowerKey]];
    }
    if ([json valueForKey:kIsTappedKey]) {
        newWGUser.isTapped =                [NSNumber numberWithBool: [json st_boolForKey:kIsTappedKey]];
    }
    if ([json valueForKey:kIsBlockedKey]) {
        newWGUser.isBlocked =               [NSNumber numberWithBool: [json st_boolForKey:kIsBlockedKey]];
    }
    if ([json valueForKey:kIsBlockingKey]) {
        newWGUser.isBlocking =              [NSNumber numberWithBool: [json st_boolForKey:kIsBlockingKey]];
    }
    if ([json valueForKey:kIsBlockingKey]) {
        newWGUser.isFollowing =             [NSNumber numberWithBool: [json st_boolForKey:kIsFollowingKey]];
    }
    if ([json valueForKey:kIsFavoriteKey]) {
        newWGUser.isFavorite =              [NSNumber numberWithBool: [json st_boolForKey:kIsFavoriteKey]];
    }
    if ([json valueForKey:kIsFollowingKey]) {
        newWGUser.isFollowingRequested =    [NSNumber numberWithBool: [json st_boolForKey:kIsFollowingRequestedKey]];
    }
    if ([json valueForKey:kIsGoingOutKey]) {
        newWGUser.isGoingOut =              [NSNumber numberWithBool: [json st_boolForKey:kIsGoingOutKey]];
    }
    if ([json valueForKey:kIsAttendingKey]) {
        newWGUser.isAttending =             [NSNumber numberWithBool: [json st_boolForKey:kIsAttendingKey]];
    }
    
    newWGUser.bio =                     [json st_stringForKey:kBioKey];
    newWGUser.image =                   [json st_stringForKey:kImageKey];
    newWGUser.created =                 [json st_dateForKey:kCreatedKey];
    newWGUser.lastName =                [json st_stringForKey:kLastNameKey];
    newWGUser.properties =              [json st_dictionaryForKey:kPropertiesKey];
    newWGUser.firstName =               [json st_stringForKey:kFirstNameKey];
    
    newWGUser.gender =                  [json st_stringForKey:kGenderKey];
    /* if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderMaleValue]) {
        newWGUser.gender =              MALE;
    } else if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderFemaleValue]) {
        newWGUser.gender =              FEMALE;
    } else {
        newWGUser.gender =              UNKNOWN;
    } */
    
    newWGUser.facebookId =              [json st_stringForKey:kFacebookIdKey];
    newWGUser.numFollowers =            [json st_integerForKey:kNumFollowersKey];
    newWGUser.username =                [json st_stringForKey:kUsernameKey];
    newWGUser.group =                   [json st_dictionaryForKey:kGroupKey];
    newWGUser.groupRank =               [json st_integerForKey:kGroupRankKey];
    
    return newWGUser;
}

-(State)getUserState {
    if (_isBlocked) {
        return BLOCKED_USER_STATE;
    }
    if (_privacy == PRIVATE) {
        if (_isFollowing) {
            if (_isAttending) return ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE;
            return FOLLOWING_USER_STATE;
        }
        else if (_isFollowingRequested) {
            return NOT_YET_ACCEPTED_PRIVATE_USER_STATE;
        }
        else return NOT_SENT_FOLLOWING_PRIVATE_USER_STATE;
    }
    if (_isFollowing) {
        if (_isAttending) return ATTENDING_EVENT_FOLLOWING_USER_STATE;
        return FOLLOWING_USER_STATE;
    }
    return NOT_FOLLOWING_PUBLIC_USER_STATE;
}

+(void)getUsers:(CollectionResult)handler {
    [WGApi get:@"users/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
        }
        WGCollection *users = [WGCollection initWithResponse:jsonResponse andClass:[self class]];
        handler(users, error);
    }];
}

+(void) getCurrentUser {
    [WGApi get:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
        [WGUser setCurrentUser: [WGUser serialize:jsonResponse]];
        NSLog(@"---- Set Current User -----");
    }];
}

@end
