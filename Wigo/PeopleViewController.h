//
//  PeopleViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGUser.h"
#import "Delegate.h"

@interface PeopleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, PeopleViewDelegate>

- (id)initWithUser:(WGUser *)user andTab:(NSNumber *)tab;
- (id)initWithUser:(WGUser *)user;
- (void)presentUser:(WGUser *)user;
- (void)updateButton:(id)sender withUser:(WGUser *)user;
@property (nonatomic, strong) UIBarButtonItem *sidebarButton;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, assign) int tabNumber;
@property (nonatomic, strong) NSNumber *currentTab;
@property (nonatomic, strong) UITableView *tableViewOfPeople;

@property (nonatomic, strong) WGCollection *everyone;
@property (nonatomic, strong) WGCollection *users;
@property (nonatomic, strong) WGCollection *suggestions;
@property (nonatomic, strong) WGCollection *following;
@property (nonatomic, strong) WGCollection *followers;
@property (nonatomic, assign) BOOL fetching;

@end

#define kPeopleCellName @"PeopleCellName"
@interface PeopleCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIButton *profileButton;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *goingOutLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *followPersonButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinnerView;
- (void)setStateForUser:(WGUser *)user;
@end

#define kSuggestedFriendsCellName @"SuggestedFriendsCellName"
@interface SuggestedCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) id<PeopleViewDelegate> peopleViewDelegate;
@property (nonatomic, strong) WGCollection *suggestions;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UILabel *contextLabel;
@property (nonatomic, strong) UIScrollView *suggestedScrollView;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UILabel *inviteMoreFriendsLabel;
- (void)setStateForCollection:(WGCollection *)collection;
@end

#define kInvitePeopleCellName @"InvitePeopleCellName"
@interface InvitePeopleCell : UITableViewCell
@property (nonatomic, strong) UILabel *lateToThePartyLabel;
@property (nonatomic, strong) UIButton *inviteButton;
@end