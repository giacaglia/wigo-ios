//
//  UIBarButtonAligned.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/3/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UIButtonAligned.h"

@implementation UIButtonAligned

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame andType:(NSNumber *)type
{
    self = [super initWithFrame:frame];
    if (self) {
        self.type = type;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (UIEdgeInsets)alignmentRectInsets {
    UIEdgeInsets insets;
    if ([self.type isEqualToNumber:@0]) {
        insets = UIEdgeInsetsMake(0, 18.0f, 0, 0);
    }
    else if ([self.type isEqualToNumber:@1]) {
        insets = UIEdgeInsetsMake(0, 0, 0, 26.0f);
    }
    else if ([self.type isEqualToNumber:@2]) {
        insets = UIEdgeInsetsMake(0, 10, 0, 0);
    }
    else if ([self.type isEqualToNumber:@3]) {
        insets = UIEdgeInsetsMake(0, 0, 0, 8);
    }
    else if ([self.type isEqualToNumber:@5]) {
        insets = UIEdgeInsetsMake(0, 0, 0, 10.0f);
    }
    return insets;
}

@end
