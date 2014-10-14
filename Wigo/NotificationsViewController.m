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
#define HEIGHT_NOTIFICATION_CELL 80
#define HEADER_HEIGHT_CELL 20

@interface NotificationsViewController ()
@property int yPositionOfNotification;

@property UITableView *notificationsTableView;
@property NSMutableArray *notificationArray;

@property Party *notificationsParty;
@property Party *expiredNotificationsParty;
@property Party *nonExpiredNotificationsParty;

@property UIActivityIndicatorView *spinner;
@property NSNumber *page;
@property NSNumber *followRequestSummary;
@property int lastNotificationRead;

@end

BOOL isFetchingNotifications;
BOOL didProfileSegue;

@implementation NotificationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _followRequestSummary = @0;
    isFetchingNotifications = NO;
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
    
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchEverything) name:@"fetchNotifications" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"notificationsSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
    [self fetchEverything];
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
    else if ([indexPath section] == 0 && [indexPath row] == [[_nonExpiredNotificationsParty getObjectArray] count]) {
        return 20;
    }
    return HEIGHT_NOTIFICATION_CELL;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([_followRequestSummary isEqualToNumber:@0]) {
            return [[_nonExpiredNotificationsParty getObjectArray] count];
        }
        else {
            return [[_nonExpiredNotificationsParty getObjectArray] count] + 1;
        }
    }
    else {
        int hasNextPage = ([_notificationsParty hasNextPage] ? 1 : 0);
        return [[_expiredNotificationsParty getObjectArray] count] + hasNextPage;
    }
   
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
        if ([indexPath section] == 0 && row == 0) {
            UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HEIGHT_NOTIFICATION_CELL)];
            [notificationButton addTarget:self action:@selector(folowRequestPressed) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:notificationButton];
            
            UILabel *numberOfRequestsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, HEIGHT_NOTIFICATION_CELL/2 - 17, 35, 35)];
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
        
            UILabel *notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, HEIGHT_NOTIFICATION_CELL/2 - 18, 200, 36)];
            notificationLabel.text = @"Follow requests";
            notificationLabel.font = [FontProperties getBioFont];
            [notificationButton addSubview:notificationLabel];
           
            UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeRightArrow"]];
            rightArrowImageView.frame = CGRectMake(cell.contentView.frame.size.width - 35, HEIGHT_NOTIFICATION_CELL/2 - 9, 11, 18);
            [notificationButton addSubview:rightArrowImageView];            
            
            return cell;
        }
        row = [indexPath row] - 1;
    }
    
    // If the section is the first one
    if ([indexPath section] == 0 && [indexPath row] == [[_nonExpiredNotificationsParty getObjectArray] count]) {
        return cell;
        if ([[_expiredNotificationsParty getObjectArray] count] == 0 &&
            [indexPath row] == [[_nonExpiredNotificationsParty getObjectArray] count]) {
            if ([_page intValue] < 5) [self fetchNotifications];
            return cell;
        }
    }
    
    // Else we are
    if ([indexPath section] == 1) {
        if ([_expiredNotificationsParty hasNextPage] && [[_expiredNotificationsParty getObjectArray] count] > 5) {
            if ([indexPath row] == [[_expiredNotificationsParty getObjectArray] count] - 5) {
                if ([_page intValue] < 5) [self fetchNotifications];
            }
        }
        else {
            if ([indexPath row] == [[_expiredNotificationsParty getObjectArray] count]) {
                if ([_page intValue] < 5) [self fetchNotifications];
                return cell;
            }
        }
    }
    
    if ([[_notificationsParty getObjectArray] count] == 0) return cell;
    Notification *notification = [self getNotificationAtIndex:indexPath];
