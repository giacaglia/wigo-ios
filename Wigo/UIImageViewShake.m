//
//  UIImageViewShake.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/11/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UIImageViewShake.h"
#import <QuartzCore/QuartzCore.h>

@interface UIImageViewShake ()


@end

@implementation UIImageViewShake

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)newShake {
    self.originalFrame = self.frame;
    self.sizeDifference = self.originalFrame.size.width/8;
    self.frame = CGRectMake(self.frame.origin.x + self.originalFrame.size.width/2, self.frame.origin.y + self.originalFrame.size.height/2, 0, 0);
    _direction = 1;
    _shakes = 0;
    [self shake];
}

- (void)shake
{
    [UIView animateWithDuration:0.15 animations:^{
        int newRatio =  self.originalFrame.size.width/2 + self.direction * self.sizeDifference;
        int oldRatio = self.originalFrame.size.width/2;
        self.frame = CGRectMake(self.originalFrame.origin.x + oldRatio - newRatio, self.originalFrame.origin.y + oldRatio - newRatio, 2*newRatio, 2*newRatio);
        self.sizeDifference /= 2;
    }
                     completion:^(BOOL finished) {
                         if (finished) {
                             if (_shakes >= 13) {
                                 self.frame = self.originalFrame;
                                 return;
                             }
                             self.shakes++;
                             self.direction = self.direction * -1;
                             [self shake];
                         }
                     }];
}





/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
