//
//  TopSchoolViewController.h
//  Wigo
//
//  Created by Alex Grinman on 1/15/15.
//  Copyright (c) 2015 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupStats.h"

@interface TopSchoolViewController : UITableViewController

@property (nonatomic, strong) NSArray *topSchools;
@end


@interface TopSchoolCell : UITableViewCell
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *countLabel;

+ (CGFloat) rowHeight;
@end