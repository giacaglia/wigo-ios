//
//  MessageViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGCollection.h"
#import "WGMessage.h"

@interface MessageViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign) BOOL isFetchingEveryone;
@property (nonatomic, strong) WGCollection *allFriends;
@property (nonatomic, strong) WGCollection *content;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL isSearching;
@end

#define kMessageCellName @"MessageCellNAme"
@interface MessageCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) WGUser *user;
@end