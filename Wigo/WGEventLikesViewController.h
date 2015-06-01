//
//  WGEventLikesViewController.h
//  Wigo
//
//  Created by Gabriel Mahoney on 5/19/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WGEvent;
@class WGEventMessage;

@interface WGEventLikesViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic) UIImage *backgroundImage;
@property (nonatomic) UIButton *dismissButton;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UILabel *numberOfVotesLabel;
@property (nonatomic, assign) BOOL isFetching;

- (void)getLikesForEvent:(WGEvent *)event eventMessage:(WGEventMessage *)eventMessage;

@end
