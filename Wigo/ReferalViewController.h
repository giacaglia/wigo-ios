//
//  ReferalViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/5/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEvent.h"

@interface ReferalViewController : UIViewController<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableViewOfPeople;
@property (nonatomic, strong) WGCollection *users;
@property (nonatomic, strong) WGCollection *filteredUsers;
@property (nonatomic, strong) NSIndexPath *chosenIndexPath;
@property (nonatomic, assign) BOOL isSearching;
@end


#define kReferalPeopleCellName @"ReferalPeopleCellName"
@interface ReferalPeopleCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *labelName;
@property (nonatomic, strong) UILabel *groupName;
@end