//    NSLog(@"notification %@", notification);
    if (!notification) {
//        NSLog(@"here");
        if ([_notificationsParty hasNextPage]) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
            spinner.center = cell.contentView.center;
            [cell.contentView addSubview:spinner];
            [spinner startAnimating];
        }
        return cell;
    }
    if ([notification fromUserID] == (id)[NSNull null]) return cell;
    // When group is unlocked
    if ([[notification type] isEqualToString:@"group.unlocked"]) return cell;
    
    User *user = [[User alloc] initWithDictionary:[notification fromUser]];
    
    NSString *name = [user firstName];
    NSString *typeString = [notification type];
    NSString *message = [notification message];
    NSString *timeString = [notification timeString];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 60, 54)];
    
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(15, HEIGHT_NOTIFICATION_CELL/2 - 22, 45, 45);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
    profileImageView.layer.cornerRadius = 5;
    profileImageView.layer.borderWidth = 0.5;
    profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UIButton *buttonCallback;
    if ([typeString isEqualToString:@"tap"] && ![notification expired] &&
             [user isAttending] ) {
        if (![[Profile user] isGoingOut] || ([[Profile user] isAttending] && ![[[Profile user] attendingEventID] isEqualToNumber:[user attendingEventID]]) || ([[Profile user] isGoingOut] && ![[Profile user] isAttending])) {
            buttonCallback = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, HEIGHT_NOTIFICATION_CELL/2 - 20, 49, 40)];
            [buttonCallback setTitle:@"Go\nHere" forState:UIControlStateNormal];
            [buttonCallback setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            buttonCallback.titleLabel.font = [FontProperties scMediumFont:12.0f];
            buttonCallback.titleLabel.textAlignment = NSTextAlignmentCenter;
            buttonCallback.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            buttonCallback.titleLabel.numberOfLines = 0;
            buttonCallback.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            buttonCallback.layer.borderWidth = 1.0f;
            buttonCallback.layer.cornerRadius = 7.0f;
            buttonCallback.tag = row;
            [buttonCallback addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    else if ([typeString isEqualToString:@"follow"] || [typeString isEqualToString:@"facebook.follow"] || [typeString isEqualToString:@"follow.accepted"]) {
         buttonCallback = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, HEIGHT_NOTIFICATION_CELL/2 - 15, 49, 30)];
        if ([user getUserState] == BLOCKED_USER) {
            [buttonCallback setBackgroundImage:nil forState:UIControlStateNormal];
            [buttonCallback setTitle:@"Blocked" forState:UIControlStateNormal];
            [buttonCallback setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            buttonCallback.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            buttonCallback.titleLabel.textAlignment = NSTextAlignmentCenter;
            buttonCallback.layer.borderWidth = 1;
            buttonCallback.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            buttonCallback.layer.cornerRadius = 3;
            buttonCallback.tag = 50;
        }
        else {
            if ([user isFollowing]) {
                [buttonCallback setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                buttonCallback.tag = 100;
            }
            else {
                [buttonCallback setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
                buttonCallback.tag = - 100;
            }
        }
        [buttonCallback addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];

    int tag;
    if ([indexPath section] == 0) {
        tag = (int)[indexPath row];
        tag += 1;
    }
    else {
        tag = - (int)[indexPath row];
        tag -= 1;
    }
    notificationButton.tag = tag;
    [cell.contentView addSubview:buttonCallback];
    
    UILabel *notificationLabel = [[UILabel alloc] init];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:name ];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:nil]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:message attributes:nil]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, name.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(name.length , message.length + 1)];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",timeString ] attributes:nil]];
    [string addAttribute:NSFontAttributeName value:[FontProperties getBioFont] range:NSMakeRange(0, string.length - timeString.length)];
    [string addAttribute:NSFontAttributeName value:[FontProperties getSmallPhotoFont] range:NSMakeRange(string.length - timeString.length, timeString.length)];
    [string addAttribute:NSForegroundColorAttributeName value:RGB(201, 202, 204) range:NSMakeRange(string.length - timeString.length, timeString.length)];
    notificationLabel.attributedText = string;
    notificationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    notificationLabel.numberOfLines = 0;
    notificationLabel.frame = CGRectMake(70, HEIGHT_NOTIFICATION_CELL/2 - 35, 175, 70);
    [notificationButton addSubview:notificationLabel];
    
    [cell.contentView addSubview:notificationButton];
    if ([(NSNumber *)[notification objectForKey:@"id"] intValue] > [(NSNumber *)[[Profile user] lastNotificationRead] intValue]) {
        cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    }
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView
heightForFooterInSection:(NSInteger)section
{
    if (section == 0 && [[_nonExpiredNotificationsParty getObjectArray] count] > 0)
        return HEADER_HEIGHT_CELL;
    else return 0;
}

