//
//  ContactsViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MobileContactsViewController : UIViewController  <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@end

#define kMobileInviteCellName @"MobileInviteCellName"
@interface MobileInviteCell : UITableViewCell
+ (CGFloat)height;
@property (nonatomic, strong) UIImageView *selectedPersonImageView;
@property (nonatomic, strong) UILabel *nameOfPersonLabel;
@end