//
//  Profile.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Party.h"

@interface Profile : NSObject

+ (User *) user;
+ (void)setUser:(User *)newUser;

+ (void)setLastUserJoined:(NSNumber *)lastUserJoined;
+ (NSNumber *)lastUserJoined;

+ (Party *)followingParty;
+ (void)setFollowingParty:(Party *)newFollowingParty;
+ (Party *)notAcceptedFollowingParty;
+ (void)setNotAcceptedFollowingParty:(Party *)notAcceptedFollowingParty;
+ (BOOL)isUserDictionaryProfileUser:(NSDictionary *)userDictionary;

+ (BOOL) googleAnalyticsEnabled;
+ (void) setGoogleAnalyticsEnabled:(BOOL)enabled;
+ (NSString *)awsKey;
+ (NSString *)cdnPrefix;
+ (void)setCDNPrefix:(NSString *)newCdnPrefix;

@end
