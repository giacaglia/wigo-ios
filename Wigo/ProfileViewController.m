
//  ParallaxProfileViewController.m
//  Wigo
//
//  Created by Alex Grinman on 12/12/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "ProfileViewController.h"
#import <Parse/Parse.h>
#import "UIButtonAligned.h"
#import "ImageScrollView.h"
#import "ChatViewController.h"
#import "FXBlurView.h"
#import "RWBlurPopover.h"
#import "EventStoryViewController.h"
#import "FollowRequestsViewController.h"

@interface ProfileViewController()<ImageScrollViewDelegate> {
    UIImageView *_gradientImageView;
    NSMutableArray *_blurredImages;
}

@property (nonatomic, strong) ImageScrollView *imageScrollView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *nameView;
@property (nonatomic, strong) UIView *headerButtonView;
@property (nonatomic, strong) UIImageView *nameViewBackground;

@property UIPageControl *pageControl;

@property NSNumber *followRequestSummary;

//favorite
@property UIButton *leftProfileButton;

@property (nonatomic, strong) UIButton *rightProfileButton;
@property (nonatomic, strong) UIButton *chatButton;

//UI
@property (nonatomic, strong) UIButtonAligned *rightBarBt;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UILabel *followRequestLabel;

@property UILabel *nameOfPersonLabel;
@property UIImageView *privateLogoImageView;
@property (nonatomic, strong) UILabel *numberOfChatsLabel;
@property (nonatomic, strong) UIImageView *orangeChatBubbleImageView;
@property (nonatomic, strong) UIView *redChatNotification;
@end

BOOL isUserBlocked;
BOOL blockShown;
UIButton *tapButton;

@implementation ProfileViewController

#pragma  mark - Init
- (id)initWithUser:(WGUser *)user {
    self = [super init];
    if (self) {
        [self setStateWithUser: user];
    }
    return self;
}

- (void) setStateWithUser: (WGUser *) user {
    if ([WGProfile currentUser] && user) {
        self.user = user;
        self.userState = self.user.state;
        if (user.isTapped == nil) self.userState = NOT_LOADED_STATE;
        self.view.backgroundColor = [UIColor whiteColor];
        [self createImageScrollView];
    }
   
    
}

#pragma mark - View Delegate
- (void) viewDidLoad {
    [super viewDidLoad];
    
    blockShown = NO;
    [self pageChangedTo: 0];

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
    [self.tableView registerClass:[SummaryCell class] forCellReuseIdentifier:kSummaryCellName];
    [self.tableView registerClass:[InstaCell class] forCellReuseIdentifier:kInstaCellName];
    [self.tableView setTableHeaderView: self.imageScrollView];
    self.tableView.showsVerticalScrollIndicator = NO;
    
    [self initializeNotificationHandlers];
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    [self initializeNameOfPerson];
    [self initializeHeaderButtonView];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if ([self.tableView respondsToSelector:@selector(layoutMargins)]) {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
    
    [_pageControl removeFromSuperview];
    _pageControl = nil;
    [_gradientImageView removeFromSuperview];
    _gradientImageView = nil;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.user.state == BLOCKED_USER_STATE) [self presentBlockPopView:self.user];
    if ([self.user isCurrentUser]) {
        [self fetchUserInfo];
        [self updateLastNotificationsRead];
    }
    else {
        __weak typeof(self) weakSelf = self;
        [self.user refetchUserWithHandler:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                return;
            }
            strongSelf.userState = strongSelf.user.state;
            [strongSelf reloadViewForUserState];
        }];
    }
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    NSString *isCurrentUser = ([self.user isEqual:[WGProfile currentUser]]) ? @"Yes" : @"No";
    NSString *isPeeking = (self.userState == OTHER_SCHOOL_USER_STATE) ? @"Yes" : @"No";

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:isCurrentUser, @"Self", isPeeking, @"isPeeking", nil];
    
    [WGAnalytics tagEvent:@"Profile View" withDetails:options];

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];

    [_gradientImageView removeFromSuperview];

    if (!_gradientImageView) {
        _gradientImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, -1*[UIApplication sharedApplication].statusBarFrame.size.height, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height)];
        [_gradientImageView setImage: [UIImage imageNamed:@"topGradientBackground"]];
    }
    
   
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar insertSubview: _gradientImageView atIndex: 0];
    
    if (!_pageControl) {
        [self createPageControl];
    }
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self reloadViewForUserState];
    
    if ([self.user isEqual:WGProfile.currentUser]) {
        _followRequestSummary = @0;
        [self fetchNotifications];
        [self updateBadge];
        [self fetchSummaryOfFollowRequests];
    }

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
}

