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
#import "EditProfileViewController.h"
#import "MoreViewController.h"
#import "PeopleViewController.h"
#import "ConversationViewController.h"

@protocol InviteCellDelegate
- (void) inviteTapped;
@property STATE userState;
@end

@interface FancyProfileViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, InviteCellDelegate>

@property EditProfileViewController *editProfileViewController;
@property ConversationViewController *conversationViewController;
@property PeopleViewController *peopleViewController;
@property MoreViewController *moreViewController;

@property User *user;
@property STATE userState;

@property (nonatomic, assign) BOOL isFetchingNotifications;
@property (nonatomic, strong) Party *eventsParty;

-(id)initWithUser:(User *)user;
- (void) setStateWithUser: (User *) user;

@end


#define kSummaryCellName @"summaryCellName"
@interface SummaryCell : UITableViewCell
@property (nonatomic, strong) UILabel *numberOfRequestsLabel;
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


@interface GoOutsCell: UITableViewCell
- (void) setLabelsForUser: (User *) user;
+ (CGFloat) rowHeight;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@end



@interface InviteCell: UITableViewCell
- (void) setLabelsForUser: (User *) user;
@property (nonatomic, assign) id<InviteCellDelegate> delegate;
+ (CGFloat) rowHeight;
@property (nonatomic, strong) IBOutlet UIButton *inviteButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tappedLabel;

@end
