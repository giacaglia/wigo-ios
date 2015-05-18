//  ParallaxProfileViewController.m
//  Wigo
//
//  Created by Alex Grinman on 12/12/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "ProfileViewController.h"
#import <Parse/Parse.h>
#import "UIButtonAligned.h"
#import "ChatViewController.h"
#import "FXBlurView.h"
#import "RWBlurPopover.h"
#import "EventPeopleScrollView.h"
#import "AppDelegate.h"

@interface ProfileViewController()<ImageScrollViewDelegate> {
    UIImageView *_gradientImageView;
    NSMutableArray *_blurredImages;
}

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *nameView;
@property (nonatomic, strong) UIView *headerButtonView;
@property (nonatomic, strong) UIImageView *nameViewBackground;
@property (nonatomic, strong) UIButton *rightProfileButton;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIImageView *locationImgView;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIImageView *workImgView;
@property (nonatomic, strong) UILabel *workLabel;
@property (nonatomic, strong) UIImageView *schoolImgView;
@property (nonatomic, strong) UILabel *schoolLabel;

//UI
@property (nonatomic, strong) UIButtonAligned *rightBarBt;
@property (nonatomic, strong) UIButton *followButton;

@property UILabel *nameOfPersonLabel;
@property UIImageView *privateLogoImageView;
@end

BOOL blockShown;

@implementation ProfileViewController

- (id)initWithUser:(WGUser *)user {
    self = [super init];
    if (self) {
        self.user = user;
    }
    return self;
}

- (void)setUser:(WGUser *)user {
    _user = user;
    self.userState = user.state;
}


#pragma mark - View Delegate
- (void) viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    blockShown = NO;
    [self pageChangedTo: 0];

    [self initializeTableView];
    [self initializeNotificationHandlers];
    [self initializeLeftBarButton];
    [self initializeNameOfPerson];
    [self initializeHeaderButtonView];
    [self initializeRightBarButton];

    self.edgesForExtendedLayout = UIRectEdgeAll;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if ([self.tableView respondsToSelector:@selector(layoutMargins)]) {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
    if (self.tabBarController) {
        self.tableView.frame = CGRectMake( self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width,  [UIApplication sharedApplication].keyWindow.frame.size.height - 44);
    }
    else {
         self.tableView.frame = CGRectMake( self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width,  [UIApplication sharedApplication].keyWindow.frame.size.height);
    }

}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleLightContent];
    self.tabBarController.navigationItem.titleView.hidden = NO;
    self.navigationController.navigationBar.barTintColor = [FontProperties getBlueColor];
    
    [self.pageControl removeFromSuperview];
    self.pageControl = nil;
    [_gradientImageView removeFromSuperview];
    _gradientImageView = nil;
    if (self.user.isCurrentUser) [self updateLastNotificationsRead];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initializeRightBarButton];
    self.tabBarController.navigationItem.titleView = nil;
    [self.imageScrollView.scrollView setContentSize:CGSizeMake((self.view.frame.size.width + 10) * [self.user.imagesURL count] - 10, [UIScreen mainScreen].bounds.size.width)];


    self.tableView.contentOffset = CGPointMake(0, 0);
    [self reloadViewForUserState];
    if (self.user.state == BLOCKED_USER_STATE) [self presentBlockPopView:self.user];
    if (self.user.isCurrentUser) {
        [self fetchUserInfo];
        self.lastNotificationRead = WGProfile.currentUser.lastNotificationRead;
    }
    else {
        __weak typeof(self) weakSelf = self;
        [self.user getMeta:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) return;
            strongSelf.userState = strongSelf.user.state;
            strongSelf.numberOfFriendsLabel.text = self.user.numFriends.stringValue;
            if (strongSelf.user.numFriends.intValue == 0 || strongSelf.user.numFriends.intValue == 1) strongSelf.friendsLabel.text = @"Friend";
            else strongSelf.friendsLabel.text = @"Friends";
            [strongSelf reloadViewForUserState];
            [strongSelf.tableView reloadData];
        }];

        if (self.user.state == SENT_OR_RECEIVED_REQUEST_USER_STATE ||
            self.user.state == NOT_FRIEND_STATE) {
            [self.user getMutualFriends:^(WGCollection *collection, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (error) return;
                strongSelf.mutualFriends = collection;
                [strongSelf.tableView reloadData];
            }];
  
        }
    }
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.backgroundColor = UIColor.clearColor;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.tabBarController.navigationItem.titleView = nil;

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    [_gradientImageView removeFromSuperview];

    if (!_gradientImageView) {
        _gradientImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, -1*[UIApplication sharedApplication].statusBarFrame.size.height, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height)];
        [_gradientImageView setImage: [UIImage imageNamed:@"topGradientBackground"]];
    }
    
   [self.navigationController.navigationBar insertSubview: _gradientImageView atIndex: 0];
    
    if (!self.pageControl) [self createPageControl];
    [self reloadViewForUserState];
    
    if ([self.user isEqual:WGProfile.currentUser]) {
        // TODO: Refetch notifications
        self.notifications = NetworkFetcher.defaultGetter.notifications;
        [self fetchFirstPageNotifications];
        [self updateBadge];
    }

}

- (void)initializeTableView {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame: CGRectZero];
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset: UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(layoutMargins)]) {
        [self.tableView setLayoutMargins: UIEdgeInsetsMake(0, self.view.frame.size.width, 0, 0)];
    }
    
    self.tableView.separatorColor = RGB(228, 228, 228);
    self.tableView.separatorColor = [self.tableView.separatorColor colorWithAlphaComponent: 0.0f];
    [self.tableView registerClass:[NotificationCell class] forCellReuseIdentifier:kNotificationCellName];
    [self.tableView registerClass:[InstaCell class] forCellReuseIdentifier:kInstaCellName];
    [self.tableView registerClass:[MutualFriendsCell class] forCellReuseIdentifier:kMutualFriendsCellName];
    self.tableView.showsVerticalScrollIndicator = NO;
    if (self.user) [self createImageScrollView];
    [self.tableView reloadData];
}

