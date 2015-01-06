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
#import "Party.h"

@interface ReProfileViewController : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

-(id)initWithUser:(User *)user;

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
@property User *user;
@property STATE userState;
@property Party *eventsParty;
@property EditProfileViewController *editProfileViewController;

@property (nonatomic, assign) BOOL isFetchingNotifications;
@end

#define kNotificationCellName_old @"notificationCellName"
@interface NotificationCell_old : UITableViewCell
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) UIButton *buttonCallback;
@property (nonatomic, assign) BOOL isTapped;
@property (nonatomic, strong) UIImageView *tapImageView;
@property (nonatomic, strong) UILabel *tapLabel;
@property (nonatomic, strong) UIImageView *rightPostImageView;
@end