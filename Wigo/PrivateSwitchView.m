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
    self.layer.cornerRadius = 22.0f;
    
    self.frontView = [[UIView alloc] initWithFrame:CGRectMake(2, 2, self.frame.size.width/2 + 15, self.frame.size.height - 4)];
    self.frontView.backgroundColor = [FontProperties getBlueColor];
    self.frontView.layer.borderColor = UIColor.clearColor.CGColor;
    self.frontView.layer.borderWidth = 1.0f;
    self.frontView.layer.cornerRadius = 20.0f;
    [self addSubview:self.frontView];
    
    self.publicLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.frontView.frame.size.width - 10, self.frontView.frame.size.height)];
    self.publicLabel.text = @"Public";
    self.publicLabel.textAlignment = NSTextAlignmentCenter;
    self.publicLabel.textColor = UIColor.whiteColor;
    self.publicLabel.font = [FontProperties mediumFont:15.0f];
    [self addSubview:self.publicLabel];
    [self bringSubviewToFront:self.publicLabel];
    
    self.inviteOnlyLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 10, 0, self.frame.size.width/2 - 20, self.frontView.frame.size.height)];
    self.inviteOnlyLabel.text = @"Private";
    self.inviteOnlyLabel.textColor = [FontProperties getBlueColor];
    self.inviteOnlyLabel.font = [FontProperties mediumFont:15.0f];
    self.inviteOnlyLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.inviteOnlyLabel];
    [self bringSubviewToFront:self.inviteOnlyLabel];
    
    FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"closeLock" ofType:@"gif"]]];
    self.closeLockImageView = [[FLAnimatedImageView alloc] init];
    self.closeLockImageView.animatedImage = animatedImage;
    self.closeLockImageView.frame = CGRectMake(self.frame.size.width/2 - 6, self.frame.size.height/2 - 8, 12, 16);
    self.closeLockImageView.animationRepeatCount = 0;
    [self addSubview:self.closeLockImageView];
    
    FLAnimatedImage *openImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"openLock" ofType:@"gif"]]];
    self.openLockImageView = [[FLAnimatedImageView alloc] init];
    self.openLockImageView.animatedImage = openImage;
    self.openLockImageView.frame = CGRectMake(self.frame.size.width/2 - 6, self.frame.size.height/2 - 8, 12, 16);
    self.openLockImageView.hidden = YES;
    self.openLockImageView.animationRepeatCount = 0;
    [self addSubview:self.openLockImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(privacyPressed)];
    [self addGestureRecognizer:tapGesture];
    
//    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
//    [panRecognizer setMinimumNumberOfTouches:1];
//    [panRecognizer setMaximumNumberOfTouches:1];
//    [self.frontView addGestureRecognizer:panRecognizer];
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
    CGFloat percentage = 2*((translatedPoint.x - self.center.x/2)/self.center.x);
    NSLog(@"percentage = %f", percentage);
    self.closeLockImageView.alpha = percentage;
    [UIView animateWithDuration:0.84 animations:^{
        self.frontView.transform = CGAffineTransformMakeTranslation(self.frame.size.width/2 - 15 - 2 - 2, 0);
    }   completion:^(BOOL finished) {
        [self.closeLockImageView stopAnimating];
    }];
}


- (void)privacyPressed {
    if (!self.runningAnimation) {
        self.runningAnimation = YES;
        if (!self.privacyTurnedOn) {
            self.openLockImageView.currentFrameIndex = 29;
            self.closeLockImageView.animationRepeatCount = 1;
            self.closeLockImageView.animationDuration = 0.84;
            self.closeLockImageView.currentFrameIndex = 0;
            self.openLockImageView.hidden = YES;
            self.closeLockImageView.hidden = NO;
            [self.closeLockImageView startAnimating];
            
            [UIView animateWithDuration:0.3 animations:^{
                self.publicLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.publicLabel.textColor = [FontProperties getBlueColor];
                self.publicLabel.alpha = 1.0f;
            }];
            [UIView animateWithDuration:0.84 animations:^{
                self.frontView.transform = CGAffineTransformMakeTranslation(self.frame.size.width/2 - 15 - 2 - 2, 0);
            }
            completion:^(BOOL finished) {
                [self.closeLockImageView stopAnimating];
                self.runningAnimation = NO;
             }];
            [UIView animateWithDuration:0.34 animations:^{
                self.inviteOnlyLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.inviteOnlyLabel.textColor = UIColor.whiteColor;
                self.inviteOnlyLabel.alpha = 1.0f;
            }];
            
            self.privacyTurnedOn = YES;
            self.invitePeopleLabel.text = @"Only you can invite people and only\nthose invited can see the event.";
        }
        else {
            self.openLockImageView.animationRepeatCount = 1;
            self.openLockImageView.animationDuration = 0.84;
            self.openLockImageView.currentFrameIndex = 0;
            self.closeLockImageView.hidden = YES;
            self.openLockImageView.hidden = NO;
            [self.openLockImageView startAnimating];
            [UIView animateWithDuration:0.3 animations:^{
                self.inviteOnlyLabel.alpha = 0;
            } completion:^(BOOL finished) {
                self.inviteOnlyLabel.textColor = [FontProperties getBlueColor];
                self.inviteOnlyLabel.alpha = 1.0f;
            }];
            [UIView animateWithDuration:0.84 animations:^{
                self.frontView.transform = CGAffineTransformMakeTranslation(0, 0);
            } completion:^(BOOL finished) {
                self.runningAnimation = NO;
                [self.openLockImageView stopAnimating];
            }];
            [UIView animateWithDuration:0.34 animations:^{
                self.publicLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.publicLabel.textColor = UIColor.whiteColor;
                self.publicLabel.alpha = 1.0f;
            }];
            //
            self.privacyTurnedOn = NO;
            self.invitePeopleLabel.text = @"The whole school can see what you are posting.";
        }
    }
 
}

@end
