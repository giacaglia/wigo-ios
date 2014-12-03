//
//  PeekViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 12/1/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PeekViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray *schoolSections;
@end

@interface SchoolCell : UITableViewCell
@property (nonatomic, strong) UILabel *schoolLabel;
@end

@interface SchoolHeaderCell : UITableViewHeaderFooterView
@property (nonatomic, strong) UILabel *headerTitleLabel;
@end