-(UIView *) tableView:(UITableView *)tableView
viewForFooterInSection:(NSInteger)section
{
    if (section == 1) {
        return [[UIView alloc] init];
    }
    else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT_CELL)];
        headerView.backgroundColor = [UIColor whiteColor];
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, HEADER_HEIGHT_CELL/2 - 2, self.view.frame.size.width, 1)];
        lineView.backgroundColor = RGBAlpha(201, 202, 204, 0.6f);
        [headerView addSubview:lineView];
        
        
        UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, HEADER_HEIGHT_CELL/2 + 2, self.view.frame.size.width, 1)];
        lineView2.backgroundColor = RGBAlpha(201, 202, 204, 0.6f);
        [headerView addSubview:lineView2];
        
        UILabel *todayLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 50, HEADER_HEIGHT_CELL/2 - 15, 100, 30)];
        todayLabel.text = @"TODAY";
        todayLabel.backgroundColor = [UIColor whiteColor];
        todayLabel.textColor = RGBAlpha(201, 202, 204, 0.6f);
        todayLabel.font = [FontProperties mediumFont:15];
        todayLabel.textAlignment = NSTextAlignmentCenter;
        todayLabel.layer.borderWidth = 2.0f;
        todayLabel.layer.borderColor = RGBAlpha(201, 202, 204, 0.6f).CGColor;
        todayLabel.layer.cornerRadius = 10.0f;
        [headerView addSubview:todayLabel];
        
        UIImageView *upArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, todayLabel.frame.size.height/2 - 5, 8, 10)];
        upArrowImageView.image = [UIImage imageNamed:@"upArrow"];
        [todayLabel addSubview:upArrowImageView];
        
        UIImageView *upArrowImageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(todayLabel.frame.size.width - 8 - 10, todayLabel.frame.size.height/2 - 5, 8, 10)];
        upArrowImageView2.image = [UIImage imageNamed:@"upArrow"];
        [todayLabel addSubview:upArrowImageView2];
        
        return headerView;
    }

}

- (void)tapPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    [buttonSender.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:_notificationsTableView];
    NSIndexPath *indexPath = [_notificationsTableView indexPathForRowAtPoint:buttonOriginInTableView];
    Notification *notification = [self getNotificationAtIndex:indexPath];
    if (notification) {
        User *user = [[User alloc] initWithDictionary:[notification fromUser]];
        if (user) {
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Notifications", @"Go Here Source", nil];
            [EventAnalytics tagEvent:@"Go Here" withDetails:options];
            [[Profile user] setIsAttending:YES];
            [[Profile user] setIsGoingOut:YES];
            [[Profile user] setAttendingEventID:[user attendingEventID]];
            UITabBarController *tabBarController = (UITabBarController *)self.parentViewController.parentViewController;
            tabBarController.selectedViewController
            = [tabBarController.viewControllers objectAtIndex:1];
            [Network postGoingToEventNumber:[[user attendingEventID] intValue]];
        }
    }

}

