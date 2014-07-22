//
//  FollowRequestsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FollowRequestsViewController.h"
#import "Globals.h"

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

#pragma mark - Network Function
- (void)fetchFollowRequests {
    NSString *queryString = @"/api/notifications/?type=follow.request";
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
        });
    }];
}

@end
