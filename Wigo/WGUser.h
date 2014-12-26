//
//  WGUser.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGCollection.h"

#import "WGCollection.h"

typedef enum Gender {
    MALE,
    FEMALE,
    UNKNOWN
} Gender;

typedef enum Privacy {
    PUBLIC,
    PRIVATE,
    OTHER
} Privacy;

typedef enum State {
    PRIVATE_STATE,
    PUBLIC_STATE,
    NOT_FOLLOWING_PUBLIC_USER_STATE,
    FOLLOWING_USER_STATE,
    ATTENDING_EVENT_FOLLOWING_USER_STATE,
    NOT_SENT_FOLLOWING_PRIVATE_USER_STATE,
    NOT_YET_ACCEPTED_PRIVATE_USER_STATE,
    ACCEPTED_PRIVATE_USER_STATE,
    ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE,
    BLOCKED_USER_STATE
} State;

@interface WGUser : WGObject

typedef void (^UserResult)(WGUser *object, NSError *error);

@property NSString* key;
// @property (nonatomic, assign) Privacy privacy;
@property NSString* privacy;
@property NSNumber* isFollower;
@property NSNumber* numFollowing;
@property NSNumber* isTapped;
@property NSNumber* isBlocked;
@property NSNumber* isBlocking;
@property NSString* bio;
@property NSString* image;
@property NSString* created;
@property NSNumber* isFollowing;
@property NSString* lastName;
@property NSNumber* isFollowingRequested;
@property NSNumber* isGoingOut;
@property NSDictionary* properties;
@property NSNumber* isFavorite;
@property NSString* firstName;

// @property (nonatomic, assign) Gender gender;
@property NSString* gender;
@property NSString* email;
@property NSString* facebookId;
@property NSString* facebookAccessToken;
@property NSNumber* numFollowers;
@property NSString* username;
@property NSNumber* isAttending;
@property NSDictionary* group;
@property NSNumber* groupRank;

+ (WGUser *) currentUser;
+ (void) setCurrentUser: (WGUser *) user;

+(WGUser *)serialize:(NSDictionary *)json;

-(State) state;

+ (void)loginWithFacebookId: facebookId facebookAccessToken:facebookAccessToken email:email andHandler:(UserResult)handler;

+(void)getUsers:(CollectionResult)handler;

@end