- (void) createImageScrollView {
    CGFloat imageScrollViewDimension = [[UIScreen mainScreen] bounds].size.width;
    self.imageScrollView = [[ImageScrollView alloc] initWithFrame: CGRectMake(0, 0, imageScrollViewDimension, imageScrollViewDimension) andUser:self.user];
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
    if (![self.user isCurrentUser]) {
        if (isUserBlocked) self.user.isBlocked = [NSNumber numberWithBool:isUserBlocked];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self.user deserialize]];
        isUserBlocked = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUserAtTable" object:nil userInfo:userInfo];
    }
    
    
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
    [barBt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    // self.navigationItem.leftBarButtonItem = barItem;
    [self.navigationItem setLeftBarButtonItem:barItem animated:NO];
}

- (void) initializeRightBarButton {
    _rightBarBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [_rightBarBt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _rightBarBt.titleLabel.font = [FontProperties getSubtitleFont];
    
    if (self.userState == PRIVATE_STATE || self.userState == PUBLIC_STATE) {
        [_rightBarBt setTitle:@"Edit" forState:UIControlStateNormal];
        [_rightBarBt addTarget:self action: @selector(editPressed) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_rightBarBt setTitle:@"More" forState:UIControlStateNormal];
        [_rightBarBt addTarget:self action: @selector(morePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [_rightBarBt sizeToFit];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:_rightBarBt];
    // self.navigationItem.rightBarButtonItem = barItem;
    [self.navigationItem setRightBarButtonItem:barItem animated:NO];
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
    if ((self.userState == ACCEPTED_PRIVATE_USER_STATE || self.userState == NOT_YET_ACCEPTED_PRIVATE_USER_STATE || self.userState == PRIVATE_STATE)) {
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
    
    _leftProfileButton = [[UIButton alloc] init];
    _leftProfileButton.frame = CGRectMake(0, 0, self.view.frame.size.width/3 + 5, 70);
    [_leftProfileButton addTarget:self action:@selector(followersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.numberOfFollowersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, _leftProfileButton.frame.size.width, 25)];
    self.numberOfFollowersLabel.textColor = [FontProperties getOrangeColor];
    self.numberOfFollowersLabel.font = [FontProperties mediumFont:20.0f];
    self.numberOfFollowersLabel.textAlignment = NSTextAlignmentCenter;
    self.numberOfFollowersLabel.text = [self.user.numFollowers stringValue];
    [_leftProfileButton addSubview:self.numberOfFollowersLabel];
    
    UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35, _leftProfileButton.frame.size.width, 20)];
    followersLabel.textColor = [FontProperties getOrangeColor];
    followersLabel.font = [FontProperties scMediumFont:16];
    followersLabel.textAlignment = NSTextAlignmentCenter;
    followersLabel.text = @"followers";
    [_leftProfileButton addSubview:followersLabel];
    [_headerButtonView addSubview:_leftProfileButton];
    
    _rightProfileButton = [[UIButton alloc] init];
    [_rightProfileButton addTarget:self action:@selector(followingButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _rightProfileButton.frame = CGRectMake(self.view.frame.size.width/3, 0, self.view.frame.size.width/3, 70);
    self.numberOfFollowingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, _rightProfileButton.frame.size.width, 25)];
    self.numberOfFollowingLabel.textColor = [FontProperties getOrangeColor];
    self.numberOfFollowingLabel.font = [FontProperties mediumFont:20.0f];
    self.numberOfFollowingLabel.textAlignment = NSTextAlignmentCenter;
    self.numberOfFollowingLabel.text = [self.user.numFollowing stringValue];
    [_rightProfileButton addSubview:self.numberOfFollowingLabel];
    
    UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35, _rightProfileButton.frame.size.width, 20)];
    followingLabel.textColor = [FontProperties getOrangeColor];
    followingLabel.font = [FontProperties scMediumFont:16.0F];
    followingLabel.textAlignment = NSTextAlignmentCenter;
    followingLabel.text = @"following";
    [_rightProfileButton addSubview:followingLabel];
    [_headerButtonView addSubview:_rightProfileButton];
    
    _chatButton = [[UIButton alloc] initWithFrame:CGRectMake(2*self.view.frame.size.width/3, 0, self.view.frame.size.width/3, 70)];
    [_chatButton addTarget:self action:@selector(chatPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35, _chatButton.frame.size.width, 20)];
    chatLabel.textAlignment = NSTextAlignmentCenter;
    chatLabel.text = @"chats";
    chatLabel.textColor = [FontProperties getOrangeColor];
    chatLabel.font = [FontProperties scMediumFont:16.0f];
    [_chatButton addSubview:chatLabel];
    
    _orangeChatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(_chatButton.frame.size.width/2 - 10, 10, 20, 20)];
    _orangeChatBubbleImageView.center = CGPointMake(_orangeChatBubbleImageView.center.x, _chatButton.center.y - _orangeChatBubbleImageView.frame.size.height/2 + 2);
    
    [_chatButton addSubview:_orangeChatBubbleImageView];
    _numberOfChatsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _orangeChatBubbleImageView.frame.size.width, _orangeChatBubbleImageView.frame.size.height - 8)];
    _numberOfChatsLabel.textAlignment = NSTextAlignmentCenter;
    _numberOfChatsLabel.textColor = UIColor.whiteColor;
    _numberOfChatsLabel.font = [FontProperties scMediumFont:16.0f];
    [_orangeChatBubbleImageView addSubview:_numberOfChatsLabel];
    
    _redChatNotification = [[UIView alloc] initWithFrame:CGRectMake(_chatButton.frame.size.width/2 + 10, 5, 13, 13)];
    _redChatNotification.backgroundColor = UIColor.redColor;
    _redChatNotification.layer.borderColor = [UIColor clearColor].CGColor;
    _redChatNotification.clipsToBounds = YES;
    _redChatNotification.layer.borderWidth = 3;
    _redChatNotification.layer.cornerRadius = 7;
    _redChatNotification.alpha = 0.0f;
    [_chatButton addSubview:_redChatNotification];
    
    [self updateNumberOfChats];

    
    [_headerButtonView addSubview:_chatButton];
    [self initializeFollowRequestLabel];
    [self initializeFollowButton];

}

