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
    _followRequestsParty = [[Party alloc] initWithObjectName:@"Notification"];
    [self fetchFollowRequests];
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
    UIButton *buttonSender = (UIButton *)sender;
    UITableViewCell *cell = [_followRequestTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:buttonSender.tag inSection:0]];
    for (UIView *subview in [cell.contentView subviews]) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview removeFromSuperview];
        }
    }
    UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, 27 - 15, 49, 30)];
    [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    followPersonButton.tag = -100;
    [followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:followPersonButton];
    
//    if ([user isFollowing]) {
//        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
//        followPersonButton.tag = 100;
//    }


}

- (void)rejectUser:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    UITableViewCell *cell = [_followRequestTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:buttonSender.tag inSection:0]];
    for (UIView *subview in [cell.contentView subviews]) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview removeFromSuperview];
        }
    }


}

- (void)followedPersonPressed:(id)sender {
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:_followRequestTableView];
    NSIndexPath *indexPath = [_followRequestTableView indexPathForRowAtPoint:buttonOriginInTableView];
    User *user = [Profile user];
    
//    UIButton *senderButton = (UIButton*)sender;
//    if (senderButton.tag == -100) {
//        
//        if ([user isPrivate]) {
//            [senderButton setBackgroundImage:nil forState:UIControlStateNormal];
//            [senderButton setTitle:@"Pending" forState:UIControlStateNormal];
//            [senderButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
//            senderButton.titleLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:12.0f];
//            senderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
//            senderButton.layer.borderWidth = 1;
//            senderButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
//            senderButton.layer.cornerRadius = 3;
//        }
//        else {
//            [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
//        }
//        senderButton.tag = 100;
//        [self updateFollowingUIAndCachedData:num_following];
//        [Network followUser:user];
//    }
//    else {
//        [senderButton setTitle:nil forState:UIControlStateNormal];
//        [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
//        senderButton.tag = -100;
//        [self updateFollowingUIAndCachedData:num_following];
//        [Network unfollowUser:user];
//    }
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
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([[_followRequestsParty getObjectArray] count] == 0) return cell;

    Notification *notification = [[_followRequestsParty getObjectArray] objectAtIndex:[indexPath row]];
    User *user = [[User alloc] initWithDictionary:[notification objectForKey:@"from_user"]];
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
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(55, 27 - 12, 150, 24)];
    labelName.font = [FontProperties getSmallFont];
    labelName.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
    labelName.tag = [indexPath row];
    labelName.textAlignment = NSTextAlignmentLeft;
    [cell.contentView addSubview:labelName];
    
    UIButton *acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 83, 27 - 10, 20, 20)];
    UIImageView *acceptImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"acceptFollowRequest"]];
    acceptImageView.frame = CGRectMake(0, 0, 18, 18);
    [acceptButton addSubview:acceptImageView];
    acceptButton.tag = [indexPath row];
    [acceptButton addTarget:self action:@selector(acceptUser:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:acceptButton];
    
    UIButton *rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 40 , 27 - 10, 20, 20)];
    UIImageView *rejectImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rejectFollowRequest"]];
    rejectImageView.frame = CGRectMake(0, 0, 18, 18);
    [rejectButton addSubview:rejectImageView];
    rejectButton.tag = [indexPath row];
    [rejectButton addTarget:self action:@selector(rejectUser:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:rejectButton];
    
    if (NO) {
        UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, 24, 49, 30)];
        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        followPersonButton.tag = -100;
        [followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:followPersonButton];
        
        if ([user isFollowing]) {
            [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
            followPersonButton.tag = 100;
        }
    }

    return cell;
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
