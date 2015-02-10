//
//  MessageViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGCollection.h"

@interface MessageViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) BOOL isFetchingEveryone;
@property (nonatomic, strong) WGCollection *content;
@property (nonatomic, strong) WGCollection *filteredContent;
@property (nonatomic, strong) UITableView *tableView;

@end