#pragma mark - Image Scroll View 
- (void) createPageControl {
    self.pageControl = [[UIPageControl alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 20)];
    self.pageControl.enabled = NO;
    self.pageControl.currentPage = 0;
    self.pageControl.currentPageIndicatorTintColor = UIColor.whiteColor;
    self.pageControl.pageIndicatorTintColor = RGBAlpha(255, 255, 255, 0.4f);
    self.pageControl.numberOfPages = self.user.imagesURL.count;
  
    self.pageControl.center = CGPointMake(_nameView.center.x, _nameOfPersonLabel.frame.origin.y + _nameOfPersonLabel.frame.size.height);
    [_nameView addSubview: self.pageControl];
}

- (void) createImageScrollView {
    CGFloat imageScrollViewDimension = [[UIScreen mainScreen] bounds].size.width;
    self.imageScrollView = [[ImageScrollView alloc] initWithFrame: CGRectMake(0, 0, imageScrollViewDimension, imageScrollViewDimension) andUser:self.user];
    self.imageScrollView.delegate = self;
    [self.tableView reloadData];
}

- (void)pageChangedTo:(NSInteger)page {
    self.pageControl.currentPage = page;
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
    if (!self.user.isCurrentUser) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self.user deserialize]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUserAtTable" object:nil userInfo:userInfo];
    }
    [self.navigationController setNavigationBarHidden:self.hideNavBar];
    //if presented sudo-modally
    if (!self.navigationController || self == self.navigationController.viewControllers[0]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    //if presented in a stack
    else {
        [self.navigationController popViewControllerAnimated: YES];
    }
}

#pragma mark - Nav Bar Buttons

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"whiteBackIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    // self.navigationItem.leftBarButtonItem = barItem;
    [self.navigationItem setLeftBarButtonItem:barItem animated:NO];
}

- (void) initializeRightBarButton {
    _rightBarBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [_rightBarBt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _rightBarBt.titleLabel.font = [FontProperties getSubtitleFont];
    
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] initWithCustomView:_rightBarBt];
    [self.navigationItem setRightBarButtonItem:barItem animated:NO];
    UIBarButtonItem *tabBarBt =  [[UIBarButtonItem alloc] initWithCustomView:_rightBarBt];
    self.tabBarController.navigationItem.rightBarButtonItem = tabBarBt;
    [self reloadViewForUserState];
}

-(void) morePressed {
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.view.bounds;
//    self.navigationController.navigationBar.alpha = 0.0f;
    self.moreVc = [MoreViewController new];
    self.moreVc.user = self.user;
    self.moreVc.profileDelegate = self;
    self.moreVc.view.alpha = 0.0f;
    self.moreVc.bgView = visualEffectView;
    [self addChildViewController:self.moreVc];
    [self.view addSubview:self.moreVc.view];
    [UIView animateWithDuration:0.3 animations:^{
        self.moreVc.view.alpha = 1.0f;
    }];
}

-(void) removeMoreVc {
    [self.moreVc willMoveToParentViewController:nil];
    [self.moreVc.view removeFromSuperview];
    [self.moreVc removeFromParentViewController];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.backgroundColor = UIColor.clearColor;
}

- (void) editPressed {    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: [EditProfileViewController new]];
    [self presentViewController: navController animated: YES completion: nil];
}

#pragma mark Name View
- (void)initializeNameOfPerson {
    _nameView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width - 80, self.view.frame.size.width, 80)];
    _nameView.userInteractionEnabled = NO;
     
    _nameViewBackground = [[UIImageView alloc] initWithFrame: _nameView.bounds];
    _nameViewBackground.contentMode = UIViewContentModeBottom;
    _nameViewBackground.clipsToBounds = NO;
    _nameViewBackground.userInteractionEnabled = NO;
    _nameViewBackground.alpha = 0;
    [_nameView addSubview: _nameViewBackground];
    
    UIImageView *gradientBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    gradientBackground.image = [UIImage imageNamed:@"backgroundGradient"];
    gradientBackground.userInteractionEnabled = NO;
    [_nameView addSubview:gradientBackground];
    
    _nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 15, self.view.frame.size.width - 14, 50)];
    _nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
    if (self.user.age.length > 0) _nameOfPersonLabel.text = [NSString stringWithFormat:@"%@, %@", self.user.fullName, self.user.age];
    else _nameOfPersonLabel.text = self.user.fullName;
    _nameOfPersonLabel.textColor = UIColor.whiteColor;
    _nameOfPersonLabel.font = [FontProperties lightFont:20.0f];
    _nameOfPersonLabel.userInteractionEnabled = NO;
    [_nameView addSubview:_nameOfPersonLabel];

    _privateLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 80 - 40 - 9, 16, 22)];
    _privateLogoImageView.image = [UIImage imageNamed:@"privateIcon"];
    _privateLogoImageView.userInteractionEnabled = NO;
    [_nameView addSubview:_privateLogoImageView];
}

