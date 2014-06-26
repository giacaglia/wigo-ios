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

@interface NotificationsViewController ()
@property int yPositionOfNotification;
@property UIScrollView *notificationScrollView;

@property UITableView *notificationsTableView;

@property NSMutableArray *notificationArray;

@end

@implementation NotificationsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeTableNotifications];
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
    NSDictionary *notification = @{@"name": @"Alice Banger", @"message": @"What's popping?", @"type": @"chat", @"timeString": @"2 hours ago"};
    _notificationArray = [[NSMutableArray alloc] initWithObjects:notification, nil];
    notification = @{@"name": @"Lisa Kerry", @"message": @"What are you up to?", @"type": @"chat", @"timeString": @"1 day ago"};
    [_notificationArray addObject:notification];
    notification = @{@"name": @"Greg Sono", @"message": @"wants to see you out tonight", @"type": @"tap", @"timeString": @"2 days ago"};
    [_notificationArray addObject:notification];
    notification = @{@"name": @"Lisa Kerry", @"message": @"is now following you", @"type": @"following", @"timeString": @"2 days ago"};
    [_notificationArray addObject:notification];
    notification = @{@"name": @"Brad Wang", @"message": @"joined WiGo", @"type": @"joined", @"timeString": @"2 days ago"};
    [_notificationArray addObject:notification];

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
    return [_notificationArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell*)[tableView
                                               dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                  reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];

    NSDictionary *notification = [_notificationArray objectAtIndex:[indexPath row]];
    NSString *name = [notification objectForKey:@"name"];
    NSString * typeString = [notification objectForKey:@"type"];
    NSString *message = [notification objectForKey:@"message"];
    NSString *timeString = [notification objectForKey:@"timeString"];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
    
    UIImageView *profileImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"giu3.jpg"]];
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
        [notificationButton addTarget:self action:@selector(profileSegue) forControlEvents:UIControlEventTouchDown];
    }
    else if ([typeString isEqualToString:@"following"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"addedFilled"]];
        iconLabel.frame = CGRectMake(55, 20, 17, 12);
        [notificationButton addTarget:self action:@selector(profileSegue) forControlEvents:UIControlEventTouchDown];
    }
    else if ([typeString isEqualToString:@"joined"]) {
        iconLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"joined"]];
        iconLabel.frame = CGRectMake(55, 20, 14, 14);
        [notificationButton addTarget:self action:@selector(profileSegue) forControlEvents:UIControlEventTouchDown];
    }
    [notificationButton addSubview:iconLabel];
    
//    UILabel *profileLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, 140, 20)];
//    profileLabel.text = name;
//    profileLabel.textAlignment = NSTextAlignmentLeft;
//    profileLabel.font = [FontProperties getBioFont];
//    [profileLabel sizeToFit];
//    [notificationButton addSubview:profileLabel];
//    
//    UILabel *chatMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(80 + profileLabel.frame.size.width + 5, 8, self.view.frame.size.width - (80 + profileLabel.frame.size.width + 5), 20)];
//    chatMessageLabel.text = message;
//    chatMessageLabel.textAlignment = NSTextAlignmentLeft;
//    chatMessageLabel.font = [FontProperties getBioFont];
//    chatMessageLabel.textColor = [UIColor grayColor];
//    chatMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;
//    chatMessageLabel.numberOfLines = 0;
//    [notificationButton addSubview:chatMessageLabel];
    
    UILabel *notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 11, 200, 18)];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:name ];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@": " attributes:nil]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:message attributes:nil]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, name.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(name.length + 1, message.length + 1)];
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

- (void) profileSegue {
    self.profileViewController = [[ProfileViewController alloc] initWithProfile:NO];
    [self.navigationController pushViewController:self.profileViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}


@end
