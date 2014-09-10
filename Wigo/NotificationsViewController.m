//
//  NotificationsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "NotificationsViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import "LeaderboardViewController.h"

@interface NotificationsViewController ()
@property int yPositionOfNotification;

@property UITableView *notificationsTableView;
@property NSMutableArray *notificationArray;
@property Party *notificationsParty;
@property Party *everyoneParty;

@property UIActivityIndicatorView *spinner;
@property NSNumber *page;
@property NSNumber *followRequestSummary;
@property int lastNotificationRead;

@end

@implementation NotificationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _followRequestSummary = @0;
    _everyoneParty = [Profile everyoneParty];
    [self initializeTableNotifications];
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 1, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGBAlpha(244, 149, 45, 0.1f);
    [self.navigationController.navigationBar addSubview:lineView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchEverything) name:@"fetchNotifications" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapSegue) name:@"tapSegue" object:nil];
    

}

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"notificationsSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
    [self fetchSummaryOfFollowRequests];
    [self fetchFirstPageNotifications];
}


- (void) viewDidAppear:(BOOL)animated {
    [EventAnalytics tagEvent:@"Notifications View"];

    [self initializeNavigationItem];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self updateLastNotificationsRead];
}

- (void)initializeNavigationItem {
    self.tabBarController.tabBar.hidden = NO;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Notifications";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    UIButtonAligned *leaderboardButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 50, 30) andType:@3];
    [leaderboardButton addTarget:self action:@selector(leaderboardSegue)
            forControlEvents:UIControlEventTouchUpInside];
    [leaderboardButton setShowsTouchWhenHighlighted:YES];
    [leaderboardButton setTitle:@"100" forState:UIControlStateNormal];
    [leaderboardButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    leaderboardButton.titleLabel.textAlignment = NSTextAlignmentRight;
    leaderboardButton.titleLabel.font = [FontProperties getSubtitleFont];
    UIBarButtonItem *leaderboardBarButton =[[UIBarButtonItem alloc] initWithCustomView:leaderboardButton];
    self.navigationItem.rightBarButtonItem = leaderboardBarButton;
}

- (void)leaderboardSegue {
    LeaderboardViewController *leaderboardViewController = [LeaderboardViewController new];
    [self.navigationController pushViewController:leaderboardViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void) initializeTableNotifications {
    self.automaticallyAdjustsScrollViewInsets = NO;
    _notificationsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49)];
    _notificationsTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_notificationsTableView];
    _notificationsTableView.dataSource = self;
    _notificationsTableView.delegate = self;
    _notificationsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addRefreshToTable];
}

- (void)scrollUp {
    [_notificationsTableView setContentOffset:CGPointZero animated:YES];
}