#pragma mark Header Button View
- (void)initializeHeaderButtonView {
    _headerButtonView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, 70)];
    _headerButtonView.backgroundColor = UIColor.whiteColor;
    
    CALayer *lowerBorder = [CALayer layer];
    lowerBorder.backgroundColor = [[[UIColor lightGrayColor] colorWithAlphaComponent: 0.5f] CGColor];
    lowerBorder.frame = CGRectMake(0, 70, CGRectGetWidth(_headerButtonView.frame), 0.5f);
    [_headerButtonView.layer addSublayer: lowerBorder];
    
    _locationImgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 9, 12)];
    _locationImgView.image = [UIImage imageNamed:@"locationIcon"];
    [_headerButtonView addSubview:_locationImgView];
    
    _locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 9, 0.75*self.view.frame.size.width - 30, 14)];
    _locationLabel.text = self.user.group.name;
    _locationLabel.font = [FontProperties mediumFont:12.0f];
    _locationLabel.textAlignment = NSTextAlignmentLeft;
    [_headerButtonView addSubview:_locationLabel];
    
    _schoolImgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 22 + 5, 14, 11)];
    _schoolImgView.image = [UIImage imageNamed:@"schoolIcon"];
    [_headerButtonView addSubview:_schoolImgView];
    
    _schoolLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 22 + 5 - 2, 0.75*self.view.frame.size.width - 30, 14)];
    _schoolLabel.text = self.user.education;
    _schoolLabel.font = [FontProperties mediumFont:12.0f];
    _schoolLabel.textAlignment = NSTextAlignmentLeft;
    [_headerButtonView addSubview:_schoolLabel];
    
    _workImgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 38 + 5, 12, 10)];
    _workImgView.image = [UIImage imageNamed:@"workIcon"];
    [_headerButtonView addSubview:_workImgView];
    
    _workLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 38 + 5 - 2, 0.75*self.view.frame.size.width - 30, 14)];
    _workLabel.text = self.user.work;
    _workLabel.font = [FontProperties mediumFont:12.0f];
    _workLabel.textAlignment = NSTextAlignmentLeft;
    [_headerButtonView addSubview:_workLabel];
    
    // Center images
    [self centerIcons];
    
    UIView *lineDividerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width*0.75 - 1, 5, 0.5, 60)];
    lineDividerView.backgroundColor = RGB(205, 205, 205);
    [_headerButtonView addSubview:lineDividerView];
    
    _rightProfileButton = [[UIButton alloc] init];
    [_rightProfileButton addTarget:self action:@selector(friendsPressed) forControlEvents:UIControlEventTouchUpInside];
    _rightProfileButton.frame = CGRectMake(self.view.frame.size.width*0.75, 0, self.view.frame.size.width*0.25, 70);
    self.numberOfFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, _rightProfileButton.frame.size.width, 25)];
    self.numberOfFriendsLabel.textColor = RGB(80, 80, 80);
    self.numberOfFriendsLabel.font = [FontProperties mediumFont:20.0f];
    self.numberOfFriendsLabel.textAlignment = NSTextAlignmentCenter;
    self.numberOfFriendsLabel.text = self.user.numFriends.stringValue;
    [_rightProfileButton addSubview:self.numberOfFriendsLabel];
    
    self.friendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35, _rightProfileButton.frame.size.width, 20)];
    self.friendsLabel.textColor = RGB(137, 137, 137);
    self.friendsLabel.font = [FontProperties scMediumFont:16.0F];
    self.friendsLabel.textAlignment = NSTextAlignmentCenter;
    if (self.user.numFriends.intValue == 0 || self.user.numFriends.intValue == 1) self.friendsLabel.text = @"Friend";
    else self.friendsLabel.text = @"Friends";
    [_rightProfileButton addSubview:self.friendsLabel];
    [_headerButtonView addSubview:_rightProfileButton];
    
    _followButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 75, 10, 65, 50)];
    _followButton.center = CGPointMake((lineDividerView.frame.size.width + lineDividerView.frame.origin.x + _headerButtonView.frame.size.width)/2, _followButton.center.y);
    [_followButton setImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    [_followButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchUpInside];
    [_headerButtonView addSubview: _followButton];
    [_headerButtonView bringSubviewToFront: _followButton];
    
    if (!self.user.isCurrentUser) return;
    _headerButtonView.frame = CGRectMake(_headerButtonView.frame.origin.x, _headerButtonView.frame.origin.y, _headerButtonView.frame.size.width, _headerButtonView.frame.size.height + 30);
    UIView *notificationsHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 70, self.view.frame.size.width, 30)];
    notificationsHeaderView.backgroundColor = RGB(248, 248, 248);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.view.frame.size.width - 15, 30)];
    titleLabel.text = @"Notifications";
    titleLabel.font = [FontProperties lightFont:14.0f];
    titleLabel.textColor = RGB(150, 150, 150);
    [notificationsHeaderView addSubview:titleLabel];
    [_headerButtonView addSubview:notificationsHeaderView];
}

-(void) centerIcons {
    //City, education work
    int numberOfProperties = 3;
    if (!_locationLabel.text) {
        _locationLabel.hidden = YES;
        _locationImgView.hidden = YES;
        numberOfProperties -= 1;
    }
    if (!_workLabel.text) {
        _workLabel.hidden = YES;
        _workImgView.hidden = YES;
        numberOfProperties -= 1;
    }
    if (!_schoolLabel.text) {
        _schoolLabel.hidden = YES;
        _schoolImgView.hidden = YES;
        numberOfProperties -= 1;
    }
    if (numberOfProperties == 1) {
        CGAffineTransform scaleTrans  = CGAffineTransformMakeScale(2.0f, 2.0f);
        CGAffineTransform leftToRightTrans  = CGAffineTransformMakeTranslation(5.0f, 0);
        CGAffineTransform transl = CGAffineTransformConcat(scaleTrans, leftToRightTrans);
        _workLabel.textColor = RGB(170, 170, 170);
        _workLabel.font = [FontProperties mediumFont:18.0f];
        _schoolLabel.textColor = RGB(170, 170, 170);
        _schoolLabel.font = [FontProperties mediumFont:18.0f];
        _locationLabel.textColor = RGB(170, 170, 170);
        _locationLabel.font = [FontProperties mediumFont:18.0f];
        _workImgView.transform = transl;
        _schoolImgView.transform = transl;
        _locationImgView.transform = transl;
       
        _locationLabel.transform = leftToRightTrans;
        _locationLabel.center = _schoolLabel.center;
        _locationImgView.center = _schoolImgView.center;
        
        _workLabel.transform = leftToRightTrans;
        _workLabel.center = _schoolLabel.center;
        _workImgView.center = _workImgView.center;
    }
    if (numberOfProperties == 2) {
        _workLabel.font = [FontProperties lightFont:16.0f];
        _schoolLabel.font = [FontProperties lightFont:16.0f];
        _locationLabel.font = [FontProperties lightFont:16.0f];
        _workImgView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
        _schoolImgView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
        _locationImgView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
        _locationLabel.center = _schoolLabel.center;
        _workLabel.center = _schoolLabel.center;
        _locationImgView.center = _schoolImgView.center;
        _workImgView.center = _schoolImgView.center;
    }
    else {
        _locationImgView.center = CGPointMake(_schoolImgView.center.x, _locationImgView.center.y);
        _workImgView.center = CGPointMake(_schoolImgView.center.x, _workImgView.center.y);
    }
   
}

