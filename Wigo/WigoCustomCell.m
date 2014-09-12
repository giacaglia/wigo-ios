//
//  WigoCustomCell.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/11/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "WigoCustomCell.h"
#import "UIImageView+WebCache.h"
#import "FontProperties.h"
#import "UIImageViewShake.h"
@implementation WigoCustomCell


- (void)awakeFromNib {
    self.profileName.font = [FontProperties getSmallFont];
    [self.profileButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [self.profileButton2 addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [self.profileButton3 addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [self.tapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self bringSubviewToFront:self.tapButton];
    
    self.tappedImageView = [[UIImageViewShake alloc] initWithFrame:CGRectMake(69, 5, 30, 30)];
    [self addSubview:self.tappedImageView];
}

- (void)profileSegue:(id)sender {
    [self.delegate profileSegue:sender];
}

- (void)tapPressed:(id)sender {
    [self.delegate tapPressed:sender];
}

@end
