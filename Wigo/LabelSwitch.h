//
//  NSObject+LabelSwitch.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/27/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LabelSwitch : UIView

+ (CGFloat)height;
@property (nonatomic, assign) CGFloat transparency;
@property (nonatomic, strong) UILabel *friendsLabel;
@property (nonatomic, strong) UILabel *bostonLabel;
@property (nonatomic, strong) UIView *lineViewUnderLabel;
@end