#pragma mark - Action Taps

- (void)blockPressed:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    self.user.isBlocked = @YES;
    self.userState = self.user.state;
    [self reloadViewForUserState];
    
    WGUser *sentUser = [WGUser serialize:[userInfo objectForKey:@"user"]];
    NSNumber *typeNumber = (NSNumber *)[userInfo objectForKey:@"type"];
    NSArray *blockTypeArray = @[@"annoying", @"not_student", @"abusive"];
    NSString *blockType = [blockTypeArray objectAtIndex:[typeNumber intValue]];
    if (blockShown) return;
    if (sentUser.isCurrentUser) return;
    blockShown = YES;
    __weak typeof(self) weakSelf = self;
    [WGProfile.currentUser block:sentUser withType:blockType andHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
        strongSelf.userState = strongSelf.user.state;
        [strongSelf reloadViewForUserState];
        [strongSelf presentBlockPopView:sentUser];
    }];
}

- (void)unblockPressed {
    self.user.isBlocked = @NO;
    self.userState = self.user.state;
    [self reloadViewForUserState];
    
    [WGProfile.currentUser unblock:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void){
            self.navigationController.navigationBar.barStyle = UIBarStyleDefault;}];
        self.userState = self.user.state;
        [self reloadViewForUserState];
    }];
}


- (void)followPressed {
    [self.user followUser];
    self.userState = self.user.state;
    [self reloadViewForUserState];
}

- (void)unfollowPressed {
    [self.user followUser];
    self.userState = self.user.state;
    [self reloadViewForUserState];
}


- (void)friendsPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@3] animated:YES];
}

- (void)chatPressed {
    if (self.user.isCurrentUser) {
        [self.navigationController pushViewController:[ChatViewController new] animated:YES];
        return;
    }
 
    [self.navigationController pushViewController:[[ConversationViewController alloc] initWithUser:self.user] animated:YES];
}


#pragma mark User State

