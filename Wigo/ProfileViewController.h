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
#import "ImageScrollView.h"
#import "Delegate.h"

@interface ProfileViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, InviteCellDelegate>

-(id)initWithUser:(WGUser *)user;
@property (nonatomic, strong) WGUser *user;
@property State userState;

@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, assign) BOOL isFetchingNotifications;
@property (nonatomic, strong) WGCollection *events;
@property (nonatomic, strong) UILabel *numberOfFollowersLabel;
@property (nonatomic, strong) UILabel *numberOfFollowingLabel;
@property (nonatomic, strong) WGCollection *unexpiredNotifications;
@property (nonatomic, strong) WGCollection *notifications;
@property (nonatomic, assign) BOOL isPeeking;
@property (nonatomic, strong) ImageScrollView *imageScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@end


#define kSummaryCellName @"summaryCellName"
@interface SummaryCell : UITableViewCell
@property (nonatomic, strong) UILabel *numberOfRequestsLabel;
@end

#define kNotificationCellName @"notificationCellName"
@interface NotificationCell : UITableViewCell
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, assign) BOOL isTapped;
@property (nonatomic, strong) UILabel *tapLabel;
@property (nonatomic, strong) UIImageView *rightPostImageView;
@property (nonatomic, strong) WGNotification *notification;
@end


@interface GoOutsCell: UITableViewCell
- (void) setLabelsForUser: (WGUser *) user;
+ (CGFloat) rowHeight;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@end

#define kInstaCellName @"instaCellName"
@interface InstaCell : UITableViewCell
+ (CGFloat) rowHeight;
@property (nonatomic, strong) UILabel *instaLabel;
- (void) setLabelForUser: (WGUser *) user;
- (BOOL)hasInstaTextForUser:(WGUser *)user;
@end

@interface InviteCell: UITableViewCell
- (void) setLabelsForUser: (WGUser *) user;
@property (nonatomic, assign) id<InviteCellDelegate> delegate;
+ (CGFloat) rowHeight;
@property (nonatomic, strong) IBOutlet UIButton *inviteButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tappedLabel;

@end
