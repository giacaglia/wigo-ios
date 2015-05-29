//
//  NSObject+GroupConversationViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/6/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Delegate.h"
#import "WGEvent.h"

@interface GroupConversationViewController : JSQMessagesViewController
<JSQMessagesCollectionViewDataSource, JSQMessagesCollectionViewDelegateFlowLayout,
    UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) WGCollection *messages;
@property (nonatomic, strong) UIView *viewForEmptyConversation;
@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, strong) UIView *blueBannerView;

#pragma mark - Tagging table view
@property (nonatomic, strong) UITableView *tagTableView;
@property (nonatomic, strong) WGCollection *tagPeopleUsers;

@property (nonatomic, assign) CGRect positionOfKeyboard;
@property (nonatomic, strong) NSMutableArray *tagUserArray;
@property (nonatomic, strong) NSNumber *position;
@property (nonatomic, strong) NSMutableArray *positionArray;
@end


#define kTagPeopleCellName @"tagPeopleCellName"
@interface TagPeopleCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) WGUser *user;
@end