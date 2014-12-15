//
//  WGUser.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGUser.h"

#define kIdKey @"id"

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

@implementation WGUser

+(WGUser *)serialize:(NSDictionary *)json {
    WGUser *newWGUser = [WGUser new];
    
    newWGUser.id = [json st_integerForKey:kIdKey];
    
    if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPublicValue]) {
        newWGUser.privacy = PUBLIC;
    } else if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPrivateValue]) {
        newWGUser.privacy = PRIVATE;
    } else {
        newWGUser.privacy = OTHER;
    }
    
    newWGUser.isFollower =              [json st_boolForKey:kIsFollowerKey];
    newWGUser.numFollowing =            [json st_integerForKey:kNumFollowingKey];
    newWGUser.isTapped =                [json st_boolForKey:kIsTappedKey];
    newWGUser.isBlocked =               [json st_boolForKey:kIsBlockedKey];
    newWGUser.isBlocking =              [json st_boolForKey:kIsBlockingKey];
    newWGUser.bio =                     [json st_stringForKey:kBioKey];
    newWGUser.image =                   [json st_stringForKey:kImageKey];
    newWGUser.created =                 [json st_dateForKey:kCreatedKey];
    newWGUser.isFollowing =             [json st_boolForKey:kIsFollowingKey];
    newWGUser.lastName =                [json st_stringForKey:kLastNameKey];
    newWGUser.isFollowingRequested =    [json st_boolForKey:kIsFollowingRequestedKey];
    newWGUser.isGoingOut =              [json st_boolForKey:kIsGoingOutKey];
    newWGUser.properties =              [json st_dictionaryForKey:kPropertiesKey];
    newWGUser.isFavorite =              [json st_boolForKey:kIsFavoriteKey];
    newWGUser.firstName =               [json st_stringForKey:kFirstNameKey];
    
    if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderMaleValue]) {
        newWGUser.gender = MALE;
    } else if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderFemaleValue]) {
        newWGUser.gender = FEMALE;
    } else {
        newWGUser.gender = UNKNOWN;
    }
    
    newWGUser.facebookId =              [json st_stringForKey:kFacebookIdKey];
    newWGUser.numFollowers =            [json st_integerForKey:kNumFollowersKey];
    newWGUser.username =                [json st_stringForKey:kUsernameKey];
    newWGUser.isAttending =             [json st_boolForKey:kIsAttendingKey];
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

@end
