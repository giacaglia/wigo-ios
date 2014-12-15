//
//  WGUser.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGUser.h"

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

#define kGenderMaleValue @"male"
#define kGenderFemaleValue @"female"

@implementation WGUser

+(WGObject *)serialize:(NSDictionary *)json {
    WGUser *newWGUser = (WGUser *)[super serialize:json];
    
    newWGUser.privacy =                 [newWGUser stringAtKey:kPrivacyKey];
    newWGUser.isFollower =              [newWGUser numberAtKey:kIsFollowerKey];
    newWGUser.numFollowing =            [newWGUser numberAtKey:kNumFollowingKey];
    newWGUser.isTapped =                [newWGUser numberAtKey:kIsTappedKey];
    newWGUser.isBlocked =               [newWGUser numberAtKey:kIsBlockedKey];
    newWGUser.isBlocking =              [newWGUser numberAtKey:kIsBlockingKey];
    newWGUser.bio =                     [newWGUser stringAtKey:kBioKey];
    newWGUser.image =                   [newWGUser stringAtKey:kImageKey];
    newWGUser.created =                 [newWGUser dateAtKey:kCreatedKey];
    newWGUser.isFollowing =             [newWGUser numberAtKey:kIsFollowingKey];
    newWGUser.lastName =                [newWGUser stringAtKey:kLastNameKey];
    newWGUser.isFollowingRequested =    [newWGUser numberAtKey:kIsFollowingRequestedKey];
    newWGUser.isGoingOut =              [newWGUser numberAtKey:kIsGoingOutKey];
    newWGUser.properties =              [newWGUser dictionaryAtKey:kPropertiesKey];
    newWGUser.isFavorite =              [newWGUser numberAtKey:kIsFavoriteKey];
    newWGUser.firstName =               [newWGUser stringAtKey:kFirstNameKey];
    
    if ([[newWGUser stringAtKey:kGenderKey] isEqualToString:kGenderMaleValue]) {
        newWGUser.gender = MALE;
    } else if ([[newWGUser stringAtKey:kGenderKey] isEqualToString:kGenderFemaleValue]) {
        newWGUser.gender = FEMALE;
    } else {
        newWGUser.gender = UNKNOWN;
    }
    
    newWGUser.facebookId =              [newWGUser stringAtKey:kFacebookIdKey];
    newWGUser.numFollowers =            [newWGUser numberAtKey:kNumFollowersKey];
    newWGUser.username =                [newWGUser stringAtKey:kUsernameKey];
    
    return newWGUser;
}


@end
