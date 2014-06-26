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


@property NSString *email;
@property UIImage *coverImage;
@property NSString *name;
@property NSArray *images;
@property NSNumber* eventID;
@property NSString *groupName;
@property NSString *bioString;


- (BOOL)isEqualToUser:(User *)otherUser;
- (id)initWithDictionary:(NSDictionary *)otherDictionary;
- (NSString *)key;
- (void)login;
-(void)save;

// NEED TO IMPLEMENT
@property BOOL privacy;
@property BOOL *isFavorite;
@property BOOL isGoingOut;
@property NSString *placeWhereGoingOut;
@property NSMutableArray *listOfFollowers;
@property NSMutableArray *listOfFollowing;
@property NSDictionary *notificationSettings;

@end
