//
//  ParallaxProfileViewController.m
//  Wigo
//
//  Created by Alex Grinman on 12/12/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "ParallaxProfileViewController.h"
#import <Parse/Parse.h>
#import "UIButtonAligned.h"
#import "ImageScrollView.h"

@interface ParallaxProfileViewController()<ImageScrollViewDelegate>

@property (nonatomic, strong) ImageScrollView *imageScrollView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *nameView;
@property (nonatomic, strong) UIView *headerButtonView;

@property UIPageControl *pageControl;

@property Party *notificationsParty;
@property NSNumber *page;
@property Party *nonExpiredNotificationsParty;
@property UITableView *notificationsTableView;

//favorite
@property UIButton *leftProfileButton;
@property UIButton *rightProfileButton;

//UI
@property UIButtonAligned *rightBarBt;
@property UIButton *followingButton;
@property UIButton *followersButton;
@property UIButton *followButton;
@property UILabel *followRequestLabel;

@property UIView *lastLineView;
@property UIView *nameOfPersonBackground;
@property UILabel *nameOfPersonLabel;
@property UIImageView *privateLogoImageView;

@end



BOOL isUserBlocked;
BOOL blockShown;
UIButton *tapButton;

@implementation ParallaxProfileViewController

#pragma  mark - Init
- (id)initWithUser:(User *)user {
    self = [super init];
    if (self) {
        [self setStateWithUser: user];
    }
    return self;
}

- (void) setStateWithUser: (User *) user {
    if ([Profile user] && user) {
        if ([user isEqualToUser:[Profile user]]) {
            self.user = [Profile user];
            self.userState = [self.user isPrivate] ? PRIVATE_PROFILE : PUBLIC_PROFILE;
        }
        else {
            self.user = user;
            self.userState = [user getUserState];
        }
        self.view.backgroundColor = [UIColor whiteColor];
        [self createImageScrollView];
    }
}

#pragma mark - View Delegate
- (void) viewDidLoad {
    [super viewDidLoad];
    
    blockShown = NO;


    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[NotificationCell class] forCellReuseIdentifier:kNotificationCellName];
    [self.tableView setTableHeaderView: self.imageScrollView];

    [self initializeNotificationHandlers];
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    
    NSString *isCurrentUser = (self.user == [Profile user]) ? @"Yes" : @"No";
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:isCurrentUser, @"Self", nil];
    
    [EventAnalytics tagEvent:@"Profile View" withDetails:options];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    _pageControl.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _pageControl.hidden = NO;
    //if ([self.user getUserState] == BLOCKED_USER) [self presentBlockPopView:self.user];
    _page = @1;
    [self fetchNotifications];
    [self updateLastNotificationsRead];
    [self updateBadge];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    [self createPageControl];


    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Image Scroll View 
- (void) createPageControl {
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.enabled = NO;
    _pageControl.currentPage = 0;
    _pageControl.currentPageIndicatorTintColor = UIColor.whiteColor;
    _pageControl.pageIndicatorTintColor = RGBAlpha(255, 255, 255, 0.4f);
    _pageControl.center = CGPointMake(self.navigationController.view.center.x, 20);
    
    [self.navigationController.view addSubview: _pageControl];
}

- (void) createImageScrollView {
    
    NSMutableArray *infoDicts = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [[self.user imagesURL] count]; i++) {
        NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithDictionary: @{@"user": self.user,
                                                                                       @"images": [self.user images],
                                                                                       @"index": [NSNumber numberWithInt: i]}];
        [infoDicts addObject: info];
    }
    
    
    CGFloat imageScrollViewDimension = [[UIScreen mainScreen] bounds].size.width;
    self.imageScrollView = [[ImageScrollView alloc] initWithFrame: CGRectMake(0, 0, imageScrollViewDimension, imageScrollViewDimension) imageURLs:[self.user imagesURL] infoDicts: infoDicts areaDicts: [self.user imagesArea]];
    self.imageScrollView.delegate = self;
}

