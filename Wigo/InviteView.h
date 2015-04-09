//
//  UIView+InviteView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/9/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
#import "Delegate.h"

@interface InviteView : UIView
+ (CGFloat) height;
- (void)setup;
@property (nonatomic, assign) id<InviteCellDelegate> delegate;
@property (nonatomic, strong) UIButton *tapButton;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) UIImageView *tapImageView;
@property (nonatomic, strong) UILabel *tapLabel;
@property (nonatomic, strong) UILabel *underlineTapLabel;
@end
