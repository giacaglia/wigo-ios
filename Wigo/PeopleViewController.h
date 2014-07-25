//
//  PeopleViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "WigoSearchBarDelegate.h"

@interface PeopleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WigoSearchBarDelegate>

-(id)initWithUser:(User *)user;

@property (nonatomic) UIBarButtonItem *sidebarButton;
@property User *user;
@property int tabNumber;


@end
