//
//  InviteViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEvent.h"
#import "MobileDelegate.h"

@interface InviteViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

- (id)initWithEvent:(WGEvent *)newEvent;

@property (nonatomic, strong) UITableView *invitePeopleTableView;
@property (nonatomic, strong) WGCollection *content;
@property (nonatomic, strong) WGCollection *presentedUsers;
@property (nonatomic, strong) WGCollection *suggestions;
@property (nonatomic, assign) BOOL isSearching;
@end

#define kTapAllName @"tapAllName"
#define kSectionTapAllCell 0
#define kTapCellName @"tapCellName"
#define kSectionTapCell 1
#define kFollowCellName @"followCellName"
#define kSectionFollowCell 2
#define kInviteMobileCellName @"inviteCellName"
#define kSectionMobileCell 3

@interface TapCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *fullNameLabel;
@property (nonatomic, strong) UILabel *goingOutLabel;
@property (nonatomic, strong) UIButton *aroundTapButton;
@property (nonatomic, strong) UIImageView *tapImageView;
- (void)setUser:(WGUser *)user;
- (void)setCellForContactPerson:(ABRecordRef)contactPerson
               withChosenPeople:(NSArray *)chosenPeople;
@end

@interface FollowCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UIButton *profileButton;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *followPersonButton;
- (void)setStateForUser:(WGUser *)user;
@end

@interface TapAllCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UILabel *tapAllLabel;
@property (nonatomic, strong) UIButton *aroundTapButton;
@property (nonatomic, strong) UIImageView *tapImageView;
@property (nonatomic, strong) UILabel *labelUnderButton;
- (void)setStateForEvent:(WGEvent *)event;
@end
