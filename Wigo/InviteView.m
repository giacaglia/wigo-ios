//
//  UIView+InviteView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/9/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "InviteView.h"

@implementation InviteView

#define kInviteTitleTemplate @"Tap to see out:"

- (void) awakeFromNib {
    [self setup];
}


+ (CGFloat)rowHeight {
    return 70.0f;
}

- (void) setLabelsForUser: (WGUser *) user {
    if ([user isCurrentUser]) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.titleLabel.hidden = YES;
        self.tappedLabel.alpha = 0;
        return;
    }
    
    if ([self.delegate userState] == OTHER_SCHOOL_USER_STATE) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.titleLabel.hidden = YES;
        self.tappedLabel.alpha = 0;
    } else {
        if ([user.isTapped boolValue]) {
            self.inviteButton.hidden = YES;
            self.inviteButton.enabled = NO;
            self.titleLabel.hidden = YES;
            self.tappedLabel.alpha = 1;
            
        } else {
            self.inviteButton.hidden = NO;
            self.titleLabel.hidden = NO;
            self.titleLabel.text = kInviteTitleTemplate;
            self.tappedLabel.alpha = 0;
        }
    }
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70.0f);
    self.titleLabel.font = [FontProperties lightFont: 18];
    self.titleLabel.textColor = UIColor.lightGrayColor;
    
    self.inviteButton.titleLabel.font =  [FontProperties lightFont:18.0f];
    self.inviteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.borderColor = UIColor.whiteColor.CGColor;
    self.inviteButton.layer.cornerRadius = 7;
    [self.inviteButton addTarget: self action: @selector(inviteTapped) forControlEvents: UIControlEventTouchUpInside];
    
    self.tappedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70.0f)];
    self.tappedLabel.text = @"TAPPED";
    self.tappedLabel.font = [FontProperties lightFont: 24];
    self.tappedLabel.textColor = UIColor.lightGrayColor;
    self.tappedLabel.textAlignment = NSTextAlignmentCenter;
    self.tappedLabel.alpha = 0;
    
    [self addSubview:self.tappedLabel];
}

- (void) inviteTapped {
    self.inviteButton.enabled = NO;
    
    UIView *orangeBackground = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, 0, self.frame.size.width + 15, self.frame.size.height)];
    orangeBackground.backgroundColor = self.inviteButton.backgroundColor;
    orangeBackground.layer.cornerRadius = 8.0f;
    orangeBackground.layer.borderWidth = 1.0f;
    orangeBackground.layer.borderColor = UIColor.clearColor.CGColor;
    [self sendSubviewToBack:orangeBackground];
    [self addSubview:orangeBackground];
    self.titleLabel.hidden = YES;
    self.tappedLabel.textColor = UIColor.whiteColor;
    self.tappedLabel.alpha = 1;
    [self bringSubviewToFront:self.tappedLabel];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.inviteButton.alpha = 0.0f;
                         orangeBackground.frame = CGRectMake(-10, 0, self.frame.size.width + 15, self.frame.size.height);
                         self.tappedLabel.alpha = 1;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2f animations:^{
                             orangeBackground.backgroundColor = RGB(231, 222, 214);
                             weakSelf.tappedLabel.textColor = UIColor.lightGrayColor;
                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.5f animations:^{
                                 orangeBackground.alpha = 0.0f;
                             } completion:^(BOOL finished) {
                                 if (weakSelf.delegate) {
                                     [weakSelf.delegate inviteTapped];
                                 }
                             }];
                         }];
                     }];
}

@end
