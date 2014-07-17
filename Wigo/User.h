//
//  User.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Query.h"

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
@property BOOL private;
@property BOOL isGoingOut;
@property BOOL emailValidated;
@property BOOL isFavorite;
@property BOOL isFollowing;

- (BOOL)isEqualToUser:(User *)otherUser;
- (id)initWithDictionary:(NSDictionary *)otherDictionary;
- (NSString *)login;
- (NSString *)signUp;
- (void)save;
- (void)saveKey:(NSString *)key;
- (void)loadImagesWithCallback:(void (^)(NSArray *imagesReturned))callback;
- (NSString *)fullName;
- (void)addImageURL:(NSString *)imageURL;
- (NSString *)removeImageURL:(NSString *)imageURL;
- (NSString *)coverImageURL;
- (void)makeImageURLCover:(NSString *)imageURL;
- (NSDictionary *)dictionary;
- (BOOL)isTapped;

// NEED TO IMPLEMENT
@property NSString *placeWhereGoingOut;
@property NSMutableArray *listOfFollowers;
@property NSMutableArray *listOfFollowing;
@property NSDictionary *notificationSettings;

@end
