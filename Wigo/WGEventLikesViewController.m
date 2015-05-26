//
//  WGEventLikesViewController.m
//  Wigo
//
//  Created by Gabriel Mahoney on 5/19/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import "WGEventLikesViewController.h"
#import "EventConversationViewController.h"

#import "FontProperties.h"

#import "WGUser.h"
#import "WGEvent.h"
#import "WGEventMessage.h"
#import "WGEventLikesTableCell.h"

@interface WGEventLikesViewController ()

@property (nonatomic) UIImageView *backgroundImageView;

@property (nonatomic) UIImageView *upArrowImageView;

@property (nonatomic) UIView *headerView;
@property (nonatomic) UIView *headerBorderView;

@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL showingActivityIndicator;

@property (nonatomic) WGCollection *likeUsers;
@end


static NSString * kWGEventLikesCellIdentifier = @"WGEventLikesCellIdentifier";

@implementation WGEventLikesViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        self.numberOfVotesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                            0, 72.0, 20.0)];
        self.dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80.0, 55.0)];
        
        self.tableView = [[UITableView alloc] init];
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.likeUsers = nil;
        
        [self.tableView registerClass:[WGEventLikesTableCell class]
               forCellReuseIdentifier:kWGEventLikesCellIdentifier];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
    }
    return self;
}

- (void)viewDidLoad {
    
    self.backgroundImageView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    [self.view addSubview:self.backgroundImageView];
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                               0,
                                                               self.view.frame.size.width,
                                                               64.0)];
    
    
    
    CGRect rect = self.view.bounds;
    rect.origin.y += self.headerView.frame.size.height;
    rect.size.height -= self.headerView.frame.size.height;
    
    self.tableView.frame = rect;
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.headerView];
    
    self.numberOfVotesLabel.textColor = UIColor.whiteColor;
    self.numberOfVotesLabel.textAlignment = NSTextAlignmentCenter;
    self.numberOfVotesLabel.font = [FontProperties boldFont:18.0f];
    
    self.upArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"upArrow"]];
    self.upArrowImageView.frame = CGRectMake(0, 0, 36.0, 12.0);
    
    
    
    
    self.dismissButton.center = CGPointMake(self.view.frame.size.width/2.0, 0);
    CGRect frame = self.dismissButton.frame;
    frame.origin.y = 4.0;
    self.dismissButton.frame = frame;
    
    self.numberOfVotesLabel.center = CGPointMake(self.dismissButton.frame.size.width/2.0,0.0);
    frame = self.numberOfVotesLabel.frame;
    frame.origin.y = 4.0;
    self.numberOfVotesLabel.frame = frame;
    
    self.upArrowImageView.center = CGPointMake(self.dismissButton.frame.size.width/2.0,0.0);
    frame = self.upArrowImageView.frame;
    frame.origin.y = CGRectGetMaxY(self.numberOfVotesLabel.frame)+4.0;
    self.upArrowImageView.frame = frame;
    
    [self.dismissButton addSubview:self.numberOfVotesLabel];
    [self.dismissButton addSubview:self.upArrowImageView];
    
    [self.headerView addSubview:self.dismissButton];
    
    self.headerBorderView = [[UIView alloc] init];
    self.headerBorderView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    
    self.headerBorderView.frame = CGRectMake(0.0,
                                             self.headerView.frame.size.height-1.0,
                                             self.view.frame.size.width,
                                             1.0);
    
    [self.headerView addSubview:self.headerBorderView];
    
    CGPoint center = self.view.center;
    self.activityIndicator.center = CGPointMake(center.x, self.headerView.frame.size.height+[WGEventLikesTableCell rowHeight]/2.0);
    [self.view addSubview:self.activityIndicator];

}

- (void)getLikesForEvent:(WGEvent *)event eventMessage:(WGEventMessage *)eventMessage {
    
    [self showLoadingIndicator];
    [WGUser getLikesForEvent:event
             andEventMessage:eventMessage
                 withHandler:^(WGCollection *collection, NSError *error) {
                     self.likeUsers = collection;
                     [self.tableView reloadData];
                     self.numberOfVotesLabel.text = [EventConversationViewController stringForLikes:self.likeUsers.count];
                     [self hideLoadingIndicator];
             }];
}


#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.likeUsers.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [WGEventLikesTableCell rowHeight];

}

#pragma mark UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(self.likeUsers.count <= indexPath.row) {
        return [[UITableViewCell alloc] init];
    }
    WGUser *user = (WGUser *)[self.likeUsers objectAtIndex:indexPath.row];
    if(!user) {
        return [[UITableViewCell alloc] init];
    }
    
    WGEventLikesTableCell *likesCell = (WGEventLikesTableCell *)[tableView dequeueReusableCellWithIdentifier:kWGEventLikesCellIdentifier];
    
    [likesCell setUser:user];
    likesCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return likesCell;
}

- (void)showLoadingIndicator {
    _showingActivityIndicator = YES;
    self.tableView.hidden = YES;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)hideLoadingIndicator {
    _showingActivityIndicator = NO;
    self.tableView.hidden = NO;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

@end
