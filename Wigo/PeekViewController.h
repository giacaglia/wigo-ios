//
//  PeekViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 12/1/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlacesDelegate <NSObject>
- (void)setGroupID:(NSNumber *)groupID;
@end

@interface PeekViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray *schoolSections;
@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
@end

@interface SchoolCell : UITableViewCell
@property (nonatomic, strong) UILabel *schoolLabel;
@end

@interface SchoolHeaderCell : UITableViewHeaderFooterView
@property (nonatomic, strong) UILabel *headerTitleLabel;
@end