- (void)updateNumberOfChats {
    NSNumber *unreadChats = [WGProfile currentUser].numUnreadConversations;
    if (![unreadChats isEqualToNumber: @0] && [self.user isCurrentUser]) {
        _orangeChatBubbleImageView.image = [UIImage imageNamed:@"orangeChatBubble"];
        _numberOfChatsLabel.text = [NSString stringWithFormat: @"%@", unreadChats];
        [UIView animateWithDuration:1.5f animations:^{
            _redChatNotification.alpha = 1.0f;
        }];
    } else {
        _redChatNotification.alpha = 0.0f;
        _orangeChatBubbleImageView.image = [UIImage imageNamed:@"chatsIcon"];
    }
}

- (void) initializeFollowButton {
    _followButton = [[UIButton alloc] initWithFrame:CGRectMake(25, 10, self.view.frame.size.width - 50, 50)];
    _followButton.backgroundColor = [UIColor clearColor];
    _followButton.layer.cornerRadius = 15;
    _followButton.layer.borderWidth = 1;
    _followButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [_followButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchUpInside];
    [_headerButtonView addSubview: _followButton];
    [_headerButtonView bringSubviewToFront: _followButton];
    
    NSString *followText = [NSString stringWithFormat:@"Follow %@", [self.user firstName]];
    UIView *followLabelPlusImage = [[UIView alloc] init];
    int sizeOfText = (int)[followText length];
    followLabelPlusImage.frame = CGRectMake((_followButton.frame.size.width - (sizeOfText*13 + 28))/2, 15, sizeOfText*13 + 28, 20);
    followLabelPlusImage.userInteractionEnabled = NO;
    [_followButton addSubview:followLabelPlusImage];
    
    UILabel *followLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, followLabelPlusImage.frame.size.width, 20)];
    followLabel.text = followText;
    followLabel.textAlignment = NSTextAlignmentLeft;
    followLabel.textColor = [FontProperties getOrangeColor];
    followLabel.font =  [FontProperties scMediumFont:24.0f];
    
    [followLabelPlusImage addSubview:followLabel];
    
    UIImageView *plusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plusPerson"]];
    plusImageView.frame = CGRectMake(followLabelPlusImage.frame.size.width - 28, followLabelPlusImage.frame.size.height/2 - 11, 28, 20);
    plusImageView.tintColor = [FontProperties getOrangeColor];
    [followLabelPlusImage addSubview:plusImageView];
}

- (void)initializeFollowRequestLabel {
    _followRequestLabel = [[UILabel alloc] initWithFrame: _headerButtonView.bounds];
    _followRequestLabel.text = @"Your follow request has been sent";
    _followRequestLabel.textAlignment = NSTextAlignmentCenter;
    _followRequestLabel.textColor = [FontProperties getOrangeColor];
    _followRequestLabel.font = [FontProperties scMediumFont:16.0f];
    if (self.userState == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) _followRequestLabel.hidden = NO;
    else _followRequestLabel.hidden = YES;
    [_headerButtonView addSubview: _followRequestLabel];
    [_headerButtonView bringSubviewToFront: _followRequestLabel];
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
    if (!blockShown) {
        blockShown = YES;
        if (![sentUser isCurrentUser]) {
            __weak typeof(self) weakSelf = self;
            [[WGProfile currentUser] block:sentUser withType:blockType andHandler:^(BOOL success, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionPost];
                    return;
                }
                strongSelf.userState = strongSelf.user.state;
                [strongSelf reloadViewForUserState];
                [strongSelf presentBlockPopView:sentUser];
            }];
        }
    }
}

- (void)unblockPressed {
    self.user.isBlocked = @NO;
    self.userState = self.user.state;
    [self reloadViewForUserState];
    
    [[WGProfile currentUser] unblock:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
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
    self.user.isFollowing = @YES;
    self.user.isFollowingRequested = @YES;
    self.userState = self.user.state;
    [self reloadViewForUserState];
    
    [[WGProfile currentUser] follow:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
        self.userState = self.user.state;
        [self reloadViewForUserState];
    }];
}

