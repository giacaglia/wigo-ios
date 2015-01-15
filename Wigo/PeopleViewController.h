//
//  PeopleViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGUser.h"

@interface PeopleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

- (id)initWithUser:(WGUser *)user andTab:(NSNumber *)tab;
- (id)initWithUser:(WGUser *)user;

@property (nonatomic, strong) UIBarButtonItem *sidebarButton;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, assign) int tabNumber;
@property (nonatomic, strong) NSNumber *currentTab;
@property (nonatomic, strong) UITableView *tableViewOfPeople;


@end
