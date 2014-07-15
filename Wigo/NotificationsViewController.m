//
//  NotificationsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "NotificationsViewController.h"
#import "Globals.h"

#import "SDWebImage/UIImageView+WebCache.h"
#import "WiGoSpinnerView.h"

@interface NotificationsViewController ()
@property int yPositionOfNotification;

@property UITableView *notificationsTableView;
@property NSMutableArray *notificationArray;
@property Party *notificationsParty;
@property Party *everyoneParty;

@property UIActivityIndicatorView *spinner;
@property NSNumber *page;

@end

@implementation NotificationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _everyoneParty = [Profile everyoneParty];
    _notificationsParty = [[Party alloc] initWithObjectName:@"Notification"];
    _page = @1;
    [self initializeTableNotifications];
    [self fetchNotifications];
}

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"notificationsSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
}



- (void) viewDidAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"NOTIFICATIONS";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
}

- (void) initializeTableNotifications {
    _notificationsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49)];
    _notificationsTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_notificationsTableView];
    _notificationsTableView.dataSource = self;
    _notificationsTableView.delegate = self;
    _notificationsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}


#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == [[_notificationsParty getObjectArray] count]) {
        return 30;
    }
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int hasNextPage = ([_notificationsParty hasNextPage] ? 1 : 0);
    return [[_notificationsParty getObjectArray] count] + hasNextPage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    if ([indexPath row] == [[_notificationsParty getObjectArray] count]) {
        _spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0,0,80,80)];
        [_spinner startAnimating];
        [cell.contentView addSubview:_spinner];
        [self fetchNotifications];
        return cell;
    }
    
    Notification *notifcation = [[_notificationsParty getObjectArray] objectAtIndex:[indexPath row]];
    User *user = (User *)[_everyoneParty getObjectWithId:[notifcation fromUserID]];
    
    NSString *name = [user fullName];
    NSString * typeString = [notifcation type];
    NSString *message = [notifcation message];
    NSString *timeString = [notifcation timeString];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
    
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    profileImageView.layer.cornerRadius = 3;
    profileImageView.layer.borderWidth = 1;
    profileImageView.backgroundColor = [UIColor whiteColor];
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UIImageView *iconLabel;
    if ([typeString isEqualToString:@"chat"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"commentFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(chatSegue) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([typeString isEqualToString:@"tap"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tapFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([typeString isEqualToString:@"follow"] || [typeString isEqualToString:@"facebook.follow"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"addedFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 17, 12);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([typeString isEqualToString:@"joined"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"joined"]];
        iconLabel.frame = CGRectMake(55, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    notificationButton.tag = [indexPath row];
    [notificationButton addSubview:iconLabel];

    UILabel *notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 11, 200, 18)];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:name ];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:nil]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:message attributes:nil]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, name.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(name.length , message.length + 1)];
    notificationLabel.attributedText = string;
    notificationLabel.font = [FontProperties getBioFont];
    notificationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    notificationLabel.numberOfLines = 0;
    if (notificationLabel.text.length > 32) {
        notificationLabel.frame = CGRectMake(80, 11, 200, 36);
    }
    [notificationButton addSubview:notificationLabel];
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 158, 37, 140, 12)];
    timeLabel.text = timeString;
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.font = [FontProperties getSmallPhotoFont];
    timeLabel.textColor = RGB(201, 202, 204);
    [notificationButton addSubview:timeLabel];
    
    [cell.contentView addSubview:notificationButton];
    return cell;
}

- (void) chatSegue {
    self.conversationViewController = [[ConversationViewController alloc] init];
    [self.navigationController pushViewController:self.conversationViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void) profileSegue:(id)sender {
    UIButton *notificationButton = (UIButton *)sender;
    int rowOfButtonSender = notificationButton.tag;
    Notification *notifcation = [[_notificationsParty getObjectArray] objectAtIndex:rowOfButtonSender];
    User *user = (User *)[_everyoneParty getObjectWithId:[notifcation fromUserID]];
    self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:self.profileViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)fetchNotifications {
    [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
    NSString *queryString = [NSString stringWithFormat:@"notifications/?page=%@" ,[_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [WiGoSpinnerView hideSpinnerForView:self.view];
            NSArray *arrayOfNotifications = [jsonResponse objectForKey:@"objects"];
            [_notificationsParty addObjectsFromArray:arrayOfNotifications];
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_notificationsParty addMetaInfo:metaDictionary];
            _page = @([_page intValue] + 1);
            [_notificationsTableView reloadData];
        });
    }];
}


@end