- (void)unfollowPressed {
    self.user.isFollowingRequested = @NO;
    self.user.isFollowing = @NO;
    self.userState = self.user.state;
    [self reloadViewForUserState];
    
    [[WGProfile currentUser] unfollow:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
        self.userState = self.user.state;
        [self reloadViewForUserState];
    }];
}


- (void)followersButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@3] animated:YES];
}

- (void)followingButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@4] animated:YES];
}

- (void)chatPressed {
    if ([self.user isCurrentUser]) {
        ChatViewController *chatViewController = [ChatViewController new];
        chatViewController.view.backgroundColor = UIColor.whiteColor;
        [self.navigationController pushViewController:chatViewController animated:YES];
    } else {
        [self.navigationController pushViewController: [[ConversationViewController alloc] initWithUser:self.user] animated:YES];
    }
   
}


#pragma mark User State

- (void) reloadViewForUserState {
    if (self.userState == NOT_LOADED_STATE) {
        _rightBarBt.enabled = NO;
        _rightBarBt.hidden = YES;
        _leftProfileButton.enabled = NO;
        _leftProfileButton.hidden = YES;
        _rightProfileButton.enabled = NO;
        _rightProfileButton.hidden = YES;
        _chatButton.enabled = NO;
        _chatButton.hidden = YES;
        _followButton.enabled = NO;
        _followButton.hidden = YES;
        _followButton.enabled = NO;
        _followButton.hidden = YES;
    }
    else if (self.userState == OTHER_SCHOOL_USER_STATE) {
        _rightBarBt.enabled = NO;
        _rightBarBt.hidden = YES;
        _leftProfileButton.enabled = NO;
        _leftProfileButton.hidden = YES;
        _rightProfileButton.enabled = NO;
        _rightProfileButton.hidden = YES;
        _chatButton.enabled = NO;
        _chatButton.hidden = YES;
        _followButton.enabled = NO;
        _followButton.hidden = YES;
    }
    else if (self.userState == FOLLOWING_USER_STATE ||
        self.userState == ATTENDING_EVENT_FOLLOWING_USER_STATE ||
        self.userState == ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE) {
        _rightBarBt.enabled = YES;
        _rightBarBt.hidden = NO;
        _leftProfileButton.enabled = YES;
        _leftProfileButton.hidden = NO;
        _rightProfileButton.enabled = YES;
        _rightProfileButton.hidden = NO;
        _chatButton.enabled = YES;
        _chatButton.hidden = NO;
        
        _followButton.enabled = NO;
        _followButton.hidden = YES;
        
        _privateLogoImageView.hidden = YES;
        _followRequestLabel.hidden = YES;
    }
    else if (self.userState == NOT_FOLLOWING_PUBLIC_USER_STATE ||
             self.userState == NOT_SENT_FOLLOWING_PRIVATE_USER_STATE ||
             self.userState == BLOCKED_USER_STATE) {
        _rightBarBt.enabled = YES;
        _rightBarBt.hidden = NO;
        _leftProfileButton.enabled = NO;
        _leftProfileButton.hidden = YES;
        _rightProfileButton.enabled = NO;
        _rightProfileButton.hidden = YES;
        _chatButton.enabled = NO;
        _chatButton.hidden = YES;
        
        _followButton.enabled = YES;
        _followButton.hidden = NO;
        
        if (self.userState == NOT_FOLLOWING_PUBLIC_USER_STATE) {
            _privateLogoImageView.hidden = YES;
        }
        _followRequestLabel.hidden = YES;
    }
    else if (self.userState == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
        _rightBarBt.enabled = YES;
        _rightBarBt.hidden = NO;
        _leftProfileButton.enabled = NO;
        _leftProfileButton.hidden = YES;
        _rightProfileButton.enabled = NO;
        _rightProfileButton.hidden = YES;
        _chatButton.enabled = NO;
        _chatButton.hidden = YES;
        
        _followButton.enabled = NO;
        _followButton.hidden = YES;
        
        _privateLogoImageView.hidden = YES;
        _followRequestLabel.hidden = NO;
    }
    if (self.userState == PUBLIC_STATE || self.userState == PRIVATE_STATE) {
        _rightBarBt.enabled = YES;
        _rightBarBt.hidden = NO;
        _followButton.enabled = NO;
        _followButton.hidden = YES;
        _chatButton.enabled = YES;
        _chatButton.hidden = NO;
        
        _leftProfileButton.enabled = YES;
        _leftProfileButton.hidden = NO;
        _rightProfileButton.enabled = YES;
        _rightProfileButton.hidden = NO;
        
        if (self.userState == PRIVATE_STATE) {
            _privateLogoImageView.hidden = NO;
        }
        else {
            _privateLogoImageView.hidden = YES;
            _followRequestLabel.hidden = YES;
        }
    }
    
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
    blockedLabel.text = [NSString stringWithFormat:@"%@ can't follow you or see any of your activity.", [user fullName]];
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
    isUserBlocked = [self.user.isBlocked boolValue];
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

- (BOOL) shouldShowGoOutsCell {
    if (self.userState == NOT_SENT_FOLLOWING_PRIVATE_USER_STATE ||
        self.userState == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
        return NO;
    }
    
    return YES;
}

- (BOOL) shouldShowInviteCell {
    if ([self.user isCurrentUser] ||
        self.userState == NOT_LOADED_STATE ||
        self.userState ==  NOT_FOLLOWING_PUBLIC_USER_STATE ||
        self.userState == NOT_SENT_FOLLOWING_PRIVATE_USER_STATE ||
        self.userState == NOT_YET_ACCEPTED_PRIVATE_USER_STATE ||
        self.userState == BLOCKED_USER_STATE ||
        self.userState == OTHER_SCHOOL_USER_STATE) {
        return NO;
    }
    
    return YES;
}

- (BOOL)shouldShowFollowSummary {
    if ((self.userState == PRIVATE_STATE || self.userState == PUBLIC_STATE) &&
        (![_followRequestSummary isEqualToNumber:@0] && _followRequestSummary)
        ) {
        return YES;
    }
    return NO;
}

- (BOOL) isIndexPathASummaryCell:(NSIndexPath *)indexPath {
    return (indexPath.row == 0 && [self shouldShowFollowSummary]);
}

- (NSInteger) notificationCount {
    if (self.userState == PUBLIC_STATE || self.userState == PRIVATE_STATE) {
        int numberOfCellsForSummary =  [self shouldShowFollowSummary] ? 1 : 0;
        return self.unexpiredNotifications.count + numberOfCellsForSummary;
    }
    return [self shouldShowInviteCell] ? 1 : 0;
}

#pragma mark - Table View Delegate

#define kImageViewSection 0
#define kNotificationsSection 1
#define kGoOutsSection 2
#define kInstagramSection 3

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
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
        
        if ([goOutsCell respondsToSelector:@selector(layoutMargins)]) {
            goOutsCell.layoutMargins = UIEdgeInsetsMake(0, goOutsCell.contentView.frame.size.width, 0, 0);
        }
        
        return goOutsCell;
    } else if (indexPath.section == kNotificationsSection) {
        if ([self isIndexPathASummaryCell:indexPath]) {
            SummaryCell *summaryCell = [tableView dequeueReusableCellWithIdentifier:kSummaryCellName forIndexPath:indexPath];
            summaryCell.numberOfRequestsLabel.text = [_followRequestSummary stringValue];
            
            if ([summaryCell respondsToSelector:@selector(layoutMargins)]) {
                summaryCell.layoutMargins = UIEdgeInsetsZero;
            }
            
            return summaryCell;
        }
        if ([self shouldShowInviteCell] && indexPath.row == 0) {
            InviteCell *inviteCell = [tableView dequeueReusableCellWithIdentifier:@"InviteCell" forIndexPath:indexPath];
            inviteCell.delegate = self;
            [inviteCell setLabelsForUser:self.user];
            return inviteCell;
        }
        if ([self shouldShowInviteCell]) {
             indexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
        }
        NotificationCell *notificationCell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellName forIndexPath:indexPath];
        if ([_followRequestSummary intValue] > 0) {
            indexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
        }
        if (indexPath.row >= self.unexpiredNotifications.count) return notificationCell;
        WGNotification *notification = (WGNotification *)[self.unexpiredNotifications objectAtIndex:[indexPath row]];
        if (!notification.fromUser.id) return notificationCell;
        if ([[notification type] isEqualToString:@"group.unlocked"]) return notificationCell;

        WGUser *user = notification.fromUser;
        if ([notification.id intValue] > [[WGProfile currentUser].lastNotificationRead intValue]) {
            notificationCell.backgroundColor = [FontProperties getBackgroundLightOrange];
        } else {
            notificationCell.backgroundColor = UIColor.whiteColor;
        }
        [notificationCell.profileImageView setSmallImageForUser:user completed:nil];
        notificationCell.descriptionLabel.text = [NSString stringWithFormat:@"%@ %@", user.firstName, notification.message];
        
        if (user.state == NOT_SENT_FOLLOWING_PRIVATE_USER_STATE || user.state == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
            notificationCell.rightPostImageView.hidden = YES;
        } else {
            notificationCell.rightPostImageView.hidden = NO;
        }
        
        if ([notificationCell respondsToSelector:@selector(layoutMargins)]) {
            notificationCell.layoutMargins = UIEdgeInsetsZero;
        }
        
        return notificationCell;
    } else if (indexPath.section == kImageViewSection) {
        UITableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier: @"ImageScrollViewCell" forIndexPath:indexPath];
        
        [self.imageScrollView removeFromSuperview];
        [imageCell.contentView addSubview: self.imageScrollView];
        return imageCell;
    }
    else if (indexPath.section == kInstagramSection) {
        InstaCell *instaCell = [tableView dequeueReusableCellWithIdentifier: kInstaCellName forIndexPath:indexPath];
        [instaCell setLabelForUser:self.user];
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
    if (indexPath.section == kGoOutsSection) {
        return [GoOutsCell rowHeight];
    }
    else if (indexPath.section == kNotificationsSection) {
        return 65;
    }
    else if (indexPath.section == kImageViewSection) {
        return self.imageScrollView.frame.size.height - _nameView.frame.size.height;
    }
    if (indexPath.section == kInstagramSection) {
        return [InstaCell rowHeight];
    }
    return 0;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section != kGoOutsSection) {
        // Remove seperator inset
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
        
        // Prevent the cell from inheriting the Table View's margin settings
        if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
            [cell setPreservesSuperviewLayoutMargins:NO];
        }
        
        // Explictly set your cell's layout margins
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
    }
    
    if (indexPath.section != kNotificationsSection) {
        return;
    }
    
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kNotificationsSection && [self.user isCurrentUser]) {
        if ([self isIndexPathASummaryCell:indexPath]) {
            [self.navigationController pushViewController:[FollowRequestsViewController new] animated:YES];
        } else {
            if ([_followRequestSummary intValue] > 0) indexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
            WGNotification *notification = (WGNotification *)[self.unexpiredNotifications objectAtIndex:indexPath.row];
            WGUser *user = notification.fromUser;
           
            if ([notification.type isEqualToString:@"follow"] || [notification.type isEqualToString:@"follow.accepted"] || [notification.type isEqualToString:@"facebook.follow"]) {
                [self presentUser:user];
            } else if ([user state] != NOT_YET_ACCEPTED_PRIVATE_USER_STATE && [user state] != NOT_SENT_FOLLOWING_PRIVATE_USER_STATE) {
                if (user.eventAttending) [self presentEvent:user.eventAttending];
                else [self presentUser:user];
            }
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
    [profileViewController setStateWithUser:user];
    profileViewController.events = self.events;
    [self.navigationController pushViewController: profileViewController animated: YES];
}

- (void)presentEvent:(WGEvent *)event {
    if ([self.events containsObject:event] && event.attendees && event.attendees.count > 0) {
        EventStoryViewController *eventStoryViewController = [EventStoryViewController new];
        eventStoryViewController.event = event;
        eventStoryViewController.view.backgroundColor = UIColor.whiteColor;
        [self.navigationController pushViewController: eventStoryViewController animated:YES];
    }
    else [self fetchEvent:event];
}

- (void)inviteTapped {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Profile", @"Tap Source", nil];
    [WGAnalytics tagEvent:@"Tap User" withDetails:options];

    self.user.isTapped = @YES;
    [[WGProfile currentUser] tapUser:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
        [self.tableView reloadData];
    }];
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

- (void) fetchUserInfo {
    if ([WGProfile currentUser].key) {
        __weak typeof(self) weakSelf = self;
        [WGProfile reload:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.user = [WGProfile currentUser];
            strongSelf.numberOfFollowersLabel.text = [strongSelf.user.numFollowers stringValue];
            strongSelf.numberOfFollowingLabel.text = [strongSelf.user.numFollowing stringValue];
            [strongSelf updateNumberOfChats];
            _pageControl.numberOfPages = [[strongSelf.user imagesURL] count];
            [strongSelf createImageScrollView];
            strongSelf.userState = WGProfile.currentUser.state;
            [strongSelf reloadViewForUserState];
        }];
    }
}

