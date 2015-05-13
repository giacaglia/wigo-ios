//
//  ReferalView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/7/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGUser.h"
#import "WGCollection.h"

@interface ReferalView : UIView
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIButton *aroundSkipButton;
@property (nonatomic, strong) UILabel *skipLabel;
@property (nonatomic, strong) UIView *aroundTypeNameView;
@property (nonatomic, strong) UITextField *typeNameField;
@property (nonatomic, strong) UITableView *referalTableView;
@property (nonatomic, strong) WGCollection *presentedUsers;
@property (nonatomic, strong) UILabel *beforeWeStartLabel;
@property (nonatomic, strong) UILabel *didReferLabel;
@end

@interface ReferalCell : UITableViewCell
+(CGFloat) height;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@end