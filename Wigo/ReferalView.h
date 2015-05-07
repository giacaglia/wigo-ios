//
//  ReferalView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/7/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGUser.h"

@interface ReferalView : UIView

@property (nonatomic, strong) UITextField *typeNameField;
@property (nonatomic, strong) UITableView *referalTableView;
@end

@interface ReferalCell : UITableViewCell
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@end