- (void)fetchNotifications {
    __weak typeof(self) weakSelf = self;
    if (!self.isFetchingNotifications) {
        self.isFetchingNotifications = YES;
        if (!self.notifications || self.notifications.hasNextPage == nil) {
            [WGNotification get:^(WGCollection *collection, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.isFetchingNotifications = NO;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    return;
                }
                strongSelf.notifications = collection;
                if (!strongSelf.unexpiredNotifications) strongSelf.unexpiredNotifications = [[WGCollection alloc] initWithType:[WGNotification class]];
                for (WGNotification *notification in strongSelf.notifications) {
                    if (![notification isFromLastDay]) {
                        [strongSelf.unexpiredNotifications addObject:notification];
                    }
                }
                strongSelf.tableView.separatorColor = [self.tableView.separatorColor colorWithAlphaComponent: 1.0f];
                [strongSelf.tableView reloadData];
                [strongSelf.tableView didFinishPullToRefresh];
                strongSelf.isFetchingNotifications = NO;
            }];
        } else if ([self.notifications.hasNextPage boolValue]) {
            [self.notifications getNextPage:^(WGCollection *collection, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.isFetchingNotifications = NO;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    return;
                }
                for (WGNotification *notification in collection) {
                    [strongSelf.notifications addObject:notification];
                    if (![notification isFromLastDay]) {
                        if (![strongSelf.unexpiredNotifications containsObject:notification]) {
                            [strongSelf.unexpiredNotifications addObject:notification];
                        }
                    }
                }
                strongSelf.tableView.separatorColor = [self.tableView.separatorColor colorWithAlphaComponent: 1.0f];
                [strongSelf.tableView reloadData];
                [strongSelf.tableView didFinishPullToRefresh];
                strongSelf.isFetchingNotifications = NO;
            }];
        } else {
            self.isFetchingNotifications = NO;
        }
    }
}

