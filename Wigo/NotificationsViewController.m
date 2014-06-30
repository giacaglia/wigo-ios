//
//  NotificationsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "NotificationsViewController.h"
#import "FontProperties.h"
#import <QuartzCore/QuartzCore.h>
#import "Network.h"
#import "Party.h"

#import "SDWebImage/UIImageView+WebCache.h"

@interface NotificationsViewController ()
@property int yPositionOfNotification;
@property UIScrollView *notificationScrollView;

@property UITableView *notificationsTableView;

@property NSMutableArray *notificationArray;
@property Party *notificationsParty;
@property Party *everyoneParty;

@end

@implementation NotificationsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _everyoneParty = [Profile everyoneParty];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [Network queryAsynchronousAPI:@"notifications/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSArray *arrayOfNotifications = [jsonResponse objectForKey:@"objects"];
            _notificationsParty = [[Party alloc] initWithObjectName:@"Notification"];
            [_notificationsParty addObjectsFromArray:arrayOfNotifications];
            [self initializeTableNotifications];
        });
    }];
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
    _notificationsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    _notificationsTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_notificationsTableView];
    _notificationsTableView.dataSource = self;
    _notificationsTableView.delegate = self;
    
    [_notificationsTableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)adjustHeightOfTableview
{
    CGFloat height = _notificationsTableView.contentSize.height;
    CGFloat maxHeight = _notificationsTableView.superview.frame.size.height - _notificationsTableView.frame.origin.y;

    
    if (height > maxHeight)
        height = maxHeight;
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect frame = _notificationsTableView.frame;
        frame.size.height = height;
        _notificationsTableView.frame = frame;
    }];
}


#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_notificationsParty getObjectArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    Notification *notifcation = [[_notificationsParty getObjectArray] objectAtIndex:[indexPath row]];
//    NSDictionary *notification = [_notificationArray objectAtIndex:[indexPath row]];
    User *user = (User *)[_everyoneParty getObjectWithId:[notifcation fromUserID]];
    
    NSString *name = [user fullName];
    NSString * typeString = [notifcation type];
    NSString *message = [notifcation message];
    NSString *timeString = [notifcation timeString];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
    
    UIImageView *profileImageView = [[UIImageView alloc] init];
    [profileImageView setImageWithURL:[[user imagesURL] objectAtIndex:0]];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.layer.cornerRadius = 3;
    profileImageView.layer.borderWidth = 1;
    profileImageView.backgroundColor = [UIColor whiteColor];
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UIImageView *iconLabel;
    if ([typeString isEqualToString:@"chat"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"commentFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(chatSegue) forControlEvents:UIControlEventTouchDown];
    }
    else if ([typeString isEqualToString:@"tap"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tapFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchDown];
    }
    else if ([typeString isEqualToString:@"follow"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"addedFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 17, 12);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchDown];
    }
    else if ([typeString isEqualToString:@"joined"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"joined"]];
        iconLabel.frame = CGRectMake(55, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchDown];
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


@end
