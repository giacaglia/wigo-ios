//
//  WGEventLikesTableCell.h
//  Wigo
//
//  Created by Gabriel Mahoney on 5/19/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WGUser;

@interface WGEventLikesTableCell : UITableViewCell

@property (nonatomic) UIImageView *profileImageView;
@property (nonatomic) UILabel *fullNameLabel;

- (void)setUser:(WGUser *)user;

+ (CGFloat)rowHeight;

@end
