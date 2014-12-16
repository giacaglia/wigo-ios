//
//  ParallaxProfileViewController.m
//  Wigo
//
//  Created by Alex Grinman on 12/12/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "FancyProfileViewController.h"
#import <Parse/Parse.h>
#import "UIButtonAligned.h"
#import "ImageScrollView.h"
#import "ChatViewController.h"
#import "FXBlurView.h"
#import "RWBlurPopover.h"

@interface FancyProfileViewController()<ImageScrollViewDelegate> {
    UIImageView *_gradientImageView;
    NSMutableArray *_blurredImages;
}

@property (nonatomic, strong) ImageScrollView *imageScrollView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *nameView;
@property (nonatomic, strong) UIView *headerButtonView;
@property (nonatomic, strong) UIImageView *nameViewBackground;

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

@property UILabel *nameOfPersonLabel;
@property UIImageView *privateLogoImageView;

@end



BOOL isUserBlocked;
BOOL blockShown;
UIButton *tapButton;

@implementation FancyProfileViewController

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
    [self pageChangedTo: 0];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[NotificationCell class] forCellReuseIdentifier:kNotificationCellName];
    [self.tableView setTableHeaderView: self.imageScrollView];
    self.tableView.showsVerticalScrollIndicator = NO;
    
    [self initializeNotificationHandlers];
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    [self initializeNameOfPerson];
    [self initializeHeaderButtonView];
    
    NSString *isCurrentUser = (self.user == [Profile user]) ? @"Yes" : @"No";
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:isCurrentUser, @"Self", nil];

    [EventAnalytics tagEvent:@"Profile View" withDetails:options];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
    
    [_pageControl removeFromSuperview];
    _pageControl = nil;
    [_gradientImageView removeFromSuperview];
    _gradientImageView = nil;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //if ([self.user getUserState] == BLOCKED_USER) [self presentBlockPopView:self.user];
    _page = @1;
    [self fetchNotifications];
    [self updateLastNotificationsRead];
    [self updateBadge];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];


    if (!_gradientImageView) {
        _gradientImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, -1*[UIApplication sharedApplication].statusBarFrame.size.height, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height)];
        [_gradientImageView setImage: [UIImage imageNamed:@"topGradientBackground"]];
        
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                      forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        self.navigationController.navigationBar.translucent = YES;
        
        [self.navigationController.navigationBar insertSubview: _gradientImageView atIndex: 0];
    }
    
    if (!_pageControl) {
        [self createPageControl];
    }
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self reloadViewForUserState];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Image Scroll View 
- (void) createPageControl {
    _pageControl = [[UIPageControl alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 20)];
    _pageControl.enabled = NO;
    _pageControl.currentPage = 0;
    _pageControl.currentPageIndicatorTintColor = UIColor.whiteColor;
    _pageControl.pageIndicatorTintColor = RGBAlpha(255, 255, 255, 0.4f);
    _pageControl.numberOfPages = [[self.user imagesURL] count];
  
    _pageControl.center = CGPointMake(_nameView.center.x, _nameOfPersonLabel.frame.origin.y + _nameOfPersonLabel.frame.size.height);
    [_nameView addSubview: _pageControl];
//    [self.navigationController.navigationBar insertSubview: _pageControl aboveSubview: _gradientImageView];
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
    [self.tableView reloadData];
}

- (void)pageChangedTo:(NSInteger)page {
    _pageControl.currentPage = page;
    
    if (_blurredImages && page < _blurredImages.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_nameViewBackground setImage: [_blurredImages objectAtIndex: page]];
        });
        return;
    }
    
    if (!_blurredImages) {
        _blurredImages = [[NSMutableArray alloc] init];
    }
    
    UIImage *image = [self.imageScrollView getCurrentImage];
    if (!image) {
        return;
    }
    
    UIImage *blurredImage = [image blurredImageWithRadius:20.0f iterations:4 tintColor:[UIColor clearColor]];
    [_nameViewBackground setImage: blurredImage];
    [_blurredImages addObject: blurredImage];
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


