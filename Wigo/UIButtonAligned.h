//
//  UIBarButtonAligned.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/3/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButtonAligned : UIButton

- (id)initWithFrame:(CGRect)frame andType:(NSNumber *)type;

@property NSNumber* type;

@end
