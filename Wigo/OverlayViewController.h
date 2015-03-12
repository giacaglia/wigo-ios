//
//  UIView+OverlayView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/11/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PrivateSwitchView.h"

@interface OverlayViewController : UIViewController

@property (nonatomic, strong) PrivateSwitchView *privateSwitch;
@property (nonatomic, strong) UILabel *explanationLabel;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) UIImageView *lockImageView;
@end
