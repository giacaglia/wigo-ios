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


#define kChatCellName @"ChatCellName"
@interface ChatCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *lastMessageLabel;
@property (nonatomic, strong) UIImageView *lastMessageImageView;
@end