- (void)pageChangedTo:(NSInteger)page {
    _pageControl.currentPage = page;
}

#pragma mark - Go Back
- (void) goBack {
    if (![self.user isEqualToUser:[Profile user]]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self.user dictionary]];
        if (isUserBlocked) [userInfo setObject:[NSNumber numberWithBool:isUserBlocked] forKey:@"is_blocked"];
        isUserBlocked = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUserAtTable" object:nil userInfo:userInfo];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
}

#pragma mark - Nav Bar Buttons

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"whiteBackIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) initializeRightBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        [barBt setTitle:@"Edit" forState:UIControlStateNormal];
        [barBt addTarget:self action: @selector(editPressed) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [barBt setTitle:@"More" forState:UIControlStateNormal];
        [barBt addTarget:self action: @selector(morePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [barBt sizeToFit];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.rightBarButtonItem = barItem;
}



- (void) editPressed {
    self.editProfileViewController = [[EditProfileViewController alloc] init];
    self.editProfileViewController.view.backgroundColor = RGB(235, 235, 235);
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: self.editProfileViewController];
    [self presentViewController: navController animated: YES completion: nil];
}

#pragma mark Name View

#pragma mark Header Button View

#pragma mark Header Name View

#pragma mark Notification Handlers

- (void) initializeNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProfile) name:@"updateProfile" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unfollowPressed) name:@"unfollowPressed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockPressed:) name:@"blockPressed" object:nil];
}



#pragma mark - Table View Delegate


#define kImageViewSection 0
#define kNotificationsSection 1

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kNotificationsSection) {
        return [_nonExpiredNotificationsParty getObjectArray].count*10;
    }
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (indexPath.section == kNotificationsSection) {
        NotificationCell *notificationCell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellName forIndexPath:indexPath];
        Notification *notification = [[_nonExpiredNotificationsParty getObjectArray] objectAtIndex:[indexPath row] % [_nonExpiredNotificationsParty getObjectArray].count];
        if ([notification fromUserID] == (id)[NSNull null]) return notificationCell;
        if ([[notification type] isEqualToString:@"group.unlocked"]) return notificationCell;
        User *user = [[User alloc] initWithDictionary:[notification fromUser]];
        [notificationCell.profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
        notificationCell.descriptionLabel.text = [NSString stringWithFormat:@"%@ %@", [user firstName] ,[notification message] ];
        return notificationCell;
    }
    
    else if (indexPath.section == kImageViewSection) {
        UITableViewCell *imageCell =[tableView dequeueReusableCellWithIdentifier: @"ImageScrollViewCell" forIndexPath:indexPath];
        
        [self.imageScrollView removeFromSuperview];
        [imageCell.contentView addSubview: self.imageScrollView];
        return imageCell;
    }
    
    return nil;

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kImageViewSection) {
        return nil;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kImageViewSection) {
        return 0.0f;
    }
    return self.nameView.frame.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kNotificationsSection) {
        return 54;
    } else if (indexPath.section == kImageViewSection) {
        return self.imageScrollView.frame.size.height - self.nameView.frame.size.height;
    }
    
    return 0;

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < 0) {
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    }
}



#pragma mark - Notifications Network requests

