//
//  User.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Query.h"

typedef enum userStates
{
    PROFILE,
    NOT_FOLLOWING_PUBLIC_USER,
    FOLLOWING_USER,
    NOT_SENT_FOLLOWING_PRIVATE_USER,
    NOT_YET_ACCEPTED_PRIVATE_USER,
    ACCEPTED_PRIVATE_USER,
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
@property NSString *bioString;
@property NSArray *imagesURL;
@property BOOL isPrivate;
@property BOOL isGoingOut;
@property BOOL emailValidated;
@property BOOL isFavorite;
@property BOOL isFollowing;
@property NSNumber *lastNotificationRead;
@property NSNumber *lastMessageRead;

- (BOOL)isEqualToUser:(User *)otherUser;
- (id)initWithDictionary:(NSDictionary *)otherDictionary;
- (void)loadImagesWithCallback:(void (^)(NSArray *imagesReturned))callback;
- (NSString *)fullName;
- (void)addImageURL:(NSString *)imageURL;
- (NSString *)removeImageURL:(NSString *)imageURL;
- (NSString *)coverImageURL;
- (void)makeImageURLCover:(NSString *)imageURL;
- (NSDictionary *)dictionary;
- (BOOL)isTapped;
- (BOOL)isFollowingRequested;
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


@end
