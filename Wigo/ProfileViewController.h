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
#import "MoreViewController.h"
#import "User.h"


@interface ProfileViewController : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate>

-(id)initWithProfile:(BOOL)isMyProfile;
-(id)initWithUser:(User *)user;

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
@property User *user;
@property STATE userState;

@property EditProfileViewController *editProfileViewController;
@property ConversationViewController *conversationViewController;
@property PeopleViewController *peopleViewController;
@property MoreViewController *moreViewController;

@end
