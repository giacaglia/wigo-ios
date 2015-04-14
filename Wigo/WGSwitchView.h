//
//  WGSwitchView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/14/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"

@interface WGSwitchView : UIView
@property (nonatomic, strong) id<WGSwitchDelegate> switchDelegate;
@property (nonatomic, strong) UIView *frontView;
@property (nonatomic, strong) NSString *firstString;
@property (nonatomic, strong) NSString *secondString;
@property (nonatomic, strong) UILabel *firstLabel;
@property (nonatomic, strong) UILabel *secondLabel;
@property (nonatomic, assign) BOOL privacyTurnedOn;
@property (nonatomic, assign) CGFloat firstX;
@property (nonatomic, strong) UIImageView *movingImageView;
@property (nonatomic, assign) BOOL runningAnimation;
- (void)changeToPrivateState:(BOOL)isPrivate;

@end
