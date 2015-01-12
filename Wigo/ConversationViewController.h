//
//  ConversationViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGUser.h"

@interface ConversationViewController : UIViewController  <UITextViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
- (id)initWithUser: (WGUser *)user;

@end