- (void) morePressed {
    [[RWBlurPopover instance] presentViewController:[[MoreViewController alloc] initWithUser:self.user] withOrigin:0 andHeight:self.view.frame.size.height fromViewController:self.navigationController];
}
- (void) editPressed {
    self.editProfileViewController = [[EditProfileViewController alloc] init];
    self.editProfileViewController.view.backgroundColor = RGB(235, 235, 235);
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: self.editProfileViewController];
    [self presentViewController: navController animated: YES completion: nil];
}

#pragma mark Name View
- (void)initializeNameOfPerson {
    _nameView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width - 80, self.view.frame.size.width, 80)];
    
    _nameViewBackground = [[UIImageView alloc] initWithFrame: _nameView.bounds];
    _nameViewBackground.contentMode = UIViewContentModeBottom;
    _nameViewBackground.clipsToBounds = NO;
    _nameViewBackground.alpha = 0;
    [_nameView addSubview: _nameViewBackground];
    
    UIImageView *gradientBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    gradientBackground.image = [UIImage imageNamed:@"backgroundGradient"];
    [_nameView addSubview:gradientBackground];
    
    _nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 15, self.view.frame.size.width - 14, 50)];
    _nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
    _nameOfPersonLabel.text = [self.user fullName];
    _nameOfPersonLabel.textColor = [UIColor whiteColor];
    _nameOfPersonLabel.font = [FontProperties getSubHeaderFont];
    [_nameView addSubview:_nameOfPersonLabel];

    
    _privateLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 80 - 40 - 9, 16, 22)];
    _privateLogoImageView.image = [UIImage imageNamed:@"privateIcon"];
    if (self.userState == ACCEPTED_PRIVATE_USER || self.userState == NOT_YET_ACCEPTED_PRIVATE_USER || self.userState == PRIVATE_PROFILE) {
        _privateLogoImageView.hidden = NO;
    }
    else _privateLogoImageView.hidden = YES;
    [_nameView addSubview:_privateLogoImageView];
}

