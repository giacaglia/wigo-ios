//
//  OnboardFollowViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 8/11/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEvent.h"

@interface OnboardFollowViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableViewOfPeople;
@property (nonatomic, strong) WGCollection *users;
@property (nonatomic, strong) WGCollection *filteredUsers;
@end

#define kOnboardCellName @"OnboardCellName"
@interface OnboardCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *labelName;
@property (nonatomic, strong) UIButton *followPersonButton;
@end

