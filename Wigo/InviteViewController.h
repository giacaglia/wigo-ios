//
//  InviteViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEvent.h"

@interface InviteViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

- (id)initWithEvent:(WGEvent *)newEvent;

@property (nonatomic, strong) UITableView *invitePeopleTableView;
@property (nonatomic, strong) WGCollection *content;
@property (nonatomic, strong) WGCollection *filteredContent;
@property (nonatomic, assign) BOOL isSearching;
@end
