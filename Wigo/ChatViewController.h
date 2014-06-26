//
//  ChatViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConversationViewController.h"
#import "MessageViewController.h"


@interface ChatViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property ConversationViewController *conversationViewController;
@property MessageViewController *messageViewController;

@end