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
<JSQMessagesCollectionViewDataSource, JSQMessagesCollectionViewDelegateFlowLayout>

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;

@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) WGCollection *messages;
@property (nonatomic, strong) UIView *viewForEmptyConversation;
@property (nonatomic, assign) BOOL isFetching;


@end
