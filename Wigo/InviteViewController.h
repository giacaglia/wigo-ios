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
@property (nonatomic, assign) BOOL isSearching;
@end

#define kTapCellName @"tapCellName"
#define kSectionTapCell 0
#define kFollowCellName @"followCellName"
#define kSectionFollowCell 1
#define kInviteMobileCellName @"inviteCellName"
#define kSectionMobileCell 2
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