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

+ (Party *)everyoneParty;
+ (void)setEveryoneParty:(Party *)newEveryoneParty;

+ (UIImage *)getProfileImage;
+ (BOOL)isGoingOut;
+ (void)setIsGoingOut:(BOOL)varIsGoingOut;


@end