- (void)followedPersonPressed:(id)sender {
    //Get Index Path
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:_notificationsTableView];
    NSIndexPath *indexPath = [_notificationsTableView indexPathForRowAtPoint:buttonOriginInTableView];
    Notification *notification = [self getNotificationAtIndex:indexPath];
    if (notification) {
        User *user = [[User alloc] initWithDictionary:[notification fromUser]];
        if (user) {
            UIButton *senderButton = (UIButton*)sender;
            if (senderButton.tag == 50) {
                [senderButton setTitle:nil forState:UIControlStateNormal];
                [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
                senderButton.tag = -100;
                [user setIsBlocked:NO];
                
                NSString *queryString = [NSString stringWithFormat:@"users/%@", [user objectForKey:@"id"]];
                NSDictionary *options = @{@"is_blocked": @NO};
                [Network sendAsynchronousHTTPMethod:POST
                                        withAPIName:queryString
                                        withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                                        withOptions:options];
            }
            else if (senderButton.tag == -100) {
                if ([user isPrivate]) {
                    [senderButton setBackgroundImage:nil forState:UIControlStateNormal];
                    [senderButton setTitle:@"Pending" forState:UIControlStateNormal];
                    [senderButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
                    senderButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
                    senderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                    senderButton.layer.borderWidth = 1;
                    senderButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
                    senderButton.layer.cornerRadius = 3;
                    [user setIsFollowingRequested:YES];
                }
                else {
                    [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                    [user setIsFollowing:YES];
                }
                senderButton.tag = 100;
                [Network followUser:user];
            }
            else {
                [senderButton setTitle:nil forState:UIControlStateNormal];
                [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
                senderButton.tag = -100;
                [user setIsFollowing:NO];
                [user setIsFollowingRequested:NO];
                [Network unfollowUser:user];
            }
            [notification setFromUser:[user dictionary]];
            if ([indexPath section] == 0) {
                if ([indexPath row] < [[_nonExpiredNotificationsParty getObjectArray] count]) {
                    [_nonExpiredNotificationsParty replaceObjectAtIndex:[indexPath row] withObject:notification];
                    [_notificationsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[indexPath row] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            else {
                if ([indexPath row] < [[_expiredNotificationsParty getObjectArray] count]) {
                    [_expiredNotificationsParty replaceObjectAtIndex:[indexPath row] withObject:notification];
                    [_notificationsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[indexPath row] inSection:1]] withRowAnimation:UITableViewRowAnimationNone];

                }
            }
        }

    }
}

- (Notification *)getNotificationAtIndex:(NSIndexPath *)indexPath {
    Notification *notification;
    if ([indexPath section] == 0) {
        int sizeOfArray = (int)[[_nonExpiredNotificationsParty getObjectArray] count];
        if (sizeOfArray > 0 && sizeOfArray > [indexPath row])
            notification = [[_nonExpiredNotificationsParty getObjectArray] objectAtIndex:[indexPath row]];
    }
    else {
        int sizeOfArray = (int)[[_expiredNotificationsParty getObjectArray] count];
        if (sizeOfArray > 0 && sizeOfArray > [indexPath row])
            notification = [[_expiredNotificationsParty getObjectArray] objectAtIndex:[indexPath row]];
    }
    return notification;
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

- (NSIndexPath *)indexPathFromTag:(int)tag {
    if (tag < 0) {
        tag = -tag;
        tag -= 1;
        return [NSIndexPath indexPathForRow:tag inSection:1];
    }
    else {
        tag -= 1;
        return [NSIndexPath indexPathForRow:tag inSection:0];
    }
}


- (void) profileSegue:(id)sender {
    UIButton *notificationButton = (UIButton *)sender;
    int tag = (int)notificationButton.tag;
    NSIndexPath *indexPath = [self indexPathFromTag:tag];
    didProfileSegue = YES;
    if ([indexPath section] == 0) {
        if ([indexPath row] < [[_nonExpiredNotificationsParty getObjectArray] count]) {
            Notification *notification = [[_nonExpiredNotificationsParty getObjectArray] objectAtIndex:[indexPath row]];
            User *user = [[User alloc] initWithDictionary:[notification fromUser]];
            self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
            [self.navigationController pushViewController:self.profileViewController animated:YES];
            self.tabBarController.tabBar.hidden = YES;
        }
    }
    else {
        if ([indexPath row] < [[_expiredNotificationsParty getObjectArray] count]) {
            Notification *notification = [[_expiredNotificationsParty getObjectArray] objectAtIndex:[indexPath row]];
            User *user = [[User alloc] initWithDictionary:[notification fromUser]];
            self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
            [self.navigationController pushViewController:self.profileViewController animated:YES];
            self.tabBarController.tabBar.hidden = YES;
        }
    }
   
}

#pragma mark - Refresh button

- (void)addRefreshToTable {
    [WiGoSpinnerView addDancingGToUIScrollView:_notificationsTableView withHandler:^{
        [self fetchEverything];
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
    if (!didProfileSegue) {
        [self fetchSummaryOfFollowRequests];
        [self fetchFirstPageNotifications];
        didProfileSegue = NO;
    }
}

- (void)fetchFirstPageNotifications {
    _page = @1;
    [self fetchNotifications];
}

- (void)fetchNotifications {
    if (!isFetchingNotifications) {
        isFetchingNotifications = YES;
        NSString *queryString;
        if (![_page isEqualToNumber:@1] && [_notificationsParty nextPageString]) {
            queryString = [_notificationsParty nextPageString];
        }
        else {
            queryString = [NSString stringWithFormat:@"notifications/?type__ne=follow.request&page=%@" ,[_page stringValue]];
        }
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                if ([_page isEqualToNumber:@1]) {
                    _notificationsParty = [[Party alloc] initWithObjectType:NOTIFICATION_TYPE];
                    _expiredNotificationsParty = [[Party alloc] initWithObjectType:NOTIFICATION_TYPE];
                    _nonExpiredNotificationsParty = [[Party alloc] initWithObjectType:NOTIFICATION_TYPE];
                }
                NSArray *arrayOfNotifications = [jsonResponse objectForKey:@"objects"];
                Notification *notification;
                for (int i = 0; i < [arrayOfNotifications count]; i++) {
                    NSDictionary *notificationDictionary = [arrayOfNotifications objectAtIndex:i];
                    notification = [[Notification alloc] initWithDictionary:notificationDictionary];
                    if ([notification expired]) {
                        [_expiredNotificationsParty addObject:(NSMutableDictionary *)notification];
                    }
                    else {
                        [_nonExpiredNotificationsParty addObject:(NSMutableDictionary *)notification];
                    }
                }
                [_notificationsParty addObjectsFromArray:arrayOfNotifications];
                NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
                [_notificationsParty addMetaInfo:metaDictionary];
                _page = @([_page intValue] + 1);
                [_notificationsTableView reloadData];
                [_notificationsTableView didFinishPullToRefresh];
                isFetchingNotifications = NO;
            });
        }];

    }
}


- (void)fetchSummaryOfFollowRequests {
    [Network queryAsynchronousAPI:@"notifications/summary/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ([[jsonResponse allKeys] containsObject:@"follow.request"])
                _followRequestSummary = (NSNumber *)[jsonResponse objectForKey:@"follow.request"];
            else
                _followRequestSummary = @0;
            [_notificationsTableView reloadData];
        });
    }];
}


@end
