//
//  FollowRequestsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FollowRequestsViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"

@interface FollowRequestsViewController ()

@property UITableView *followRequestTableView;
@property Party *followRequestsParty;
@property NSNumber *page;
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
    _page = @1;
    self.title = @"Follow Requests";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    [self initializeLeftBarButton];
    [self initializeFollowRequestTable];
    _followRequestsParty = [[Party alloc] initWithObjectType:NOTIFICATION_TYPE];
    [self fetchFollowRequests];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [EventAnalytics tagEvent:@"Follow Requests View"];
}

- (void) initializeFollowRequestTable {
    _followRequestTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 49)];
    _followRequestTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_followRequestTableView];
    _followRequestTableView.dataSource = self;
    _followRequestTableView.delegate = self;
    _followRequestTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void)acceptUser:(id)sender {
    [EventAnalytics tagEvent:@"Follow Request Accepted"];
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    UITableViewCell *cell = [_followRequestTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:buttonSender.tag inSection:0]];
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    Notification *notification = [[_followRequestsParty getObjectArray] objectAtIndex:buttonSender.tag];
    User *user = [[User alloc] initWithDictionary:[notification objectForKey:@"from_user"]];
    [Network acceptFollowRequestForUser:user];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width - 100, 54)];
    notificationButton.tag = tag;
    [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:notificationButton];
    
    [cell.contentView addSubview:notificationButton];
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
    profileImageView.layer.cornerRadius = 5;
    profileImageView.layer.borderWidth = 0.5;
    profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(55, 27 - 12, 150, 24)];
    labelName.font = [FontProperties getSmallFont];
    labelName.text = [user fullName];
    labelName.tag = tag;
    labelName.textAlignment = NSTextAlignmentLeft;
    [notificationButton addSubview:labelName];
    
    UIButton *followBackPersonButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, 27 - 15, 49, 30)];
    if ([user isFollowing]) {
        followBackPersonButton.tag = -100;
        [followBackPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
    }
    else {
        followBackPersonButton.tag = 100;
        [followBackPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    }
    [followBackPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchDown];
    [cell.contentView addSubview:followBackPersonButton];

}

- (void)rejectUser:(id)sender {
    [EventAnalytics tagEvent:@"Follow Request Rejected"];
    UIButton *buttonSender = (UIButton *)sender;
    UITableViewCell *cell = [_followRequestTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:buttonSender.tag inSection:0]];
    for (UIView *subview in [cell.contentView subviews]) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview removeFromSuperview];
        }
    }
    Notification *notification = [[_followRequestsParty getObjectArray] objectAtIndex:buttonSender.tag];
    User *user = [[User alloc] initWithDictionary:[notification objectForKey:@"from_user"]];
    [Network rejectFollowRequestForUser:user];


}

- (void)followedPersonPressed:(id)sender {
    UIButton *buttonSender = (UIButton*)sender;
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:_followRequestTableView];
    NSIndexPath *indexPath = [_followRequestTableView indexPathForRowAtPoint:buttonOriginInTableView];
    User *user = [self getUserAtIndex:(int)[indexPath row]];
    if (user) {
        if (buttonSender.tag == 50) {
            [buttonSender setTitle:nil forState:UIControlStateNormal];
            [buttonSender setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
            buttonSender.tag = -100;
            [user setIsBlocked:NO];
            NSString *queryString = [NSString stringWithFormat:@"users/%@", [user objectForKey:@"id"]];
            NSDictionary *options = @{@"is_blocked": @NO};
            [Network sendAsynchronousHTTPMethod:POST
                                    withAPIName:queryString
                                    withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                                    withOptions:options];
        }
        else if (buttonSender.tag == -100) {
            if ([user isPrivate]) {
                [buttonSender setBackgroundImage:nil forState:UIControlStateNormal];
                [buttonSender setTitle:@"Pending" forState:UIControlStateNormal];
                [buttonSender setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
                buttonSender.titleLabel.font =  [FontProperties scMediumFont:12.0f];
                buttonSender.titleLabel.textAlignment = NSTextAlignmentCenter;
                buttonSender.layer.borderWidth = 1;
                buttonSender.layer.borderColor = [FontProperties getOrangeColor].CGColor;
                buttonSender.layer.cornerRadius = 3;
                [user setIsFollowingRequested:YES];
            }
            else {
                [buttonSender setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                [user setIsFollowing:YES];
            }
            buttonSender.tag = 100;
            [Network followUser:user];
        }
        else {
            [buttonSender setTitle:nil forState:UIControlStateNormal];
            [buttonSender setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
            buttonSender.tag = -100;
            [user setIsFollowing:NO];
            [user setIsFollowingRequested:NO];
            [Network unfollowUser:user];
        }
    }
}


- (User *)getUserAtIndex:(int)index {
    User *user;
    if (index >= 0 && index < [[_followRequestsParty getObjectArray] count]) {
        Notification *notification = [[_followRequestsParty getObjectArray] objectAtIndex:index];
        user = [[User alloc] initWithDictionary:[notification objectForKey:@"from_user"]];
    }
    return user;
}

- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_followRequestsParty getObjectArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    
    if ([[_followRequestsParty getObjectArray] count] == 0) return cell;

    Notification *notification = [[_followRequestsParty getObjectArray] objectAtIndex:[indexPath row]];
    User *user = [[User alloc] initWithDictionary:[notification objectForKey:@"from_user"]];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width - 100, 54)];
    notificationButton.tag = [indexPath row];
    [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:notificationButton];
    
    [cell.contentView addSubview:notificationButton];
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
    profileImageView.layer.cornerRadius = 5;
    profileImageView.layer.borderWidth = 0.5;
    profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(55, 27 - 12, 150, 24)];
    labelName.font = [FontProperties getSmallFont];
    labelName.text = [user fullName];
    labelName.tag = [indexPath row];
    labelName.textAlignment = NSTextAlignmentLeft;
    [notificationButton addSubview:labelName];
    
    UIButton *acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 86, 27 - 13, 30, 30)];
    UIImageView *acceptImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"acceptFollowRequest"]];
    acceptImageView.frame = CGRectMake(0, 0, 30, 30);
    [acceptButton addSubview:acceptImageView];
    acceptButton.tag = [indexPath row];
    [acceptButton addTarget:self action:@selector(acceptUser:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:acceptButton];
    
    UIButton *rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 43 , 27 - 13, 30, 30)];
    UIImageView *rejectImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rejectFollowRequest"]];
    rejectImageView.frame = CGRectMake(0, 0, 30, 30);
    [rejectButton addSubview:rejectImageView];
    rejectButton.tag = [indexPath row];
    [rejectButton addTarget:self action:@selector(rejectUser:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:rejectButton];
    return cell;
}

- (void)profileSegue:(id)sender {
    int index = (int)((UIButton *)sender).tag;
    Notification *notification = [[_followRequestsParty getObjectArray] objectAtIndex:index];
    User *user = [[User alloc] initWithDictionary:[notification objectForKey:@"from_user"]];
    self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:self.profileViewController animated:YES];
}

#pragma mark - Network Functions


- (void)fetchFollowRequests {
    NSString *queryString = @"notifications/?type=follow.request";
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSArray *arrayOfNotifications = [jsonResponse objectForKey:@"objects"];
            [_followRequestsParty addObjectsFromArray:arrayOfNotifications];
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_followRequestsParty addMetaInfo:metaDictionary];
            _page = @([_page intValue] + 1);
            [_followRequestTableView reloadData];
        });
    }];
}

@end
