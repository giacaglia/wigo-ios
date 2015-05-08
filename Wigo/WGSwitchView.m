//
//  WGSwitchView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/16/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGSwitchView.h"
#import "Globals.h"

@implementation WGSwitchView

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
    
    self.firstLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frontView.frame.size.width - 4, self.frontView.frame.size.height)];
    self.firstLabel.text = self.firstString;
    self.firstLabel.textAlignment = NSTextAlignmentCenter;
    self.firstLabel.textColor = UIColor.whiteColor;
    self.firstLabel.font = [FontProperties mediumFont:15.0f];
    [self addSubview:self.firstLabel];
    [self bringSubviewToFront:self.firstLabel];
    
    self.secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 10, 0, self.frame.size.width/2 - 20, self.frontView.frame.size.height)];
    self.secondLabel.text = self.secondString;
    self.secondLabel.textColor = [FontProperties getBlueColor];
    self.secondLabel.font = [FontProperties mediumFont:15.0f];
    self.secondLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.secondLabel];
    [self bringSubviewToFront:self.secondLabel];
    
    self.movingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 6, self.frame.size.height/2 - 8, 12, 16)];
    [self addSubview:self.movingImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(privacyPressed)];
    [self addGestureRecognizer:tapGesture];
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self.frontView addGestureRecognizer:panRecognizer];
}

- (void)setFirstString:(NSString *)firstString {
    _firstString = firstString;
    self.firstLabel.text = _firstString;
}

- (void)setSecondString:(NSString *)secondString {
    _secondString = secondString;
    self.secondLabel.text = _secondString;
}

-(void)move:(id)sender {
    [self bringSubviewToFront:[(UIPanGestureRecognizer*)sender view]];
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.frontView];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        self.firstX = [sender view].frame.origin.x;
    }
    
    translatedPoint = CGPointMake(self.firstX+translatedPoint.x, [sender view].frame.origin.y);
    translatedPoint = CGPointMake(MIN(MAX(2 ,translatedPoint.x), self.frame.size.width - self.frontView.frame.size.width - 2), translatedPoint.y);
    [[sender view] setFrame:CGRectMake(translatedPoint.x, translatedPoint.y, [sender view].frame.size.width, [sender view].frame.size.height)];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[(UIPanGestureRecognizer*)sender velocityInView:self.frontView].x);
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
        if ([sender view].center.x > self.frame.size.width/2) {
            [UIView animateWithDuration:animationDuration animations:^{
                [[sender view] setFrame:CGRectMake(self.frame.size.width - self.frontView.frame.size.width - 2, [sender view].frame.origin.y, [sender view].frame.size.width, [sender view].frame.size.height)];
            }];
            [self.switchDelegate switched];
            self.privacyTurnedOn = YES;
            self.firstLabel.hidden = NO;
            [self bringSubviewToFront:self.firstLabel];
            self.firstLabel.textColor = [FontProperties getBlueColor];
            [self bringSubviewToFront:self.secondLabel];
            self.secondLabel.textColor = UIColor.whiteColor;
            [self bringSubviewToFront:self.movingImageView];
        }
        else {
            [UIView animateWithDuration:animationDuration animations:^{
                [[sender view] setFrame:CGRectMake(2, [sender view].frame.origin.y, [sender view].frame.size.width, [sender view].frame.size.height)];
            }];
            [self.switchDelegate switched];
            self.privacyTurnedOn = NO;
            self.firstLabel.hidden = NO;
            [self bringSubviewToFront:self.firstLabel];
            self.firstLabel.textColor = UIColor.whiteColor;
            [self bringSubviewToFront:self.secondLabel];
            self.secondLabel.textColor = [FontProperties getBlueColor];
        
            [self bringSubviewToFront:self.movingImageView];
        }
        return;
    }
    [self bringSubviewToFront:self.movingImageView];
}

- (void)privacyPressed {
    if (!self.runningAnimation) {
        self.runningAnimation = YES;
        if (!self.privacyTurnedOn) {
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.firstLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.firstLabel.textColor = [FontProperties getBlueColor];
                self.firstLabel.alpha = 1.0f;
                [self.switchDelegate switched];
            }];
            
            [UIView animateWithDuration:0.84 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.frontView.frame = CGRectMake(self.frame.size.width - self.frontView.frame.size.width - 2, self.frontView.frame.origin.y, self.frontView.frame.size.width, self.frontView.frame.size.height);
            }
                             completion:^(BOOL finished) {
                                 self.runningAnimation = NO;
                             }];
            
            [UIView animateWithDuration:0.34 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.secondLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.secondLabel.transform = CGAffineTransformMakeTranslation(-2, 0);
                self.secondLabel.textColor = UIColor.whiteColor;
                self.secondLabel.alpha = 1.0f;
            }];
            
            self.privacyTurnedOn = YES;
        }
        else {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.secondLabel.alpha = 0;
            } completion:^(BOOL finished) {
                self.secondLabel.transform = CGAffineTransformMakeTranslation(0, 0);
                self.secondLabel.textColor = [FontProperties getBlueColor];
                self.secondLabel.alpha = 1.0f;
                [self.switchDelegate switched];
            }];
            
            
            [UIView animateWithDuration:0.84 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.frontView.frame = CGRectMake(2, self.frontView.frame.origin.y, self.frontView.frame.size.width, self.frontView.frame.size.height);
            } completion:^(BOOL finished) {
                self.runningAnimation = NO;
            }];
            
            [UIView animateWithDuration:0.34 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.firstLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.firstLabel.textColor = UIColor.whiteColor;
                self.firstLabel.alpha = 1.0f;
            }];
            self.privacyTurnedOn = NO;
        }
    }
}



- (void)changeToPrivateState:(BOOL)isPrivate {
    self.privacyTurnedOn = !isPrivate;
    [self privacyPressed];
}

@end
