//
//  User.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Query.h"

typedef void (^Handler)();
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
    ATTENDING_EVENT_ACCEPTED_PRIVATE_USER,
    BLOCKED_USER
} STATE;


@interface User : NSMutableDictionary

// Necessary Data
@property NSString *email;
@property NSString *accessToken;

@property NSString *key;
@property NSString *firstName;
@property NSString *lastName;
@property NSString *gender;
@property NSNumber* eventID;
@property NSString *groupName;
@property NSNumber *numberOfGroupMembers;
@property NSString *bioString;
@property NSArray *images;
@property NSArray *imagesURL;
@property NSArray *imagesArea;
@property BOOL isEventOwner;
@property BOOL isPrivate;
@property BOOL isGoingOut;
@property BOOL emailValidated;
@property BOOL isFavorite;
@property BOOL isFollowing;
@property NSNumber *lastNotificationRead;
@property NSNumber *lastMessageRead;
@property NSNumber *lastUserRead;
@property BOOL isFollowingRequested;
@property BOOL isTapped;
@property BOOL isTapPushNotificationEnabled;
@property BOOL isFavoritesGoingOutNotificationEnabled;
@property BOOL isBlocked;
@property NSString *attendingEventName;
@property BOOL isAttending;
- (NSString *)fullName;
- (NSString  *)joinedDate;
- (BOOL)isEqualToUser:(User *)otherUser;
- (id)initWithDictionary:(NSDictionary *)otherDictionary;
- (NSNumber *)numEvents;
- (NSDictionary *)dictionary;

// Images
- (void)setGrowthHackPresented;
- (void)addImageDictionary:(NSDictionary *)imageDictionary;
- (void)addImageURL:(NSString *)imageURL;
- (void)addImageWithURL:(NSString *)imageURL andArea:(CGRect)area;
- (NSString *)removeImageURL:(NSString *)imageURL;
- (NSString *)smallImageURL;
- (NSString *)coverImageURL;
- (NSDictionary *)coverImageArea;
- (void)makeImageURLCover:(NSString *)imageURL;


- (NSNumber *)numberOfFollowing;
- (NSNumber *)numberOfFollowers;

//Attending event
@property NSNumber *attendingEventID;
- (BOOL)isGroupLocked;

- (STATE)getUserState;

#pragma mark - Saving data
- (NSString *)login;
- (NSString *)signUp;
- (void)save;
- (void)saveKey:(NSString *)key;
- (void)loginWithHandler:(QueryResult)handler;
- (void)saveKeyAsynchronously:(NSString *)key;
- (void)saveKeyAsynchronously:(NSString *)key withHandler:(Handler)handler;

#pragma mark - analytics
- (void) updateUserAnalytics;
@end
