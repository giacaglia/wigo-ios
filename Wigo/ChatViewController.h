//
//  ChatViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"


@interface ChatViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UITableView *tableViewOfPeople;
@property (nonatomic, strong) WGCollection *messages;
@property (nonatomic, assign) BOOL isFetching;
@end


#define kChatCellName @"ChatCellName"
@interface ChatCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *lastMessageLabel;
@property (nonatomic, strong) WGMessage *message;
@property (nonatomic, strong) UIView *orangeNewView;
@property (nonatomic, strong) UIImageView *arrowMsgImageView;
@end