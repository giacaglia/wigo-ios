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

+ (CGFloat)height {
    return 70.0f;
}

- (void) setUser:(WGUser *)user {
    _user = user;
    
    if (self.delegate.user.state == OTHER_SCHOOL_USER_STATE) {
//        self.inviteButton.hidden = YES;
//        self.inviteButton.enabled = NO;
//        self.tappedLabel.alpha = 0;
        self.tapButton.hidden = YES;
    }
    if (user.isCurrentUser) {
        self.tapButton.hidden = YES;
        return;
    }
  
    if (user.isTapped.boolValue) {
        self.tapLabel.text = @"TAPPED";
        self.tapImageView.image = [UIImage imageNamed:@"blueTappedImageView"];
    }
    else {
        self.tapLabel.text = @"TAP";
        self.tapImageView.image = [UIImage imageNamed:@"blueTapImageView"];
    }
    //

}

- (void) setup {
    self.tapButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 80)];
    [self.tapButton addTarget:self action:@selector(inviteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.tapButton];
    
    self.tapImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 20, 5, 40, 40)];
    self.tapImageView.image = [UIImage imageNamed:@"blueTapImageView"];
    [self.tapButton addSubview:self.tapImageView];
    
    self.tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 40, 45, 80, 20)];
    self.tapLabel.text = @"TAP";
    self.tapLabel.textAlignment = NSTextAlignmentCenter;
    self.tapLabel.font = [FontProperties mediumFont:14.0f];
    self.tapLabel.textColor = [FontProperties getBlueColor];
    [self.tapButton addSubview:self.tapLabel];
}

- (void) inviteTapped {
    WGUser *user = self.user;
    user.isTapped = @YES;
    self.user = user;
//    self.user.isTapped = @YES;
    [self.delegate inviteTapped];
    //    UIView *orangeBackground = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, 0, self.frame.size.width + 15, self.frame.size.height)];
//    orangeBackground.backgroundColor = self.inviteButton.backgroundColor;
//    orangeBackground.layer.cornerRadius = 8.0f;
//    orangeBackground.layer.borderWidth = 1.0f;
//    orangeBackground.layer.borderColor = UIColor.clearColor.CGColor;
//    [self sendSubviewToBack:orangeBackground];
//    [self addSubview:orangeBackground];
//    self.tappedLabel.textColor = UIColor.whiteColor;
//    self.tappedLabel.alpha = 1;
//    [self bringSubviewToFront:self.tappedLabel];
//    
//    
//    __weak typeof(self) weakSelf = self;
//    [UIView animateWithDuration:0.2f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseIn
//                     animations:^{
//                         self.inviteButton.alpha = 0.0f;
//                         orangeBackground.frame = CGRectMake(-10, 0, self.frame.size.width + 15, self.frame.size.height);
//                         self.tappedLabel.alpha = 1;
//                     } completion:^(BOOL finished) {
//                         [UIView animateWithDuration:0.2f animations:^{
//                             orangeBackground.backgroundColor = RGB(231, 222, 214);
//                             weakSelf.tappedLabel.textColor = [FontProperties getOrangeColor];
//                         } completion:^(BOOL finished) {
//                             [UIView animateWithDuration:0.5f animations:^{
//                                 orangeBackground.alpha = 0.0f;
//                             } completion:^(BOOL finished) {
//                                 if (weakSelf.delegate) {
//                                     [weakSelf.delegate inviteTapped];
//                                 }
//                             }];
//                         }];
//                     }];
}

@end
