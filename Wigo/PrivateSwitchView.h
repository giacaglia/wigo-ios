//
//  PrivateSwitchView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/16/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"
#import "FLAnimatedImageView.h"
#import "Delegate.h"

@interface PrivateSwitchView : UIView
@property (nonatomic, strong) id<PrivacySwitchDelegate> privateDelegate;
@property (nonatomic, strong) UIView *frontView;
@property (nonatomic, strong) NSString *privateString;
@property (nonatomic, strong) NSString *publicString;
@property (nonatomic, strong) NSString *explanationString;
@property (nonatomic, strong) UILabel *publicLabel;
@property (nonatomic, strong) UILabel *privateLabel;
@property (nonatomic, assign) BOOL privacyTurnedOn;
@property (nonatomic, assign) CGFloat firstX;
@property (nonatomic, strong) UIImageView *movingImageView;
@property (nonatomic, strong) FLAnimatedImageView *closeLockImageView;
@property (nonatomic, strong) FLAnimatedImageView *openLockImageView;
@property (nonatomic, assign) BOOL runningAnimation;
- (void)changeToPrivateState:(BOOL)isPrivate;
@end
