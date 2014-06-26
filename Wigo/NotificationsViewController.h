//
//  NotificationsViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"
#import "ConversationViewController.h"

@interface NotificationsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property ProfileViewController *profileViewController;
@property ConversationViewController *conversationViewController;

@end