- (void) reloadViewForUserState {
    _rightBarBt.hidden = YES;
    _rightProfileButton.hidden = YES;
    _chatButton.hidden = YES;
    _followButton.hidden = YES;
    _followButton.hidden = YES;
    _followButton.layer.cornerRadius = 0.0f;
    [_followButton setImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    [_followButton setTitle:nil forState:UIControlStateNormal];

    if (self.userState == NOT_LOADED_STATE ||
        self.userState == OTHER_SCHOOL_USER_STATE) {
        // Don't show anything
    }
    else if (self.userState == FRIEND_USER_STATE ||
        self.userState == CURRENT_USER_STATE) {
        _rightBarBt.hidden = NO;
        _rightProfileButton.hidden = NO;
        _chatButton.hidden = NO;
        if (self.user.privacy == PRIVATE) {
            _privateLogoImageView.hidden = NO;
        }
    }
    else if (self.userState == NOT_FRIEND_STATE ||
             self.userState == BLOCKED_USER_STATE) {
        _rightBarBt.hidden = NO;
        _followButton.hidden = NO;
    }
    else if (self.userState == SENT_OR_RECEIVED_REQUEST_USER_STATE) {
        _rightBarBt.hidden = NO;
        _followButton.hidden = NO;
        [_followButton setImage:nil forState:UIControlStateNormal];
        [_followButton setTitle:@"Pending" forState:UIControlStateNormal];
        [_followButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _followButton.titleLabel.font = [FontProperties mediumFont:15.0f];
        _followButton.backgroundColor = RGB(226, 226, 226);
        _followButton.layer.borderColor = UIColor.clearColor.CGColor;
        _followButton.layer.cornerRadius = 10.0f;
        _followButton.layer.borderWidth = 2.0f;
    }
    
    if (self.userState == CURRENT_USER_STATE) {
        [_rightBarBt setTitle:@" Edit" forState:UIControlStateNormal];
        [_rightBarBt removeTarget:nil
                           action:NULL
                 forControlEvents:UIControlEventAllEvents];
        [_rightBarBt addTarget:self action: @selector(editPressed) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_rightBarBt setTitle:@"More" forState:UIControlStateNormal];
        [_rightBarBt removeTarget:nil
                           action:NULL
                 forControlEvents:UIControlEventAllEvents];
        [_rightBarBt addTarget:self action: @selector(morePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    [_rightBarBt sizeToFit];
    
    if (self.user.privacy == PRIVATE) {
        _privateLogoImageView.hidden = NO;
    }
    else _privateLogoImageView.hidden = YES;

    
    [self.tableView reloadData];
}

#pragma mark - Block View

- (void)presentBlockPopView:(WGUser *)user {
    UIViewController *popViewController = [[UIViewController alloc] init];
    popViewController.view.frame = self.view.frame;
    popViewController.view.backgroundColor = RGBAlpha(244,149,45, 0.8f);
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 10, 65, 55)];
    [backButton setImage:[UIImage imageNamed:@"whiteBackIcon"] forState:UIControlStateNormal];
    [backButton setTitle:@" Back" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    backButton.titleLabel.font = [FontProperties getSubtitleFont];
    [backButton addTarget:self action: @selector(dismissAndGoBack) forControlEvents:UIControlEventTouchUpInside];
    [popViewController.view addSubview:backButton];
    
    UILabel *blockedLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height/2 - 60 - 40, popViewController.view.frame.size.width - 40, 120)];
    blockedLabel.text = [NSString stringWithFormat:@"%@ can't follow you or see any of your activity.", user.fullName];
    blockedLabel.textColor = [UIColor whiteColor];
    blockedLabel.numberOfLines = 0;
    blockedLabel.lineBreakMode = NSLineBreakByWordWrapping;
    blockedLabel.font = [FontProperties getSubHeaderFont];
    blockedLabel.textAlignment = NSTextAlignmentCenter;
    [popViewController.view addSubview:blockedLabel];
    
    UIButton *unblockButton = [[UIButton alloc] initWithFrame:CGRectMake(25, 64 + self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
    [unblockButton addTarget:self action:@selector(unblockPressed) forControlEvents:UIControlEventTouchUpInside];
    unblockButton.layer.cornerRadius = 15;
    unblockButton.layer.borderWidth = 1;
    unblockButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [unblockButton setTitle:[NSString stringWithFormat:@"Unblock %@", [user firstName]] forState:UIControlStateNormal];
    [unblockButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    unblockButton.titleLabel.font = [FontProperties scMediumFont:24.0f];
    [popViewController.view addSubview:unblockButton];
    
    [[RWBlurPopover instance] presentViewController:popViewController withOrigin:0 andHeight:popViewController.view.frame.size.height fromViewController:self.navigationController];
}

- (void)dismissAndGoBack {
    self.user.isBlocked = @NO;
    [[RWBlurPopover instance] dismissViewControllerAnimated:NO completion:^(void){
        [self goBack];
    }];
}

#pragma mark Notification Handlers

- (void) initializeNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProfile) name:@"updateProfile" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unfollowPressed) name:@"unfollowPressed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockPressed:) name:@"blockPressed" object:nil];
}


- (void) updateProfile {
    [self.tableView reloadData];
}

#pragma mark - Table View Helpers

- (BOOL) shouldShowInviteCell {
    if ([self.user isCurrentUser] ||
        self.userState == NOT_LOADED_STATE ||
        self.userState == NOT_FRIEND_STATE ||
        self.userState == BLOCKED_USER_STATE ||
        self.userState == OTHER_SCHOOL_USER_STATE) {
        return NO;
    }
    
    return YES;
}


- (NSInteger) notificationCount {
    if (self.userState == CURRENT_USER_STATE) {
        return self.notifications.count + 1;
    }
    return [self shouldShowInviteCell] ? 1 : 0;
}

#pragma mark - Table View Delegate

#define kImageViewSection 0
#define kNotificationsSection 1
#define kMutualFriendsSection 2
#define kInstagramSection 3

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kNotificationsSection) {
        return [self notificationCount];
    }
    if (section == kMutualFriendsSection) {
        if (self.user.state == NOT_FRIEND_STATE) {
            return 1;
        }
        return 0;
        
    }
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kImageViewSection) {
        UITableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier: @"ImageScrollViewCell" forIndexPath:indexPath];
        [self.imageScrollView removeFromSuperview];
        [imageCell.contentView addSubview: self.imageScrollView];
        return imageCell;
    } else if (indexPath.section == kNotificationsSection) {
        if ([self shouldShowInviteCell] && indexPath.row == 0) {
            InviteCell *inviteCell = [tableView dequeueReusableCellWithIdentifier:@"InviteCell" forIndexPath:indexPath];
            inviteCell.delegate = self;
            inviteCell.user = self.user;
            [inviteCell.chatButton addTarget:self action:@selector(chatPressed) forControlEvents:UIControlEventTouchUpInside];
            return inviteCell;
        }
        if ([self shouldShowInviteCell]) {
             indexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
        }
        NotificationCell *notificationCell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellName forIndexPath:indexPath];
        if (indexPath.row >= self.notifications.count) return notificationCell;
        WGNotification *notification = (WGNotification *)[self.notifications objectAtIndex:indexPath.row];
        notificationCell.notification = notification;
        if (WGProfile.currentUser.lastNotificationRead && [notification.created compare:WGProfile.currentUser.lastNotificationRead] != NSOrderedDescending ) {
            notificationCell.orangeNewView.hidden = YES;
        }
        else {
            if (!self.lastNotificationRead || [self.lastNotificationRead compare:notification.created] == NSOrderedAscending) {
                self.lastNotificationRead = notification.created;
            }
            notificationCell.orangeNewView.hidden = NO;
        }
        return notificationCell;
    }
    else if (indexPath.section == kMutualFriendsSection) {
        MutualFriendsCell *mutualFriendsCell = [tableView dequeueReusableCellWithIdentifier:kMutualFriendsCellName forIndexPath:indexPath];
        mutualFriendsCell.users = self.mutualFriends;
        return mutualFriendsCell;
    }
   else if (indexPath.section == kInstagramSection) {
       InstaCell *instaCell = [tableView dequeueReusableCellWithIdentifier: kInstaCellName forIndexPath:indexPath];
       instaCell.user = self.user;
       return instaCell;
   }

    
    return nil;

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kNotificationsSection) {
        if (self.userState == OTHER_SCHOOL_USER_STATE) {
            return _nameView;
        } else {
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

    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kNotificationsSection) {
        if (self.userState == OTHER_SCHOOL_USER_STATE) {
            return _nameView.frame.size.height;
        }
        
        return _nameView.frame.size.height + _headerButtonView.frame.size.height;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kImageViewSection) {
        return self.imageScrollView.frame.size.height - _nameView.frame.size.height;
    }
    else if (indexPath.section == kNotificationsSection) {
        if ([self shouldShowInviteCell] && indexPath.row == 0) return [InviteCell height];
        return 65;
    }
    else if (indexPath.section == kInstagramSection) {
        return [InstaCell height];
    }
    else if (indexPath.section == kMutualFriendsSection) {
        return [MutualFriendsCell height];
    }


    return 0;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section != kNotificationsSection) {
        return;
    }
    
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == kNotificationsSection && self.user.isCurrentUser) {
        WGNotification *notification = (WGNotification *)[self.notifications objectAtIndex:indexPath.row];
        WGUser *user = notification.fromUser;
        
        if ([notification.type isEqualToString:@"follow"] ||
            [notification.type isEqualToString:@"follow.accepted"] ||
            [notification.type isEqualToString:@"facebook.follow"]) {
            [self presentUser:user];
        }
        else if([notification.type isEqualToString:@"tap"]) {
            
            [(AppDelegate *)[UIApplication sharedApplication].delegate
             navigate:@"/events"];
            
        }
        else if([notification.type isEqualToString:@"invite"]) {
            
            [(AppDelegate *)[UIApplication sharedApplication].delegate
             navigate:notification.parameters[@"navigate"]];
            
        }
        else if([notification.type isEqualToString:@"eventmessage.vote"]) {
            
            [(AppDelegate *)[UIApplication sharedApplication].delegate
             navigate:notification.parameters[@"navigate"]];
            
        }
        else if (user.state != SENT_OR_RECEIVED_REQUEST_USER_STATE &&
                   user.state != NOT_FRIEND_STATE) {
            if (![user.eventAttending.id isEqual:notification.eventID]) return;
            if (user.eventAttending) [self presentEvent:user.eventAttending];
            else [self presentUser:user];
        }
    }
    else if (indexPath.section == kInstagramSection ) {
        InstaCell *instaCell = (InstaCell *)[tableView cellForRowAtIndexPath:indexPath];
        if ([instaCell hasInstaTextForUser:self.user]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.user.instaHandle;
        }
    }
    else return;
}

