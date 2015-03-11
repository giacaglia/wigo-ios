//
//  UIView+OverlayView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/11/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "OverlayView.h"
#import "Globals.h"

@implementation OverlayView

- (void)setup {
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
//    self = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.alpha = 0.0f;
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 40 - 18, 20, 60, 40)];
    UIImageView *closeButtonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 10, 24, 24)];
    closeButtonImageView.image = [UIImage imageNamed:@"blueCloseButton"];
    [closeButton addSubview:closeButtonImageView];
    [closeButton addTarget:self action:@selector(closeOverlay) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeButton];
    
    UILabel *eventOnlyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, self.frame.size.width, 20)];
    eventOnlyLabel.center = CGPointMake(self.center.x, self.center.y - 10 - 25 - 10);
    eventOnlyLabel.text = @"This event is invite-only";
    eventOnlyLabel.font = [FontProperties semiboldFont:18];
    eventOnlyLabel.textColor = [FontProperties getBlueColor];
    eventOnlyLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:eventOnlyLabel];
    
    self.privateSwitch = [[PrivateSwitchView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 120, self.frame.size.height/2, 240, 40)];
    self.privateSwitch.center = CGPointMake(self.privateSwitch.center.x, self.center.y + 10 + 25 + 20);
    self.privateSwitch.privateDelegate = self;
    [self.privateSwitch changeToPrivateState:YES];
    [self addSubview:self.privateSwitch];
    
    self.explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height/2 - 32, self.frame.size.width, 40)];
   
    self.explanationLabel.center = self.center;
    self.explanationLabel.font = [FontProperties mediumFont:15];
    self.explanationLabel.textColor = [FontProperties getBlueColor];
    self.explanationLabel.textAlignment = NSTextAlignmentCenter;
    self.explanationLabel.numberOfLines = 0;
    self.explanationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:self.explanationLabel];
    
    
    self.lockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 12, self.frame.size.height/2 + 66, 24, 32)];
    self.lockImageView.image = [UIImage imageNamed:@"lockImage"];
    [self addSubview:self.lockImageView];
}

- (void)closeOverlay {
    [UIView animateWithDuration:0.4 animations:^{
        self.alpha = 0.0f;
    }];
    self.event.isPrivate = NO;
    if (!self.privateSwitch.privacyTurnedOn) {
//        _privacyImageView.image = [UIImage imageNamed:@"blueUnlocked"];
        [self.event setPrivacyOn:NO andHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                return;
            }
        }];
    }
}

- (void)setEvent:(WGEvent *)event {
    _event = event;
    self.privateSwitch.hidden = ![event.owner isEqual:WGProfile.currentUser];
    self.lockImageView.hidden = [event.owner isEqual:WGProfile.currentUser];
    if ([event.owner isEqual:WGProfile.currentUser]) {
        self.explanationLabel.text = @"Only people you invite can see the\nevent and what is going on and only you\ncan invite people. You can change the\ntype of the event:";
    }
    else {
        self.explanationLabel.text = @"Only invited people can see whats going on. Only creator can invite people.";
    }

}


- (void)updateUnderliningText {
    self.explanationLabel.text = self.privateSwitch.explanationString;
}

@end