#pragma mark Header Button View
- (void)initializeHeaderButtonView {
    _headerButtonView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, 70)];
    _headerButtonView.backgroundColor = [UIColor whiteColor];
    
    CALayer *lowerBorder = [CALayer layer];
    lowerBorder.backgroundColor = [[[UIColor lightGrayColor] colorWithAlphaComponent: 0.5f] CGColor];
    lowerBorder.frame = CGRectMake(0, _headerButtonView.frame.size.height, CGRectGetWidth(_headerButtonView.frame), 0.5f);
    [_headerButtonView.layer addSublayer: lowerBorder];
    
    if (self.userState != FOLLOWING_USER) {
        
        return;
    }
    
    _leftProfileButton = [[UIButton alloc] init];
    _leftProfileButton.frame = CGRectMake(0, 0, self.view.frame.size.width/3, 70);
    [_leftProfileButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *numberOfFollowersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, _leftProfileButton.frame.size.width, 25)];
    numberOfFollowersLabel.textColor = [FontProperties getOrangeColor];
    numberOfFollowersLabel.font = [FontProperties mediumFont:20.0f];
    numberOfFollowersLabel.textAlignment = NSTextAlignmentCenter;
    numberOfFollowersLabel.text = [(NSNumber*)[self.user objectForKey:@"num_followers"] stringValue];
    [_leftProfileButton addSubview:numberOfFollowersLabel];
    
    UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, _leftProfileButton.frame.size.width, 20)];
    followersLabel.textColor = [FontProperties getOrangeColor];
    followersLabel.font = [FontProperties scMediumFont:16];
    followersLabel.textAlignment = NSTextAlignmentCenter;
    followersLabel.text = @"followers";
    [_leftProfileButton addSubview:followersLabel];
    [_headerButtonView addSubview:_leftProfileButton];
    
    _rightProfileButton = [[UIButton alloc] init];
    [_rightProfileButton addTarget:self action:@selector(followingButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _rightProfileButton.frame = CGRectMake(self.view.frame.size.width/3, 0, self.view.frame.size.width/3, 70);
    UILabel *numberOfFollowingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, _rightProfileButton.frame.size.width, 25)];
    numberOfFollowingLabel.textColor = [FontProperties getOrangeColor];
    numberOfFollowingLabel.font = [FontProperties mediumFont:20.0f];
    numberOfFollowingLabel.textAlignment = NSTextAlignmentCenter;
    numberOfFollowingLabel.text = [(NSNumber*)[self.user objectForKey:@"num_following"] stringValue];
    [_rightProfileButton addSubview:numberOfFollowingLabel];
    
    UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, _rightProfileButton.frame.size.width, 20)];
    followingLabel.textColor = [FontProperties getOrangeColor];
    followingLabel.font = [FontProperties scMediumFont:16.0F];
    followingLabel.textAlignment = NSTextAlignmentCenter;
    followingLabel.text = @"following";
    [_rightProfileButton addSubview:followingLabel];
    
    [_headerButtonView addSubview:_rightProfileButton];
    
    UIButton *chatButton = [[UIButton alloc] initWithFrame:CGRectMake(2*self.view.frame.size.width/3, 0, self.view.frame.size.width/3, 70)];
    [chatButton addTarget:self action:@selector(chatPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, chatButton.frame.size.width, 20)];
    chatLabel.textAlignment = NSTextAlignmentCenter;
    chatLabel.text = @"chats";
    chatLabel.textColor = [FontProperties getOrangeColor];
    chatLabel.font = [FontProperties scMediumFont:16.0f];
    [chatButton addSubview:chatLabel];
    
    UIImageView *orangeChatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(chatButton.frame.size.width/2 - 10, 10, 20, 20)];
    [chatButton addSubview:orangeChatBubbleImageView];
    UILabel *numberOfChatsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, orangeChatBubbleImageView.frame.size.width, orangeChatBubbleImageView.frame.size.height - 4)];
    numberOfChatsLabel.textAlignment = NSTextAlignmentCenter;
    numberOfChatsLabel.textColor = UIColor.whiteColor;
    numberOfChatsLabel.font = [FontProperties scMediumFont:16.0f];
    NSNumber *unreadChats = (NSNumber *)[self.user objectForKey:@"num_unread_conversations"];
    if (![unreadChats isEqualToNumber: @0]) {
        orangeChatBubbleImageView.image = [UIImage imageNamed:@"orangeChatBubble"];
        numberOfChatsLabel.text = [NSString stringWithFormat: @"%@", unreadChats];
    } else {
        orangeChatBubbleImageView.image = [UIImage imageNamed:@"chatsIcon"];
    }
    [orangeChatBubbleImageView addSubview:numberOfChatsLabel];
    
    [_headerButtonView addSubview:chatButton];
}

- (void)leftProfileButtonPressed {
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        [self followersButtonPressed];
    }
}

- (void)followersButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@3] animated:YES];
}

- (void)followingButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@4] animated:YES];
}

- (void)chatPressed {
    ChatViewController *chatViewController = [ChatViewController new];
    chatViewController.view.backgroundColor = UIColor.whiteColor;
    [self.navigationController pushViewController:chatViewController animated:YES];
}


#pragma mark User State

