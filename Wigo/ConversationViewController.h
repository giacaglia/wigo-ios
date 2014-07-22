//
//  ConversationViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface ConversationViewController : UIViewController  <UITextViewDelegate>

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
- (id)initWithUser: (User *)user;
@end