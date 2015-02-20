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
    
    self.frontView = [[UIView alloc] initWithFrame:CGRectMake(2, 2, self.frame.size.width/2 + 15, self.frame.size.height - 4)];
    self.frontView.backgroundColor = [FontProperties getBlueColor];
    self.frontView.layer.borderColor = UIColor.clearColor.CGColor;
    self.frontView.layer.borderWidth = 1.0f;
    self.frontView.layer.cornerRadius = 18.0f;
    [self addSubview:self.frontView];
    
    self.publicLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frontView.frame.size.width - 4, self.frontView.frame.size.height)];
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
    for (int i = 0; i < 28; i++) {
        [self.closeLockImageView.animatedImage imageLazilyCachedAtIndex:i];
    }
    [self addSubview:self.closeLockImageView];
    
    self.movingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 6, self.frame.size.height/2 - 8, 12, 16)];
    self.movingImageView.hidden = YES;
    [self addSubview:self.movingImageView];
    
    FLAnimatedImage *openImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"openLock" ofType:@"gif"]]];
    self.openLockImageView = [[FLAnimatedImageView alloc] init];
    self.openLockImageView.animatedImage = openImage;
    self.openLockImageView.frame = CGRectMake(self.frame.size.width/2 - 6, self.frame.size.height/2 - 8, 12, 16);
    self.openLockImageView.hidden = YES;
    self.openLockImageView.animationRepeatCount = 0;
    [self addSubview:self.openLockImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(privacyPressed)];
    [self addGestureRecognizer:tapGesture];
    self.explanationString = @"The whole school can see what you are posting.";
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
    translatedPoint = CGPointMake(MIN(MAX(self.center.x/2 - 15 ,translatedPoint.x), self.center.x + 15 - 2), translatedPoint.y);
    [[sender view] setCenter:translatedPoint];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[(UIPanGestureRecognizer*)sender velocityInView:self.frontView].x);
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
        if (translatedPoint.x > 0.75*self.center.x) {
            [UIView animateWithDuration:animationDuration animations:^{
                [[sender view] setCenter:CGPointMake(self.center.x + 15 - 4, translatedPoint.y)];
            }];
            self.privacyTurnedOn = YES;
            self.explanationString = @"Only you can invite people and only\nthose invited can see the event.";
            [self.privateDelegate updateUnderliningText];
            self.publicLabel.hidden = NO;
            [self bringSubviewToFront:self.publicLabel];
            self.publicLabel.textColor = [FontProperties getBlueColor];
            [self bringSubviewToFront:self.inviteOnlyLabel];
            self.inviteOnlyLabel.textColor = UIColor.whiteColor;
            self.movingImageView.hidden = NO;
            self.movingImageView.image = [UIImage imageNamed:@"openLock-1"];
            [self bringSubviewToFront:self.movingImageView];
        }
        else {
            [UIView animateWithDuration:animationDuration animations:^{
                [[sender view] setCenter:CGPointMake(self.center.x/2 - 15 + 4, translatedPoint.y)];
            }];
            self.privacyTurnedOn = NO;
            self.explanationString = @"The whole school can see what you are posting.";
            [self.privateDelegate updateUnderliningText];
            self.publicLabel.hidden = NO;
            [self bringSubviewToFront:self.publicLabel];
            self.publicLabel.textColor = UIColor.whiteColor;
            [self bringSubviewToFront:self.inviteOnlyLabel];
            self.inviteOnlyLabel.textColor = [FontProperties getBlueColor];
            self.movingImageView.hidden = NO;
            self.movingImageView.image = [UIImage imageNamed:@"openLock-30"];
            [self bringSubviewToFront:self.movingImageView];
        }
        return;
    }
    CGFloat percentage = 2*((translatedPoint.x - self.center.x/2)/self.center.x);
    percentage = MIN(MAX(percentage, 0), 1);
    self.publicLabel.hidden = NO;
    [self bringSubviewToFront:self.publicLabel];
    self.publicLabel.textColor = RGB(floor(255*(1-percentage) + 122*(percentage)),floor(255*(1-percentage) + 193*percentage), floor(255*(1-percentage) + 226*percentage));
    [self bringSubviewToFront:self.inviteOnlyLabel];
    self.inviteOnlyLabel.textColor = RGB(floor(255*percentage + 122*(1 - percentage)),floor(255*percentage + 193*(1-percentage)), floor(255*percentage + 226*(1-percentage)));
    int number = MAX((1-percentage) * 30, 1);
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"openLock-%d", number]];
    self.movingImageView.hidden = NO;
    self.movingImageView.image = image;
    [self bringSubviewToFront:self.movingImageView];
}




