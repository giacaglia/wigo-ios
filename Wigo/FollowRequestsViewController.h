//
//  FollowRequestsViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FancyProfileViewController.h"

@interface FollowRequestsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property FancyProfileViewController *profileViewController;

@end