- (void)updateLastNotificationsRead {
    [[WGProfile currentUser] setLastNotificationReadToLatest:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
        }
    }];
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

- (void)fetchEvent:(WGEvent *)event {
    __weak typeof(self) weakSelf = self;
    [event refresh:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        EventStoryViewController *eventStoryViewController = [EventStoryViewController new];
        eventStoryViewController.event = event;
        eventStoryViewController.view.backgroundColor = UIColor.whiteColor;
        [strongSelf.navigationController pushViewController: eventStoryViewController animated:YES];
    }];
}


- (void)fetchSummaryOfFollowRequests {
    __weak typeof(self) weakSelf = self;
    [WGNotification getFollowSummary:^(NSNumber *follow, NSNumber *followRequest, NSNumber *total, NSNumber *tap, NSNumber *facebookFollow, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        _followRequestSummary = followRequest;
        [strongSelf.tableView reloadData];
    }];
}


@end

@implementation SummaryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 65);
   
    self.numberOfRequestsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 45, 45)];
    self.numberOfRequestsLabel.layer.cornerRadius = 5;
    self.numberOfRequestsLabel.layer.borderWidth = 0.5;
    self.numberOfRequestsLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.numberOfRequestsLabel.layer.masksToBounds = YES;
    self.numberOfRequestsLabel.backgroundColor = RGB(254, 242, 229);
    self.numberOfRequestsLabel.textColor = [FontProperties getOrangeColor];
    self.numberOfRequestsLabel.textAlignment = NSTextAlignmentCenter;
    self.numberOfRequestsLabel.text = @"";
    self.numberOfRequestsLabel.center = CGPointMake(self.numberOfRequestsLabel.center.x, self.center.y);
    [self.contentView addSubview:self.numberOfRequestsLabel];

    UILabel *notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, self.frame.size.height/2 - 22, self.frame.size.width - 70 - 80, self.contentView.frame.size.height)];
    notificationLabel.text = @"Follow requests";
    notificationLabel.font = [FontProperties getBioFont];
    [self.contentView addSubview:notificationLabel];

    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeRightArrow"]];
    rightArrowImageView.frame = CGRectMake(self.frame.size.width - 35, self.frame.size.height/2 - 9, 11, 18);
    rightArrowImageView.center = CGPointMake(rightArrowImageView.center.x, self.center.y);
    [self.contentView addSubview:rightArrowImageView];
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
    self.profileImageView.layer.cornerRadius = 7;
    self.profileImageView.layer.borderWidth = 0.5;
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
    
    self.rightPostImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 32, self.frame.size.height/2 - 7, 9, 15)];
    self.rightPostImageView.image = [UIImage imageNamed:@"rightPostImage"];
    self.rightPostImageView.center = CGPointMake(self.rightPostImageView.center.x, self.center.y);
    [self.contentView addSubview:self.rightPostImageView];
    
    self.tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 25 - 27, self.frame.size.height/2 + 13 + 3, 50, 15)];
    self.tapLabel.text = @"Tap back";
    self.tapLabel.textAlignment = NSTextAlignmentCenter;
    self.tapLabel.font = [FontProperties lightFont:12.0f];
    self.tapLabel.textColor = RGB(240, 203, 163);
    self.tapLabel.hidden = YES;
    [self.contentView addSubview:self.tapLabel];
}