- (void)privacyPressed {
    if (!self.runningAnimation) {
        self.movingImageView.hidden = YES;
        [self bringSubviewToFront:self.openLockImageView];
        self.openLockImageView.hidden = NO;
        [self bringSubviewToFront:self.closeLockImageView];
        self.closeLockImageView.hidden = NO;
        self.runningAnimation = YES;
        if (!self.privacyTurnedOn) {
            //Change to private
            self.openLockImageView.currentFrameIndex = 29;
            self.closeLockImageView.animationRepeatCount = 1;
            self.closeLockImageView.animationDuration = 0.84;
            self.closeLockImageView.currentFrameIndex = 0;
            self.openLockImageView.hidden = YES;
            self.closeLockImageView.hidden = NO;
            [self.closeLockImageView startAnimating];
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.publicLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.publicLabel.textColor = [FontProperties getBlueColor];
                self.publicLabel.alpha = 1.0f;
                [self.privateDelegate updateUnderliningText];
            }];
            
            [UIView animateWithDuration:0.84 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.frontView setCenter:CGPointMake(self.center.x + 15 - 4 - 0.5, self.frontView.center.y)];
            }
            completion:^(BOOL finished) {
                [self.closeLockImageView stopAnimating];
                self.runningAnimation = NO;
             }];
            
            [UIView animateWithDuration:0.34 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.inviteOnlyLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.inviteOnlyLabel.transform = CGAffineTransformMakeTranslation(-2, 0);
                self.inviteOnlyLabel.textColor = UIColor.whiteColor;
                self.inviteOnlyLabel.alpha = 1.0f;
            }];
            
            self.privacyTurnedOn = YES;
            self.explanationString = self.privateString;
        }
        else {
            //Change to public
            self.openLockImageView.animationRepeatCount = 1;
            self.openLockImageView.animationDuration = 0.84;
            self.openLockImageView.currentFrameIndex = 0;
            self.closeLockImageView.hidden = YES;
            self.openLockImageView.hidden = NO;
            [self.openLockImageView startAnimating];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.inviteOnlyLabel.alpha = 0;
            } completion:^(BOOL finished) {
                self.inviteOnlyLabel.transform = CGAffineTransformMakeTranslation(0, 0);
                self.inviteOnlyLabel.textColor = [FontProperties getBlueColor];
                self.inviteOnlyLabel.alpha = 1.0f;
                [self.privateDelegate updateUnderliningText];
            }];

            
            [UIView animateWithDuration:0.84 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.frontView setCenter:CGPointMake(self.center.x/2 - 15 + 4 + 0.5, self.frontView.center.y)];
            } completion:^(BOOL finished) {
                self.runningAnimation = NO;
                [self.openLockImageView stopAnimating];
            }];
            
            [UIView animateWithDuration:0.34 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.publicLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.publicLabel.textColor = UIColor.whiteColor;
                self.publicLabel.alpha = 1.0f;
            }];
            //
            self.privacyTurnedOn = NO;
            self.explanationString = self.publicString;
        }
    }
}

- (void)changeToPrivateState:(BOOL)isPrivate {
    self.privacyTurnedOn = !isPrivate;
    [self privacyPressed];
}

@end
