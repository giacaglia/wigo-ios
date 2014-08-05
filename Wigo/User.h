//
//  User.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Query.h"

typedef enum
{
    PRIVATE_PROFILE,
    PUBLIC_PROFILE,
    NOT_FOLLOWING_PUBLIC_USER,
    FOLLOWING_USER,
    ATTENDING_EVENT_FOLLOWING_USER,
    NOT_SENT_FOLLOWING_PRIVATE_USER,
    NOT_YET_ACCEPTED_PRIVATE_USER,
    ACCEPTED_PRIVATE_USER,
    ATTENDING_EVENT_ACCEPTED_PRIVATE_USER
} STATE;


@interface User : NSMutableDictionary

// Necessary Data
@property NSString *email;
@property NSString *accessToken;

@property NSString *key;
@property NSString *firstName;
@property NSString *lastName;
@property NSNumber* eventID;
@property NSString *groupName;
@property NSNumber *numberOfGroupMembers;
@property NSString *bioString;
@property NSArray *imagesURL;
@property BOOL isPrivate;
@property BOOL isGoingOut;
@property BOOL emailValidated;
@property BOOL isFavorite;
@property BOOL isFollowing;
@property NSNumber *lastNotificationRead;
@property NSNumber *lastMessageRead;
@property NSNumber *lastUserRead;

- (NSString *)fullName;


- (BOOL)isEqualToUser:(User *)otherUser;
- (id)initWithDictionary:(NSDictionary *)otherDictionary;

- (NSDictionary *)dictionary;

// Images
- (void)addImageURL:(NSString *)imageURL;
- (NSString *)removeImageURL:(NSString *)imageURL;
- (NSString *)coverImageURL;
- (void)makeImageURLCover:(NSString *)imageURL;

- (BOOL)isTapped;
- (BOOL)isFollowingRequested;
- (BOOL)isAttending;
//Attending event
- (NSString *)attendingEventName;
@property NSNumber *attendingEventID;
- (BOOL)isGroupLocked;


- (STATE)getUserState;

// NEED TO IMPLEMENT
@property NSString *placeWhereGoingOut;
@property NSDictionary *notificationSettings;

#pragma mark - Saving data
- (NSString *)login;
- (NSString *)signUp;
- (void)save;
- (void)saveKey:(NSString *)key;
- (void)loginWithHandler:(QueryResult)handler;

- (void)saveKeyAsynchronously:(NSString *)key;
@end
