//
//  PrivateSwitchView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/16/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "PrivateSwitchView.h"
#import "Globals.h"

@implementation PrivateSwitchView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.borderColor = [FontProperties getBlueColor].CGColor;
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 20.0f;
    
    self.frontView = [[UIView alloc] initWithFrame:CGRectMake(4, 2, self.frame.size.width/2 + 15, self.frame.size.height - 4)];
    self.frontView.backgroundColor = [FontProperties getBlueColor];
    self.frontView.layer.borderColor = UIColor.clearColor.CGColor;
    self.frontView.layer.borderWidth = 1.0f;
    self.frontView.layer.cornerRadius = 15.0f;
    [self addSubview:self.frontView];
    
    self.publicLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frontView.frame.size.width - 20, self.frontView.frame.size.height)];
    self.publicLabel.text = @"Public";
    self.publicLabel.textAlignment = NSTextAlignmentCenter;
    self.publicLabel.textColor = UIColor.whiteColor;
    self.publicLabel.font = [FontProperties mediumFont:15.0f];
    [self addSubview:self.publicLabel];
    [self bringSubviewToFront:self.publicLabel];
    
    self.inviteOnlyLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 20, 0, self.frame.size.width/2 - 20, self.frame.size.height)];
    self.inviteOnlyLabel.text = @"Invite Only";
    self.inviteOnlyLabel.textColor = [FontProperties getBlueColor];
    self.inviteOnlyLabel.font = [FontProperties mediumFont:15.0f];
    self.inviteOnlyLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.inviteOnlyLabel];
    [self bringSubviewToFront:self.inviteOnlyLabel];
    
    self.frontImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 6, self.frame.size.height/2 - 8, 12, 16)];
    self.frontImageView.image = [UIImage imageNamed:@"unlocked"];
    [self addSubview:self.frontImageView];
    [self bringSubviewToFront:self.frontImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(privacyPressed)];
    [self addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self.frontView addGestureRecognizer:panRecognizer];
}


-(void)move:(id)sender {
    [self bringSubviewToFront:[(UIPanGestureRecognizer*)sender view]];
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.frontView];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        self.firstX = [sender view].center.x;
    }
    
    translatedPoint = CGPointMake(self.firstX+translatedPoint.x, [sender view].center.y);
    translatedPoint = CGPointMake(MIN(MAX((self.center.x)/2 ,translatedPoint.x), self.center.x), translatedPoint.y);
    [[sender view] setCenter:translatedPoint];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[(UIPanGestureRecognizer*)sender velocityInView:self.frontView].x);
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView commitAnimations];
    }
}


- (void)privacyPressed {
    if (!self.privacyTurnedOn) {
        [UIView animateWithDuration:0.3 animations:^{
            self.publicLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.publicLabel.textColor = [FontProperties getBlueColor];
            self.publicLabel.alpha = 1.0f;
        }];
        [UIView animateWithDuration:0.7 animations:^{
            self.frontView.transform = CGAffineTransformMakeTranslation(self.frame.size.width/2 - 15 - 4 - 4, 0);
        }];
        [UIView animateWithDuration:0.34 animations:^{
            self.inviteOnlyLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.inviteOnlyLabel.textColor = UIColor.whiteColor;
            self.inviteOnlyLabel.alpha = 1.0f;
        }];
        
        self.frontImageView.image = [UIImage imageNamed:@"lockClosed"];
        self.privacyTurnedOn = YES;
        self.invitePeopleLabel.text = @"Only you can invite people and only\nthose invited can see the event.";
    }
    else {
        [UIView animateWithDuration:0.3 animations:^{
            self.inviteOnlyLabel.alpha = 0;
        } completion:^(BOOL finished) {
            self.inviteOnlyLabel.textColor = [FontProperties getBlueColor];
            self.inviteOnlyLabel.alpha = 1.0f;
        }];
        [UIView animateWithDuration:0.7 animations:^{
            self.frontView.transform = CGAffineTransformMakeTranslation(0, 0);
        }];
        [UIView animateWithDuration:0.34 animations:^{
            self.publicLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.publicLabel.textColor = UIColor.whiteColor;
            self.publicLabel.alpha = 1.0f;
        }];
        
        self.frontImageView.image = [UIImage imageNamed:@"unlocked"];
        self.privacyTurnedOn = NO;
        self.invitePeopleLabel.text = @"The whole school can see what you are posting.";
    }
}

@end
