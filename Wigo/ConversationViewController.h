//
//  ConversationViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"
#import "WGUser.h"

@interface ConversationViewController : JSQMessagesViewController <JSQMessagesCollectionViewDataSource, JSQMessagesCollectionViewDelegateFlowLayout>

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
- (id)initWithUser: (WGUser *)user;
@property (nonatomic, strong) WGCollection *messages;
@property (nonatomic, strong) UIView *viewForEmptyConversation;
@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, assign) BOOL hideNavBar;
@property (nonatomic, strong) UIView *blueBannerView;

@end