- (void)fetchNotifications {
    if (!self.isFetchingNotifications) {
        self.isFetchingNotifications = YES;
        NSString *queryString;
        if (![_page isEqualToNumber:@1] && [_notificationsParty nextPageString]) {
            queryString = [_notificationsParty nextPageString];
        }
        else {
            queryString = [NSString stringWithFormat:@"notifications/?type__ne=follow.request&page=%@" ,[_page stringValue]];
        }
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ([_page isEqualToNumber:@1]) {
                    _notificationsParty = [[Party alloc] initWithObjectType:NOTIFICATION_TYPE];
                    _nonExpiredNotificationsParty = [[Party alloc] initWithObjectType:NOTIFICATION_TYPE];
                }
                NSArray *arrayOfNotifications = [jsonResponse objectForKey:@"objects"];
                Notification *notification;
                for (int i = 0; i < [arrayOfNotifications count]; i++) {
                    NSDictionary *notificationDictionary = [arrayOfNotifications objectAtIndex:i];
                    notification = [[Notification alloc] initWithDictionary:notificationDictionary];
                    if (![notification expired]) {
                        [_nonExpiredNotificationsParty addObject:(NSMutableDictionary *)notification];
                    }
                }
                [_notificationsParty addObjectsFromArray:arrayOfNotifications];
                NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
                [_notificationsParty addMetaInfo:metaDictionary];
                _page = @([_page intValue] + 1);
                [self.tableView reloadData];
                [self.tableView didFinishPullToRefresh];
                self.isFetchingNotifications = NO;
            });
        }];
        
    }
}

- (void)updateLastNotificationsRead {
    User *profileUser = [Profile user];
    for (Notification *notification in [_notificationsParty getObjectArray]) {
        if ([(NSNumber *)[notification objectForKey:@"id"] intValue] > [(NSNumber *)[[Profile user] lastNotificationRead] intValue]) {
            [profileUser setLastNotificationRead:[notification objectForKey:@"id"]];
            [profileUser saveKeyAsynchronously:@"last_notification_read" withHandler:^() {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                });
            }];
        }
    }
}

- (void)updateBadge {
    int total = 0;
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = total;
        [currentInstallation setValue:@"ios" forKey:@"deviceType"];
        currentInstallation[@"api_version"] = API_VERSION;
        [currentInstallation saveEventually];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:total];
    }
    
}
@end


@implementation NotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}


- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 54);
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSeparatorStyleNone;
    
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, self.frame.size.height/2 - 22, 45, 45)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.cornerRadius = 7;
    self.profileImageView.layer.borderWidth = 0.5;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.profileImageView];
    
    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, self.frame.size.height/2 - 22, self.frame.size.width - 70 - 80, 45)];
    self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
    self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.font = [FontProperties lightFont:15.0f];
    self.descriptionLabel.textColor = RGB(104, 104, 104);
    [self.contentView addSubview:self.descriptionLabel];
    
    self.buttonCallback = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 27 - 14, self.frame.size.height/2  - 13, 27, 27)];
    [self.buttonCallback addTarget:self action:@selector(tapPressed) forControlEvents:UIControlEventTouchUpInside];
    self.tapImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 27, 27)];
    self.tapImageView.image = [UIImage imageNamed:@"tapUnselectedNotification"];
    [self.buttonCallback addSubview:self.tapImageView];
    self.buttonCallback.hidden = YES;
    [self.contentView addSubview:self.buttonCallback];
    
    self.rightPostImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 32, self.frame.size.height/2 - 7, 9, 15)];
    self.rightPostImageView.image = [UIImage imageNamed:@"rightPostImage"];
    [self.contentView addSubview:self.rightPostImageView];
    
    self.tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 25 - 27, self.frame.size.height/2 + 13 + 3, 50, 15)];
    self.tapLabel.text = @"Tap back";
    self.tapLabel.textAlignment = NSTextAlignmentCenter;
    self.tapLabel.font = [FontProperties lightFont:12.0f];
    self.tapLabel.textColor = RGB(240, 203, 163);
    self.tapLabel.hidden = YES;
    [self.contentView addSubview:self.tapLabel];
}

- (void)tapPressed {
    if (self.isTapped) {
        self.tapImageView.image = [UIImage imageNamed:@"tapUnselectedNotification"];
    }
    else {
        self.tapImageView.image = [UIImage imageNamed:@"tapSelectedNotification"];
    }
    self.isTapped = !self.isTapped;
}

@end
