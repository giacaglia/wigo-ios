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
- (void) setLabelsForUser: (WGUser *) user;
@property (nonatomic, assign) id<InviteCellDelegate> delegate;
+ (CGFloat) rowHeight;
@property (nonatomic, strong) UILabel *tappedLabel;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UILabel *titleLabel;
- (void)setup;
@end