- (void) reloadViewForUserState {
    if (self.userState == FOLLOWING_USER ||
        self.userState == ATTENDING_EVENT_FOLLOWING_USER ||
        self.userState == ATTENDING_EVENT_ACCEPTED_PRIVATE_USER) {
        
        _followingButton.enabled = YES;
        _followingButton.hidden = NO;
        _followersButton.enabled = YES;
        _followersButton.hidden = NO;
        _leftProfileButton.enabled = YES;
        _leftProfileButton.hidden = NO;
        _rightProfileButton.enabled = YES;
        _rightProfileButton.hidden = NO;
        _rightBarBt.enabled = YES;
        _rightBarBt.hidden = NO;
        
        _followButton.enabled = NO;
        _followButton.hidden = YES;
        
        _privateLogoImageView.hidden = YES;
        _followRequestLabel.hidden = YES;
    }
    else if (self.userState == NOT_FOLLOWING_PUBLIC_USER ||
             self.userState == NOT_SENT_FOLLOWING_PRIVATE_USER ||
             self.userState == BLOCKED_USER) {
        _followingButton.enabled = NO;
        _followingButton.hidden = YES;
        _followersButton.enabled = NO;
        _followersButton.hidden = YES;
        _leftProfileButton.enabled = NO;
        _leftProfileButton.hidden = YES;
        _rightProfileButton.enabled = NO;
        _rightProfileButton.hidden = YES;
        
        _followButton.enabled = YES;
        _followButton.hidden = NO;
        
        if (self.userState == NOT_FOLLOWING_PUBLIC_USER) _privateLogoImageView.hidden = YES;
        else _privateLogoImageView.hidden = NO;
        _followRequestLabel.hidden = YES;
    }
    else if (self.userState == NOT_YET_ACCEPTED_PRIVATE_USER) {
        _followingButton.enabled = NO;
        _followingButton.hidden = YES;
        _followersButton.enabled = NO;
        _followersButton.hidden = YES;
        _leftProfileButton.enabled = NO;
        _leftProfileButton.hidden = YES;
        _rightProfileButton.enabled = NO;
        _rightProfileButton.hidden = YES;
        
        _followButton.enabled = NO;
        _followButton.hidden = YES;
        
        _privateLogoImageView.hidden = YES;
        _followRequestLabel.hidden = NO;
    }
    if (self.userState == PUBLIC_PROFILE || self.userState == PRIVATE_PROFILE) {
        _followingButton.enabled = NO;
        _followingButton.hidden = YES;
        _followersButton.enabled = NO;
        _followersButton.hidden = YES;
        _followButton.enabled = NO;
        _followButton.hidden = YES;
        
        _leftProfileButton.enabled = YES;
        _leftProfileButton.hidden = NO;
        _rightProfileButton.enabled = YES;
        _rightProfileButton.hidden = NO;
        
        if (self.userState == PRIVATE_PROFILE) _privateLogoImageView.hidden = NO;
        else _privateLogoImageView.hidden = YES;
        _followRequestLabel.hidden = YES;
    }
}


#pragma mark Notification Handlers

- (void) initializeNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProfile) name:@"updateProfile" object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unfollowPressed) name:@"unfollowPressed" object:nil];
   // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockPressed:) name:@"blockPressed" object:nil];
}


- (void) updateProfile {
    [self.tableView reloadData];
}

#pragma mark - Table View Helpers

- (BOOL) shouldShowGoOutsCell {
    if (self.userState == NOT_SENT_FOLLOWING_PRIVATE_USER ||
        self.userState == NOT_YET_ACCEPTED_PRIVATE_USER) {
        return NO;
    }
    
    return YES;
}

- (BOOL) shouldShowInviteCell {
    if (self.userState == PUBLIC_PROFILE || self.userState == PRIVATE_PROFILE) {
        return NO;
    }
    
    if (self.userState == FOLLOWING_USER) {
        return YES;
    }

    
    return YES;
}

- (NSInteger) notificationCount {
    if (self.userState == PUBLIC_PROFILE || self.userState == PRIVATE_PROFILE) {
        return [_nonExpiredNotificationsParty getObjectArray].count*2;
    }
    
    return 0;
}

#pragma mark - Table View Delegate

#define kImageViewSection 0
#define kNotificationsSection 1
#define kGoOutsSection 2


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == kGoOutsSection) {
        return ([self shouldShowGoOutsCell]) ? 1 : 0;
    }
    else if (section == kNotificationsSection) {
        return [self notificationCount];
    }
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (indexPath.section == kGoOutsSection) {
        GoOutsCell *goOutsCell = [tableView dequeueReusableCellWithIdentifier: @"GoOutsCell" forIndexPath:indexPath];
        [goOutsCell setLabelsForUser: self.user];
        
        return goOutsCell;
    }
    
    else if (indexPath.section == kNotificationsSection) {
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
    if (section == kNotificationsSection) {
        UIView *headerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, tableView.frame.size.width, _nameView.frame.size.height + _headerButtonView.frame.size.height)];
        
        CGRect frame = _nameView.frame;
        frame.origin = CGPointMake(0, 0);
        _nameView.frame = frame;
        [headerView addSubview: _nameView];
        
        frame = _headerButtonView.frame;
        frame.origin = CGPointMake(0, _nameView.frame.size.height);
        _headerButtonView.frame = frame;
        [headerView addSubview: _headerButtonView];
        
        return headerView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kNotificationsSection) {
        return _nameView.frame.size.height + _headerButtonView.frame.size.height;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kGoOutsSection) {
        return [GoOutsCell rowHeight];
    }
    else if (indexPath.section == kNotificationsSection) {
        return 54;
    }
    else if (indexPath.section == kImageViewSection) {
        return self.imageScrollView.frame.size.height - _nameView.frame.size.height;
    }
    
    return 0;

}