-(void) presentUser:(WGUser *)user {
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = user;
    profileViewController.events = self.events;
    [self.navigationController pushViewController: profileViewController animated: YES];
}

- (void)presentEvent:(WGEvent *)event {
    if (!self.navigationController || self == self.navigationController.viewControllers[0]) {
        if (self.placesDelegate) [self.placesDelegate showEvent:event];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    //if presented in a stack
    else {
        if (self.placesDelegate) [self.placesDelegate showEvent:event];
        [self.navigationController popViewControllerAnimated: YES];
    }

}

- (void)inviteTapped {
    [WGAnalytics tagAction:@"tap"
                    atView:@"profile"
            withTargetUser:self.user];
    
    self.user.isTapped = @YES;
    [WGProfile.currentUser tapUser:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
        [self.tableView reloadData];
    }];
}

#pragma mark WGViewController methods

- (void)updateViewWithOptions:(NSDictionary *)options {
    
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
    
    self.pageControl.alpha = _privateLogoImageView.alpha;
    _gradientImageView.alpha = _privateLogoImageView.alpha;
    
    
    _nameViewBackground.alpha = MIN(1.0, lengthFraction);
    _nameViewBackground.alpha  = 1 - MAX(_nameViewBackground.alpha, 0);
    
    
    CGFloat minFontSize = 15.0f;
    CGFloat maxFontSize = 20.0f;
    
    CGFloat currentSize = MIN(maxFontSize, maxFontSize - (maxFontSize - minFontSize)*(1 - lengthFraction));
    currentSize = MAX(currentSize, minFontSize);
    
    self.nameOfPersonLabel.font = [FontProperties lightFont: currentSize];
    
}

-(BOOL)isRowZeroVisible {
    return [self.tableView.indexPathsForVisibleRows indexOfObject: [NSIndexPath indexPathForRow:0 inSection:0]] != NSNotFound;
}


#pragma mark - Notifications Network requests

- (void) fetchUserInfo {
    if (!WGProfile.currentUser.key) return;
    
    __weak typeof(self) weakSelf = self;
    [WGProfile reload:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.user = WGProfile.currentUser;
        strongSelf.numberOfFriendsLabel.text = WGProfile.numFriends.stringValue;
        if (WGProfile.numFriends.intValue == 1) strongSelf.friendsLabel.text = @"Friend";
        else strongSelf.friendsLabel.text = @"Friends";
        strongSelf.imageScrollView.user = WGProfile.currentUser;
        strongSelf.pageControl.numberOfPages = WGProfile.currentUser.images.count;
        [strongSelf reloadViewForUserState];
    }];
    
    if (!WGProfile.numFriends) {
        __weak typeof(self) weakSelf = self;
        [NetworkFetcher.defaultGetter fetchMetaWithHandler:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.numberOfFriendsLabel.text = WGProfile.numFriends.stringValue;
            if (WGProfile.numFriends.intValue == 1) strongSelf.friendsLabel.text = @"Friend";
            else strongSelf.friendsLabel.text = @"Friends";
        }];
    }
    
}

- (void)fetchFirstPageNotifications {
    if (self.isFetchingNotifications) return;
    self.isFetchingNotifications = YES;
    
    __weak typeof(self) weakSelf = self;
    [WGNotification get:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isFetchingNotifications = NO;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        strongSelf.notifications = collection;
        strongSelf.tableView.separatorColor = [self.tableView.separatorColor colorWithAlphaComponent: 1.0f];
        [strongSelf.tableView reloadData];
    }];
}

- (void)fetchNextPageNotifications {
    if (self.isFetchingNotifications || !self.notifications.nextPage) return;
    self.isFetchingNotifications = YES;
    
    __weak typeof(self) weakSelf = self;
    [self.notifications addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isFetchingNotifications = NO;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        [strongSelf.tableView reloadData];
    }];
}

