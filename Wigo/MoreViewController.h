//
//  MoreViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGUser.h"
#import "Delegate.h"

@interface MoreViewController : UIViewController
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, assign) id <ProfileDelegate> profileDelegate;

@end
