//
//  NSObject+LabelSwitch.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/27/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "LabelSwitch.h"
#import "Globals.h"


@implementation LabelSwitch : UIView

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
    self.backgroundColor = RGB(249, 249, 249);
    self.clipsToBounds = YES;
    UIButton *leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width/2, self.frame.size.height)];
    [leftButton addTarget:self action:@selector(scrollLeft) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:leftButton];
    
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2, 0, self.frame.size.width/2, self.frame.size.height)];
    [rightButton addTarget:self action:@selector(scrollRight) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:rightButton];
    
    self.friendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(58, [LabelSwitch height] - 22 - 7, 68, 22)];
    self.friendsLabel.textAlignment = NSTextAlignmentCenter;
    self.friendsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];
    self.friendsLabel.textColor = [FontProperties getBlueColor];
    self.friendsLabel.text = @"Friends";
    [self addSubview: self.friendsLabel];
    
    self.lineViewUnderLabel = [[UIView alloc] initWithFrame:CGRectMake(58, [LabelSwitch height] - 3, 68, 3)];
    self.lineViewUnderLabel.backgroundColor = [FontProperties getBlueColor];
    [self addSubview:self.lineViewUnderLabel];
    
    self.bostonLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 58 - 68, [LabelSwitch height] - 22 - 7, 68, 22)];
    self.bostonLabel.textAlignment = NSTextAlignmentCenter;
    self.bostonLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];
    self.bostonLabel.textColor = RGB(179, 179, 179);
    self.bostonLabel.text = @"Boston";
    [self addSubview: self.bostonLabel];
}

- (void)scrollLeft {
    [UIView animateWithDuration:0.3f animations:^{
        self.lineViewUnderLabel.frame = CGRectMake(58, [LabelSwitch height] - 3, 68, 3);
        self.friendsLabel.textColor = [FontProperties getBlueColor];
        self.bostonLabel.textColor = RGB(179, 179, 179);
    }];
}

- (void)scrollRight {
    [UIView animateWithDuration:0.3f animations:^{
        self.lineViewUnderLabel.frame = CGRectMake(self.frame.size.width - 58 - 68, [LabelSwitch height] - 3, 68, 3);
        self.friendsLabel.textColor = RGB(179, 179, 179);
        self.bostonLabel.textColor = [FontProperties getBlueColor];
    }];
}


+ (CGFloat) height {
    return 40;
}

@end
