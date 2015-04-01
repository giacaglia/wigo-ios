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
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) NSNumber *currentTab;
@property (nonatomic, strong) UITableView *tableViewOfPeople;

@property (nonatomic, strong) WGCollection *everyone;
@property (nonatomic, strong) WGCollection *users;
@property (nonatomic, strong) WGCollection *suggestions;
@property (nonatomic, strong) WGCollection *following;
@property (nonatomic, strong) WGCollection *followers;
@property (nonatomic, strong) WGCollection *filteredUsers;
@property (nonatomic, assign) BOOL fetching;
@end

@interface TablePersonCell : UITableViewCell
+ (CGFloat) height;
- (void)setup;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIButton *profileButton;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *mutualFriendsLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinnerView;
@property (nonatomic, strong) WGUser *user;
@end

#define kSectionPeople 1
#define kPeopleCellName @"PeopleCellName"
@interface PeopleCell : TablePersonCell
@property (nonatomic, strong) UIButton *followPersonButton;
@end

#define kSectionFollowPeople 0
#define kFollowPeopleCell @"FollowPeopleCell"
@interface FollowPeopleCell : TablePersonCell
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIButton *rejectButton;
@end