@end

@interface GoOutsCell() {
    NSNumber *_lastCount;
}

@end
@implementation GoOutsCell

#define kTitleTemplate @"times out this semester"

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    
    _lastCount = nil;
    
    return self;
}


+ (CGFloat)rowHeight {
    return 100.0f;
}

- (void) setLabelsForUser: (WGUser *) user {
    
    NSNumber *newCount = (NSNumber *)[user objectForKey:@"period_went_out"];
    
    if (_lastCount && [_lastCount isEqualToNumber: newCount]) {
        return;
    }
    
    newCount = newCount;
    _lastCount = newCount;
    
    for (UIView *subview in self.contentView.subviews) {
        [subview removeFromSuperview];
    }
    
    
    UIFont *numberLabelFont = [FontProperties lightFont: 55];
    
    NSDictionary *attributes = @{NSFontAttributeName: numberLabelFont};
    CGSize numberSize = [[newCount stringValue] sizeWithAttributes: attributes];

    CGFloat spacerSize = 10.0f;
    CGFloat titleWidth = 137.0f;

    CGFloat contentWidth = numberSize.width + spacerSize + titleWidth;
    CGFloat sideSpacing = (self.contentView.bounds.size.width - contentWidth)/2;
    
    self.numberLabel = [[UILabel alloc] initWithFrame: CGRectMake(sideSpacing, 0, numberSize.width, self.contentView.frame.size.height)];
    self.numberLabel.text = [newCount stringValue];
    self.numberLabel.textAlignment = NSTextAlignmentRight;
    self.numberLabel.font = numberLabelFont;
    self.numberLabel.textColor = [FontProperties getOrangeColor];
    [self.contentView addSubview: self.numberLabel];

    self.titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(sideSpacing + numberSize.width + spacerSize, 0, titleWidth, self.contentView.frame.size.height)];
    self.titleLabel.text = [NSString stringWithFormat: kTitleTemplate];
    self.titleLabel.font = [FontProperties lightFont: 24];
    self.titleLabel.textColor = [UIColor lightGrayColor];
    self.titleLabel.numberOfLines = 2;
    [self.contentView addSubview: self.titleLabel];
}

