//
//  PeopleViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface PeopleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

- (id)initWithUser:(User *)user andTab:(NSNumber *)tab;
- (id)initWithUser:(User *)user;

@property (nonatomic) UIBarButtonItem *sidebarButton;
@property User *user;
@property int tabNumber;
@property (nonatomic, strong) NSNumber *currentTab;

@end
