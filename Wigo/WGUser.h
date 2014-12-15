//
//  WGUser.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"

typedef enum {
    MALE   = 0,
    FEMALE = 1,
    UNKNOWN = 2
} Gender;

@interface WGUser : WGObject

@property NSString* privacy;
@property NSNumber* isFollower;
@property NSNumber* numFollowing;
@property NSNumber* isTapped;
@property NSNumber* isBlocked;
@property NSNumber* isBlocking;
@property NSString* bio;
@property NSString* image;
@property NSDate* created;
@property NSNumber* isFollowing;
@property NSString* lastName;
@property NSNumber* isFollowingRequested;
@property NSNumber* isGoingOut;
@property NSDictionary* properties;
@property NSNumber* isFavorite;
@property NSString* firstName;
@property Gender gender;
@property NSString* facebookId;
@property NSNumber* numFollowers;
@property NSString* username;

@end
