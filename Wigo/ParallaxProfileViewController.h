//
//  ParallaxProfileViewController.h
//  Wigo
//
//  Created by Alex Grinman on 12/12/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPBParallaxTableViewController.h"
#import "Globals.h"
#import "ReProfileViewController.h"

@interface ParallaxProfileViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property EditProfileViewController *editProfileViewController;
@property ConversationViewController *conversationViewController;
@property PeopleViewController *peopleViewController;
@property MoreViewController *moreViewController;


@property User *user;
@property STATE userState;

@property (nonatomic, assign) BOOL isFetchingNotifications;


-(id)initWithUser:(User *)user;
- (void) setStateWithUser: (User *) user;

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