#pragma mark - ScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < 0) {
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    }
    

    CGFloat defaultLength = self.imageScrollView.frame.size.height - _nameView.frame.size.height;
    CGFloat lengthFraction = (defaultLength - scrollView.contentOffset.y)/defaultLength;
    
    _privateLogoImageView.alpha = MIN(1.0, (defaultLength - scrollView.contentOffset.y)/defaultLength);
    _privateLogoImageView.alpha  = MAX(_privateLogoImageView.alpha, 0);
    
    _pageControl.alpha = _privateLogoImageView.alpha;
    _gradientImageView.alpha = _privateLogoImageView.alpha;
    
    _nameViewBackground.alpha = MIN(1.0, lengthFraction);
    _nameViewBackground.alpha  = 1 - MAX(_nameViewBackground.alpha, 0);
    
    
    CGFloat minFontSize = 24.0f;
    CGFloat maxFontSize = 30.0f;
    
    CGFloat currentSize = MIN(maxFontSize, maxFontSize - (maxFontSize - minFontSize)*(1 - lengthFraction));
    currentSize = MAX(currentSize, minFontSize);
    
    self.nameOfPersonLabel.font = [FontProperties lightFont: currentSize];
    
}

-(BOOL)isRowZeroVisible {
    return [self.tableView.indexPathsForVisibleRows indexOfObject: [NSIndexPath indexPathForRow:0 inSection:0]] != NSNotFound;
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

@implementation GoOutsCell

#define kTitleTemplate @"times %@ went out this term"

- (void) awakeFromNib {
    [self setup];
}


+ (CGFloat)rowHeight {
    return 100.0f;
}

- (void) setLabelsForUser: (User *) user {
    self.numberLabel.text = [NSString stringWithFormat: @"42"];
    self.titleLabel.text = [NSString stringWithFormat: kTitleTemplate, [user.firstName lowercaseString]];
}

- (void) setup {
    self.numberLabel.font = [FontProperties mediumFont: 55];
    self.numberLabel.textColor = [FontProperties getOrangeColor];
    self.titleLabel.font = [FontProperties mediumFont: 24];
    self.titleLabel.textColor = [UIColor lightGrayColor];
}

@end

@implementation InviteCell

#define kInviteTitleTemplate @"Invite %@ to join you at"

- (void) awakeFromNib {
    [self setup];
}


+ (CGFloat)rowHeight {
    return 70.0f;
}

- (void) setLabelsForUser: (User *) user {
    self.titleLabel.text = [NSString stringWithFormat: kInviteTitleTemplate, [user.firstName lowercaseString]];
}

- (void) setup {
    self.eventNameLabel.font = [FontProperties mediumFont: 18];
    self.eventNameLabel.textColor = [FontProperties getBlueColor];
    self.titleLabel.font = [FontProperties lightFont: 18];
    self.titleLabel.textColor = [UIColor lightGrayColor];
    
    [self.inviteButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    self.inviteButton.titleLabel.font =  [FontProperties scMediumFont:18.0f];
    self.inviteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    self.inviteButton.layer.cornerRadius = 3;
    
    [self.inviteButton addTarget: self action: @selector(inviteTapped) forControlEvents: UIControlEventTouchUpInside];
    
}
- (void) inviteTapped {
    [self.delegate inviteTapped];
}
@end
