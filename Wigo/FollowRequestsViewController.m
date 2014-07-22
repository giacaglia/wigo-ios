//
//  FollowRequestsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FollowRequestsViewController.h"
#import "Globals.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface FollowRequestsViewController ()

@property UITableView *followRequestTableView;

@end

@implementation FollowRequestsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Follow Requests";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    [self initializeFollowRequestTable];
}

- (void) initializeFollowRequestTable {
    _followRequestTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49)];
    _followRequestTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_followRequestTableView];
    _followRequestTableView.dataSource = self;
    _followRequestTableView.delegate = self;
    _followRequestTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
//    User *user = (User *)[_everyoneParty getObjectWithId:[notifcation fromUserID]];
    User *user = [[User alloc] init];
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    profileImageView.layer.cornerRadius = 5;
    profileImageView.layer.borderWidth = 0.5;
    profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    profileImageView.layer.masksToBounds = YES;
    [cell.contentView addSubview:profileImageView];
    
    return cell;
}

#pragma mark - Network Function
- (void)fetchFollowRequests {
    NSString *queryString = @"/api/notifications/?type=follow.request";
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [_followRequestTableView reloadData];
        });
    }];
}

@end