#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_notificationsParty hasNextPage] && [indexPath row] == [[_notificationsParty getObjectArray] count]) {
        return 30;
    }
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int hasNextPage = ([_notificationsParty hasNextPage] ? 1 : 0);
    if ([_followRequestSummary isEqualToNumber:@0]) {
        return [[_notificationsParty getObjectArray] count] + hasNextPage;
    }
    else return [[_notificationsParty getObjectArray] count] + hasNextPage + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
    NSInteger row = [indexPath row];
    if (![_followRequestSummary isEqualToNumber:@0]) {
        if (row == 0) {
            UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
            [notificationButton addTarget:self action:@selector(folowRequestPressed) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:notificationButton];
            
            UILabel *numberOfRequestsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 35, 35)];
            numberOfRequestsLabel.layer.cornerRadius = 5;
            numberOfRequestsLabel.layer.borderWidth = 0.5;
            numberOfRequestsLabel.layer.borderColor = [UIColor whiteColor].CGColor;
            numberOfRequestsLabel.layer.masksToBounds = YES;
            numberOfRequestsLabel.backgroundColor = RGB(254, 242, 229);
            numberOfRequestsLabel.text = [_followRequestSummary stringValue];
            numberOfRequestsLabel.textColor = [FontProperties getOrangeColor];
            numberOfRequestsLabel.textAlignment = NSTextAlignmentCenter;
            [notificationButton addSubview:numberOfRequestsLabel];
            
            UIImageView *iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"addedFilled"]];
            iconLabel.frame = CGRectMake(55, 20, 17, 12);
            [notificationButton addSubview:iconLabel];
        
            UILabel *notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(83, 9, 200, 36)];
            notificationLabel.text = @"Follow requests";
            notificationLabel.font = [FontProperties getBioFont];
            [notificationButton addSubview:notificationLabel];
           
            UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeRightArrow"]];
            rightArrowImageView.frame = CGRectMake(cell.contentView.frame.size.width - 35, 27 - 9, 11, 18);
            [notificationButton addSubview:rightArrowImageView];            
            
            return cell;
        }
        row = [indexPath row] - 1;
    }
    
    
    if (row == [[_notificationsParty getObjectArray] count] ) {
        if ([_page intValue] < 5) [self fetchNotifications];
        return cell;
    }
    
    if ([[_notificationsParty getObjectArray] count] == 0) return cell;
    Notification *notification = [[_notificationsParty getObjectArray] objectAtIndex:row];
    if ([notification fromUserID] == (id)[NSNull null]) return cell;
    // When group is unlocked
    if ([[notification type] isEqualToString:@"group.unlocked"]) return cell;
    
    User *user = (User *)[_everyoneParty getObjectWithId:[notification fromUserID]];
    
    NSString *name = [user fullName];
    NSString *typeString = [notification type];
    NSString *message = [notification message];
    NSString *timeString = [notification timeString];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
    
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    profileImageView.layer.cornerRadius = 5;
    profileImageView.layer.borderWidth = 0.5;
    profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UIImageView *iconLabel;
    if ([typeString isEqualToString:@"chat"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"commentFilled"]];
        iconLabel.frame = CGRectMake(58, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(chatSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([typeString isEqualToString:@"tap"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tapFilled"]];
        iconLabel.frame = CGRectMake(58, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(tapSegue) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([typeString isEqualToString:@"follow"] || [typeString isEqualToString:@"facebook.follow"] || [typeString isEqualToString:@"follow.accepted"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"addedFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 17, 12);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([typeString isEqualToString:@"joined"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"joined"]];
        iconLabel.frame = CGRectMake(58, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([typeString isEqualToString:@"goingout"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_tiny_blue"]];
        iconLabel.frame = CGRectMake(58, 20, 14, 16);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    notificationButton.tag = row;
    [notificationButton addSubview:iconLabel];

    UILabel *notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(83, 18, 200, 18)];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:name ];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:nil]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:message attributes:nil]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, name.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(name.length , message.length + 1)];
    notificationLabel.attributedText = string;
    notificationLabel.font = [FontProperties getBioFont];
    notificationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    notificationLabel.numberOfLines = 0;
    if ([string size].width > 175) {
        notificationLabel.frame = CGRectMake(83, 9, 200, 36);
    }
    [notificationButton addSubview:notificationLabel];
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 150, 37, 140, 12)];
    timeLabel.text = timeString;
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.font = [FontProperties getSmallPhotoFont];
    timeLabel.textColor = RGB(201, 202, 204);
    [notificationButton addSubview:timeLabel];
    
    [cell.contentView addSubview:notificationButton];
    if ([(NSNumber *)[notification objectForKey:@"id"] intValue] > [(NSNumber *)[[Profile user] lastNotificationRead] intValue]) {
        cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    }
    return cell;
}

- (void)folowRequestPressed {
    self.followRequestsViewController = [[FollowRequestsViewController alloc] init];
    [self.navigationController pushViewController:self.followRequestsViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)chatSegue:(id)sender {
    self.conversationViewController = [[ConversationViewController alloc] init];
    [self.navigationController pushViewController:self.conversationViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)tapSegue {
    self.tapViewController = [[TapViewController alloc] init];
    [self.navigationController pushViewController:self.tapViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;

}

- (void) profileSegue:(id)sender {
    UIButton *notificationButton = (UIButton *)sender;
    int rowOfButtonSender = (int)notificationButton.tag;
    if (rowOfButtonSender < [[_notificationsParty getObjectArray] count]) {
        Notification *notification = [[_notificationsParty getObjectArray] objectAtIndex:rowOfButtonSender];
        User *user = (User *)[_everyoneParty getObjectWithId:[notification fromUserID]];
        self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.profileViewController animated:YES];
        self.tabBarController.tabBar.hidden = YES;
    }
}

#pragma mark - Refresh button

- (void)addRefreshToTable {
    [WiGoSpinnerView addDancingGToUIScrollView:_notificationsTableView withHandler:^{
        [self fetchSummaryOfFollowRequests];
        [self fetchFirstPageNotifications];
        [self updateLastNotificationsRead];
    }];
}

#pragma mark - Network function

- (void)updateLastNotificationsRead {
    User *profileUser = [Profile user];
    for (Notification *notification in [_notificationsParty getObjectArray]) {
        if ([(NSNumber *)[notification objectForKey:@"id"] intValue] > [(NSNumber *)[[Profile user] lastNotificationRead] intValue]) {
            [profileUser setLastNotificationRead:[notification objectForKey:@"id"]];
            [profileUser saveKeyAsynchronously:@"last_notification_read" withHandler:^() {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTabBarNotifications" object:nil];
                });
            }];
        }
    }
}

-(void)fetchEverything {
    [self fetchSummaryOfFollowRequests];
    [self fetchFirstPageNotifications];
}

- (void)fetchFirstPageNotifications {
    _page = @1;
    [self fetchNotifications];
}

- (void)fetchNotifications {
    NSString *queryString = [NSString stringWithFormat:@"notifications/?type__ne=follow.request&page=%@" ,[_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ([_page isEqualToNumber:@1]) _notificationsParty = [[Party alloc] initWithObjectType:NOTIFICATION_TYPE];
            NSArray *arrayOfNotifications = [jsonResponse objectForKey:@"objects"];
            [_notificationsParty addObjectsFromArray:arrayOfNotifications];
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_notificationsParty addMetaInfo:metaDictionary];
            _page = @([_page intValue] + 1);
            [_notificationsTableView reloadData];
            [_notificationsTableView didFinishPullToRefresh];
        });
    }];
}


- (void)fetchSummaryOfFollowRequests {
    [Network queryAsynchronousAPI:@"notifications/summary/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ([[jsonResponse allKeys] containsObject:@"follow.request"]) {
                _followRequestSummary = (NSNumber *)[jsonResponse objectForKey:@"follow.request"];
                [_notificationsTableView reloadData];
            }
        });
    }];
}


@end