@end


@implementation InstaCell


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


+ (CGFloat)rowHeight {
    return 60.0f;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [InstaCell rowHeight]);
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.instaLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [InstaCell rowHeight])];
    self.instaLabel.font = [FontProperties lightFont:20];
    self.instaLabel.textColor = [FontProperties getOrangeColor];
    self.instaLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.instaLabel];
}

- (void) setLabelForUser: (WGUser *) user {
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

#define kInviteTitleTemplate @"Tap to see out:"

- (void) awakeFromNib {
    [self setup];
}


+ (CGFloat)rowHeight {
    return 70.0f;
}

- (void) setLabelsForUser: (WGUser *) user {
    if ([user isCurrentUser]) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.titleLabel.hidden = YES;
        self.tappedLabel.alpha = 0;
        return;
    }
    
    if ([self.delegate userState] == OTHER_SCHOOL_USER_STATE) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.titleLabel.hidden = YES;
        self.tappedLabel.alpha = 0;
        } else {
        if ([user.isTapped boolValue]) {
            self.inviteButton.hidden = YES;
            self.inviteButton.enabled = NO;
            self.titleLabel.hidden = YES;
            self.tappedLabel.alpha = 1;

        } else {
            self.inviteButton.hidden = NO;
            self.titleLabel.hidden = NO;
            self.titleLabel.text = kInviteTitleTemplate;
            self.tappedLabel.alpha = 0;
        }
    }
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70.0f);
    self.titleLabel.font = [FontProperties lightFont: 18];
    self.titleLabel.textColor = UIColor.lightGrayColor;
    
    self.inviteButton.titleLabel.font =  [FontProperties lightFont:18.0f];
    self.inviteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.borderColor = UIColor.whiteColor.CGColor;
    self.inviteButton.layer.cornerRadius = 7;
    [self.inviteButton addTarget: self action: @selector(inviteTapped) forControlEvents: UIControlEventTouchUpInside];
    
    self.tappedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70.0f)];
    self.tappedLabel.text = @"TAPPED";
    self.tappedLabel.font = [FontProperties lightFont: 24];
    self.tappedLabel.textColor = UIColor.lightGrayColor;
    self.tappedLabel.textAlignment = NSTextAlignmentCenter;
    self.tappedLabel.alpha = 0;
    
    [self.contentView addSubview:self.tappedLabel];
}

- (void) inviteTapped {
    self.inviteButton.enabled = NO;
  
    UIView *orangeBackground = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, 0, self.frame.size.width + 15, self.frame.size.height)];
    orangeBackground.backgroundColor = self.inviteButton.backgroundColor;
    orangeBackground.layer.cornerRadius = 8.0f;
    orangeBackground.layer.borderWidth = 1.0f;
    orangeBackground.layer.borderColor = UIColor.clearColor.CGColor;
    [self.contentView sendSubviewToBack:orangeBackground];
    [self.contentView addSubview:orangeBackground];
    self.titleLabel.hidden = YES;
    self.tappedLabel.textColor = UIColor.whiteColor;
    self.tappedLabel.alpha = 1;
    [self.contentView bringSubviewToFront:self.tappedLabel];

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.inviteButton.alpha = 0.0f;
        orangeBackground.frame = CGRectMake(-10, 0, self.frame.size.width + 15, self.frame.size.height);
        self.tappedLabel.alpha = 1;
    } completion:^(BOOL finished) {
    [UIView animateWithDuration:0.2f animations:^{
        orangeBackground.backgroundColor = RGB(231, 222, 214);
        weakSelf.tappedLabel.textColor = UIColor.lightGrayColor;
    } completion:^(BOOL finished) {
    [UIView animateWithDuration:0.5f animations:^{
        orangeBackground.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (weakSelf.delegate) {
            [weakSelf.delegate inviteTapped];
        }
    }];
    }];
    }];

}
@end
