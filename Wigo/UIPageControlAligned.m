//
//  UIPageControlAligned.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/5/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UIPageControlAligned.h"

@implementation UIPageControlAligned


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (UIEdgeInsets)alignmentRectInsets {
    return UIEdgeInsetsMake(30, 0, 0, 0);
}

- (UIEdgeInsets)imageEdgeInsets {
    return UIEdgeInsetsMake(0, 0, 30, 0);
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
