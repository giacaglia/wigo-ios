//
//  UIView+OverlayView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/11/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "OverlayViewController.h"
#import "Globals.h"

@implementation OverlayViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad {
    [self setup];
}

- (void)setup {
//    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
//    self = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40 - 18, 20, 60, 40)];
    UIImageView *closeButtonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 10, 24, 24)];
    closeButtonImageView.image = [UIImage imageNamed:@"blueCloseButton"];
    [closeButton addSubview:closeButtonImageView];
    [closeButton addTarget:self action:@selector(closeOverlay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    UILabel *eventOnlyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, self.view.frame.size.width, 20)];
    eventOnlyLabel.center = CGPointMake(self.view.center.x, self.view.center.y - 10 - 25 - 10);
    eventOnlyLabel.text = @"This event is invite-only";
    eventOnlyLabel.font = [FontProperties semiboldFont:18];
    eventOnlyLabel.textColor = [FontProperties getBlueColor];
    eventOnlyLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:eventOnlyLabel];
    
    self.privateSwitch = [[PrivateSwitchView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 120, self.view.frame.size.height/2, 240, 40)];
    self.privateSwitch.center = CGPointMake(self.privateSwitch.center.x, self.view.center.y + 10 + 25 + 20);
    self.privateSwitch.privateDelegate = self;
    [self.view addSubview:self.privateSwitch];
    
    self.explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2 - 32, self.view.frame.size.width, 40)];
   
    self.explanationLabel.center = self.view.center;
    self.explanationLabel.font = [FontProperties mediumFont:15];
    self.explanationLabel.textColor = [FontProperties getBlueColor];
    self.explanationLabel.textAlignment = NSTextAlignmentCenter;
    self.explanationLabel.numberOfLines = 0;
    self.explanationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.explanationLabel];
    
    self.lockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 12, self.view.frame.size.height/2 + 66, 24, 32)];
    self.lockImageView.image = [UIImage imageNamed:@"lockImage"];
    [self.view addSubview:self.lockImageView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.privateSwitch.openLockImageView stopAnimating];
    [self.privateSwitch.closeLockImageView stopAnimating];
    self.privateSwitch.privateString = @"Only the creator can invite people and only\nthose invited can see the event.";
    self.privateSwitch.publicString =  @"Everyone around you can see and\nattend your event.";
    self.explanationLabel.text = self.privateSwitch.privateString;
}

- (void)closeOverlay {
    if ([self.event.owner isEqual:WGProfile.currentUser]) {
        self.event.isPrivate = self.privateSwitch.privacyTurnedOn;
        if (!self.privateSwitch.privacyTurnedOn) {
            [self.event setPrivacyOn:NO andHandler:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] logError:error forAction:WGActionSave];
                    return;
                }
            }];
        }
    }

    [self dismissViewControllerAnimated:NO completion:nil];
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
    [self.privateSwitch changeToPrivateState:event.isPrivate];

}


- (void)updateUnderliningText {
    self.explanationLabel.text = self.privateSwitch.explanationString;
}

@end
