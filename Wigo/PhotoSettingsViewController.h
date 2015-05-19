//
//  PhotoSettingsViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/19/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEventMessage.h"

@interface PhotoSettingsViewController : UIViewController

@property (nonatomic, strong) WGEventMessage *eventMsg;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *grayView;
@end