- (void)updateLastNotificationsRead {
    if (!WGProfile.currentUser.lastNotificationRead ||
        [self.lastNotificationRead compare:WGProfile.currentUser.lastNotificationRead] == NSOrderedDescending ||
        !WGProfile.currentUser.lastNotificationRead) {
        WGProfile.currentUser.lastNotificationRead = self.lastNotificationRead;
    }
    [TabBarAuxiliar checkIndex:kIndexOfProfile forDate:self.lastNotificationRead];
}

- (void)updateBadge {
    int total = 0;
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = total;
        [currentInstallation setValue:@"ios" forKey:@"deviceType"];
        currentInstallation[@"api_version"] = API_VERSION;
        [currentInstallation setObject:@2.0f forKey:@"api_version_num"];
        [currentInstallation saveEventually];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:total];
    }
    
}
@end

@implementation MutualFriendsCell

+ (CGFloat)height {
    return 105.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}


- (void) setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [MutualFriendsCell height]);
    self.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSeparatorStyleNone;
    
    self.mutualFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 140, 20)];
    self.mutualFriendsLabel.textColor = RGB(159, 159, 159);
    self.mutualFriendsLabel.textAlignment = NSTextAlignmentLeft;
    self.mutualFriendsLabel.font = [FontProperties mediumFont:15.0f];
    [self.contentView addSubview:self.mutualFriendsLabel];
    
    self.mutualFriendsCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 30, [UIScreen mainScreen].bounds.size.width, 60) collectionViewLayout:[[ScrollViewLayout alloc] initWithWidth:40]];
    [self.mutualFriendsCollection registerClass:[ScrollViewCell class] forCellWithReuseIdentifier:kScrollViewCellName];
    [self.mutualFriendsCollection registerClass:[UICollectionReusableView class]
                     forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                            withReuseIdentifier:kScrollViewHeader];
    self.mutualFriendsCollection.backgroundColor = UIColor.whiteColor;
    self.mutualFriendsCollection.dataSource = self;
    self.mutualFriendsCollection.delegate = self;
    self.mutualFriendsCollection.showsHorizontalScrollIndicator = NO;
    [self.contentView addSubview:self.mutualFriendsCollection];
}


- (void)setUsers:(WGCollection *)users {
    _users = users;
    if (users.total == 0) return;
    self.mutualFriendsLabel.text = [NSString stringWithFormat:@"%@ mutual friends", users.total];
    [self.mutualFriendsCollection reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.users.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ScrollViewCell *scrollCell = [collectionView dequeueReusableCellWithReuseIdentifier:kScrollViewCellName forIndexPath:indexPath];
    scrollCell.alpha = 1.0f;
    scrollCell.imgView.image = nil;
 
    scrollCell.imageButton.tag = indexPath.item;
    [scrollCell.imageButton removeTarget:nil
                                  action:NULL
                        forControlEvents:UIControlEventAllEvents];
    scrollCell.blueOverlayView.hidden = YES;
    scrollCell.goHereLabel.hidden = YES;
    scrollCell.profileNameLabel.alpha = 1.0f;
    scrollCell.user = (WGUser *)[self.users objectAtIndex:indexPath.item];
    return scrollCell;
}

#pragma mark - UICollectionView Header
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kScrollViewHeader
                                                                               forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(10, 1);
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
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 65);
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSeparatorStyleNone;
    
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 45, 45)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.center = CGPointMake(self.profileImageView.center.x, self.center.y);
    [self.contentView addSubview:self.profileImageView];
    
    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, self.frame.size.width - 70 - 50, self.frame.size.height)];
    self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
    self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.font = [FontProperties lightFont:15.0f];
    self.descriptionLabel.textColor = RGB(104, 104, 104);
    self.descriptionLabel.center = CGPointMake(self.descriptionLabel.center.x, self.center.y);
    [self.contentView addSubview:self.descriptionLabel];
    
    self.orangeNewView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 0, 17, 17)];
    self.orangeNewView.backgroundColor = [FontProperties getOrangeColor];
    self.orangeNewView.layer.cornerRadius = self.orangeNewView.frame.size.width/2;
    self.orangeNewView.layer.borderColor = UIColor.clearColor.CGColor;
    self.orangeNewView.layer.borderWidth = 1.0f;
    self.orangeNewView.hidden = YES;
    self.orangeNewView.center = CGPointMake(self.orangeNewView.center.x, self.center.y);
    [self.contentView addSubview:self.orangeNewView];
    
    self.tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 25 - 27, self.frame.size.height/2 + 13 + 3, 50, 15)];
    self.tapLabel.text = @"Tap back";
    self.tapLabel.textAlignment = NSTextAlignmentCenter;
    self.tapLabel.font = [FontProperties lightFont:12.0f];
    self.tapLabel.textColor = RGB(240, 203, 163);
    self.tapLabel.hidden = YES;
    [self.contentView addSubview:self.tapLabel];
    
    if ([self respondsToSelector:@selector(layoutMargins)]) {
        self.layoutMargins = UIEdgeInsetsZero;
    }
}

- (void)setNotification:(WGNotification *)notification {
    _notification = notification;
    WGUser *user = notification.fromUser;
    if (user) [self.profileImageView setSmallImageForUser:user completed:nil];
    else self.profileImageView.image = [UIImage imageNamed:@"wigoSystem"];
    self.descriptionLabel.text = notification.message;
}

@end

@implementation InstaCell

