//
//  ProfileViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditProfileViewController.h"
#import "ConversationViewController.h"
#import "PeopleViewController.h"
#import "User.h"

typedef enum playerStateTypes
{
    PROFILE,
    FOLLOWING_USER,
    NOT_FOLLOWING_USER,
    PRIVATE_USER
} STATE;

@interface ProfileViewController : UIViewController <UIScrollViewDelegate>

-(id)initWithProfile:(BOOL)isMyProfile;
-(id)initWithUser:(User *)user;

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
@property User *user;
@property STATE state;

@property EditProfileViewController *editProfileViewController;
@property ConversationViewController *conversationViewController;
@property PeopleViewController *peopleViewController;

@end
