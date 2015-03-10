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
    if (user.isCurrentUser) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.tappedLabel.alpha = 0;
        return;
    }
    
    if ([self.delegate userState] == OTHER_SCHOOL_USER_STATE) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.tappedLabel.alpha = 0;
    } else {
        if ([user.isTapped boolValue]) {
            self.inviteButton.hidden = YES;
            self.inviteButton.enabled = NO;
            self.tappedLabel.alpha = 1;
            
        } else {
            self.inviteButton.hidden = NO;
            self.tappedLabel.alpha = 0;
        }
    }
}

- (void) setup {
    self.inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 37, 35 - 17.5, 75, 35)];
    self.inviteButton.backgroundColor = [FontProperties getOrangeColor];
    [self.inviteButton setTitle:@"TAP" forState:UIControlStateNormal];
    [self.inviteButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.inviteButton.titleLabel.font =  [FontProperties scMediumFont:18.0f];
    self.inviteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.borderColor = UIColor.whiteColor.CGColor;
    self.inviteButton.layer.cornerRadius = 7;
    [self.inviteButton addTarget: self action: @selector(inviteTapped) forControlEvents: UIControlEventTouchUpInside];
    [self addSubview:self.inviteButton];
    
    self.tappedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 70.0f)];
    self.tappedLabel.text = @"tapped";
    self.tappedLabel.font = [FontProperties scMediumFont:20];
    self.tappedLabel.textColor = [FontProperties getOrangeColor];
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
                             weakSelf.tappedLabel.textColor = [FontProperties getOrangeColor];
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
