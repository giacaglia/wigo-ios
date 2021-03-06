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
#import "MoreViewController.h"

@interface ProfileViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, InviteCellDelegate, ProfileDelegate, WGViewController>

-(id)initWithUser:(WGUser *)user;
@property (nonatomic, strong) WGUser *user;
@property State userState;

@property (nonatomic, assign) id<EventPeopleModalDelegate>cardsDelegate;
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, assign) BOOL isFetchingNotifications;
@property (nonatomic, strong) WGCollection *events;
@property (nonatomic, strong) UILabel *numberOfFriendsLabel;
@property (nonatomic, strong) UILabel *friendsLabel;
@property (nonatomic, strong) WGCollection *notifications;
@property (nonatomic, assign) BOOL isPeeking;
@property (nonatomic, strong) ImageScrollView *imageScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSDate *lastNotificationRead;
@property (nonatomic, strong) WGCollection *mutualFriends;
@property (nonatomic, strong) MoreViewController *moreVc;
@property (nonatomic, assign) BOOL hideNavBar;

@property (nonatomic) BOOL showStatusBarOnDismiss;

-(void)removeMoreVc;
@end


#define kMutualFriendsCellName @"mutualFriendsCellName"
@interface MutualFriendsCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate>
+ (CGFloat)height;
@property (nonatomic, strong) UILabel *mutualFriendsLabel;
@property (nonatomic, strong) UICollectionView *mutualFriendsCollection;
@property (nonatomic, strong) WGCollection *users;
@end

#define kNotificationCellName @"notificationCellName"
@interface NotificationCell : UITableViewCell
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, assign) BOOL isTapped;
@property (nonatomic, strong) UILabel *tapLabel;
@property (nonatomic, strong) WGNotification *notification;
@property (nonatomic, strong) UIView *orangeNewView;
@property (nonatomic, strong) UIImageView *arrowImageView;
@end

#define kInstaCellName @"instaCellName"
@interface InstaCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) UILabel *instaLabel;
- (BOOL)hasInstaTextForUser:(WGUser *)user;
@end

@interface InviteCell: UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, assign) id<InviteCellDelegate> delegate;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *tapButton;
@property (nonatomic, strong) UIImageView *tapImageView;
@property (nonatomic, strong) UILabel *tapLabel;
@property (nonatomic, strong) UILabel *underlineTapLabel;
@end
