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
@implementation WigoCustomCell


- (void)awakeFromNib {
    self.profileName.font = [FontProperties getSmallFont];
    [self.profileButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [self.profileButton2 addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [self.tapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self bringSubviewToFront:self.tapButton];
}

- (void)profileSegue:(id)sender {
    [self.delegate profileSegue:sender];
}

- (void)tapPressed:(id)sender {
    [self.delegate tapPressed:sender];
}

@end
