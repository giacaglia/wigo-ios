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
//#import <LayerKit/LayerKit.h>
//#import "Atlas.h"

@interface ConversationViewController : UIViewController

@property (weak, nonatomic) UIBarButtonItem *sidebarButton;
- (id)initWithUser: (WGUser *)user;
@property (nonatomic, strong) NSOrderedSet *messages;
@property (nonatomic, strong) UIView *viewForEmptyConversation;
@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, assign) BOOL hideNavBar;
@property (nonatomic, strong) UIView *blueBannerView;
@property (nonatomic, strong) WGUser *user;

@end