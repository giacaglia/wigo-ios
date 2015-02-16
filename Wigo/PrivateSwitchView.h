//
//  PrivateSwitchView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/16/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PrivateSwitchView : UIView
@property (nonatomic, strong) UIView *frontView;
@property (nonatomic, strong) UILabel *invitePeopleLabel;
@property (nonatomic, strong) UILabel *publicLabel;
@property (nonatomic, strong) UILabel *inviteOnlyLabel;
@property (nonatomic, strong) UIImageView *frontImageView;
@property (nonatomic, assign) BOOL privacyTurnedOn;
@property (nonatomic, assign) CGFloat firstX;
@end