+ (CGFloat)height {
    return 60.0f;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) awakeFromNib {
    [self setup];
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [InstaCell height]);
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.instaLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [InstaCell height])];
    self.instaLabel.font = [FontProperties lightFont:20];
    self.instaLabel.textColor = [FontProperties getOrangeColor];
    self.instaLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.instaLabel];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    if ([self hasInstaTextForUser:user]) {
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Instagram: %@", user.instaHandle]];
        [string addAttribute:NSForegroundColorAttributeName value:UIColor.grayColor range:NSMakeRange(0,10)];
        [string addAttribute:NSForegroundColorAttributeName value:[FontProperties getOrangeColor] range:NSMakeRange(10, string.length - 10)];
        self.instaLabel.attributedText = string;
    }
}


- (BOOL)hasInstaTextForUser:(WGUser *)user {
    return user.instaHandle && user.instaHandle.length > 0 && ![user.instaHandle isEqual:@"@"];
}

@end

@implementation InviteCell


- (void) awakeFromNib {
    [self setup];
}

+ (CGFloat)height {
    return [UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width;
}

- (void)setUser:(WGUser *)user {
    _user = user;
    if (user.state != FRIEND_USER_STATE) {
        self.tapButton.hidden = YES;
        self.chatButton.hidden = YES;
        return;
    }
    self.tapButton.hidden = NO;
    self.chatButton.hidden = NO;
    float heightOfButton = self.frame.size.width/4.0f;
    if (user.isTapped.boolValue) {
        self.tapImageView.image = [UIImage imageNamed:@"blueTappedImageView"];
        self.tapLabel.text = @"TAPPED";
        self.tapLabel.frame = CGRectMake(self.tapLabel.frame.origin.x, heightOfButton/2 - 10, 70, 20);
        self.underlineTapLabel.hidden = YES;

    } else {
        self.tapImageView.image = [UIImage imageNamed:@"blueTapImageView"];
        self.tapLabel.text = @"TAP";
        self.tapLabel.frame = CGRectMake(self.tapLabel.frame.origin.x, heightOfButton/2 - 10 - 5, 70, 20);
        self.underlineTapLabel.hidden = NO;
    }
    
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [InviteCell height]);
    self.backgroundColor = RGB(252, 252, 252);

    float widthOfButton = [UIScreen mainScreen].bounds.size.width/2.4f;
    float heightOfButton = self.frame.size.width/4.0f;
    self.chatButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - widthOfButton - 20, 20, widthOfButton, heightOfButton)];
    self.chatButton.layer.cornerRadius = 27.0f;
    self.chatButton.layer.borderColor = RGB(216, 216, 216).CGColor;
    self.chatButton.layer.borderWidth = 0.5f;
    [self.contentView addSubview:self.chatButton];
    
    UIImageView *chatImageView = [[UIImageView alloc] initWithFrame:CGRectMake(widthOfButton/2 - 40 - 10, heightOfButton/2 - 20, 40, 40)];
    chatImageView.image = [UIImage imageNamed:@"blueChatImageView"];
    [self.chatButton addSubview:chatImageView];
    
    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(widthOfButton/2 - 10 + 5, heightOfButton/2 - 10, 60, 20)];
    chatLabel.text = @"CHAT";
    chatLabel.textAlignment = NSTextAlignmentCenter;
    chatLabel.font = [FontProperties mediumFont:20.0f];
    chatLabel.textColor = [FontProperties getBlueColor];
    [self.chatButton addSubview:chatLabel];
    
    self.tapButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 20, 20, widthOfButton, heightOfButton)];
    [self.tapButton addTarget:self action:@selector(inviteTapped) forControlEvents:UIControlEventTouchUpInside];
    self.tapButton.layer.cornerRadius = 27.0f;
    self.tapButton.layer.borderColor = RGB(216, 216, 216).CGColor;
    self.tapButton.layer.borderWidth = 0.5f;
    [self.contentView addSubview:self.tapButton];
    
    self.tapImageView = [[UIImageView alloc] initWithFrame:CGRectMake(widthOfButton/2 - 40 - 15 - 2.5, heightOfButton/2 - 20, 40, 40)];
    self.tapImageView.image = [UIImage imageNamed:@"blueTapImageView"];
    [self.tapButton addSubview:self.tapImageView];

    self.tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(widthOfButton/2 - 15 + 5, heightOfButton/2 - 10 - 5, 70, 20)];
    self.tapLabel.text = @"TAP";
    self.tapLabel.textAlignment = NSTextAlignmentLeft;
    self.tapLabel.font = [FontProperties mediumFont:20.0f];
    self.tapLabel.textColor = [FontProperties getBlueColor];
    [self.tapButton addSubview:self.tapLabel];
    
    self.underlineTapLabel = [[UILabel alloc] initWithFrame:CGRectMake(widthOfButton/2 - 15 + 5, heightOfButton/2 + 10 - 5, 70, 15)];
    self.underlineTapLabel.text = @"to see out";
    self.underlineTapLabel.textAlignment = NSTextAlignmentLeft;
    self.underlineTapLabel.textColor = [FontProperties getBlueColor];
    self.underlineTapLabel.font = [FontProperties lightFont:13.0f];
    [self.tapButton addSubview:self.underlineTapLabel];
}

-(void) inviteTapped {
    [self.delegate inviteTapped];
    self.tapButton.enabled = NO;
    WGUser *user = self.user;
    user.isTapped = @1;
    self.user = user;
//    UIView *orangeBackground = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, 0, self.frame.size.width + 15, self.frame.size.height)];
//    orangeBackground.backgroundColor = self.inviteButton.backgroundColor;
//    orangeBackground.layer.cornerRadius = 8.0f;
//    orangeBackground.layer.borderWidth = 1.0f;
//    orangeBackground.layer.borderColor = UIColor.clearColor.CGColor;
//    [self.contentView sendSubviewToBack:orangeBackground];
//    [self.contentView addSubview:orangeBackground];
//    self.titleLabel.hidden = YES;
//    self.tappedLabel.alpha = 1;
//    [self.contentView bringSubviewToFront:self.tappedLabel];

}

@end
