//
//  FacebookAlbumTableViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FacebookAlbumTableViewController : UITableViewController
@end

#define kAlbumTableCellName @"albumTableCellName"

@interface AlbumTableCell : UITableViewCell
+ (CGFloat) height;
@property (nonatomic, strong) UILabel *albumNameLabel;
@property (nonatomic, strong) UIImageView *coverImageView;
@end