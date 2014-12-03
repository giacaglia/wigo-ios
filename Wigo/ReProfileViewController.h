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


@interface ReProfileViewController : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

-(id)initWithUser:(User *)user;

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
@property User *user;
@property STATE userState;

@property EditProfileViewController *editProfileViewController;
@property ConversationViewController *conversationViewController;
@property PeopleViewController *peopleViewController;
@property MoreViewController *moreViewController;

@end

#define kNotificationCellName @"notificationCellName"
@interface NotificationCell : UITableViewCell
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) UIButton *buttonCallback;
@property (nonatomic, assign) BOOL isTapped;
@property (nonatomic, strong) UIImageView *tapImageView;
@property (nonatomic, strong) UILabel *tapLabel;
@property (nonatomic, strong) UIImageView *rightPostImageView;
@end