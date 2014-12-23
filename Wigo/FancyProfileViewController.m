
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
#import "EventStoryViewController.h"
#import "FollowRequestsViewController.h"

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
@property NSNumber *followRequestSummary;

//favorite
@property UIButton *leftProfileButton;
@property UIButton *rightProfileButton;
@property UIButton *chatButton;

//UI
@property UIButtonAligned *rightBarBt;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if ([self.tableView respondsToSelector:@selector(layoutMargins)]) {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
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
      if ([self.user getUserState] == BLOCKED_USER) [self presentBlockPopView:self.user];

}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    
    _page = @1;
    _followRequestSummary = @0;
    [self fetchNotifications];
    [self updateBadge];
    [self fetchSummaryOfFollowRequests];
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
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) initializeRightBarButton {
    _rightBarBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [_rightBarBt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _rightBarBt.titleLabel.font = [FontProperties getSubtitleFont];
    
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        [_rightBarBt setTitle:@"Edit" forState:UIControlStateNormal];
        [_rightBarBt addTarget:self action: @selector(editPressed) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_rightBarBt setTitle:@"More" forState:UIControlStateNormal];
        [_rightBarBt addTarget:self action: @selector(morePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [_rightBarBt sizeToFit];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:_rightBarBt];
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
    
    _leftProfileButton = [[UIButton alloc] init];
    _leftProfileButton.frame = CGRectMake(0, 0, self.view.frame.size.width/3, 70);
    [_leftProfileButton addTarget:self action:@selector(followersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
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
    
    _chatButton = [[UIButton alloc] initWithFrame:CGRectMake(2*self.view.frame.size.width/3, 0, self.view.frame.size.width/3, 70)];
    [_chatButton addTarget:self action:@selector(chatPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, _chatButton.frame.size.width, 20)];
    chatLabel.textAlignment = NSTextAlignmentCenter;
    chatLabel.text = @"chats";
    chatLabel.textColor = [FontProperties getOrangeColor];
    chatLabel.font = [FontProperties scMediumFont:16.0f];
    [_chatButton addSubview:chatLabel];
    
    UIImageView *orangeChatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(_chatButton.frame.size.width/2 - 10, 10, 20, 20)];
    orangeChatBubbleImageView.center = CGPointMake(orangeChatBubbleImageView.center.x, _chatButton.center.y - orangeChatBubbleImageView.frame.size.height/2);
    
    [_chatButton addSubview:orangeChatBubbleImageView];
    UILabel *numberOfChatsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, orangeChatBubbleImageView.frame.size.width, orangeChatBubbleImageView.frame.size.height - 8)];
    numberOfChatsLabel.textAlignment = NSTextAlignmentCenter;
    numberOfChatsLabel.textColor = UIColor.whiteColor;
    numberOfChatsLabel.font = [FontProperties scMediumFont:16.0f];
    NSNumber *unreadChats = (NSNumber *)[self.user objectForKey:@"num_unread_conversations"];
    if (![unreadChats isEqualToNumber: @0] && [self.user isEqualToUser:[Profile user]]) {
        orangeChatBubbleImageView.image = [UIImage imageNamed:@"orangeChatBubble"];
        numberOfChatsLabel.text = [NSString stringWithFormat: @"%@", unreadChats];
    } else {
        orangeChatBubbleImageView.image = [UIImage imageNamed:@"chatsIcon"];
    }
    [orangeChatBubbleImageView addSubview:numberOfChatsLabel];
    
    [_headerButtonView addSubview:_chatButton];
    [self initializeFollowRequestLabel];
    [self initializeFollowButton];

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
    if (self.userState == NOT_YET_ACCEPTED_PRIVATE_USER) _followRequestLabel.hidden = NO;
    else _followRequestLabel.hidden = YES;
    [_headerButtonView addSubview: _followRequestLabel];
    [_headerButtonView bringSubviewToFront: _followRequestLabel];
}

#pragma mark - Action Taps

- (void)blockPressed:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    User *sentUser = [[User alloc] initWithDictionary:[userInfo objectForKey:@"user"]];
    NSNumber *typeNumber = (NSNumber *)[userInfo objectForKey:@"type"];
    NSArray *blockTypeArray = @[@"annoying", @"not_student", @"abusive"];
    NSString *blockType = [blockTypeArray objectAtIndex:[typeNumber intValue]];
    if (!blockShown) {
        blockShown = YES;
        if (![sentUser isEqualToUser:[Profile user]]) {
            NSString *queryString = @"blocks/";
            NSDictionary *options = @{@"block": [sentUser objectForKey:@"id"], @"type": blockType};
            [Network sendAsynchronousHTTPMethod:POST
                                    withAPIName:queryString
                                    withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                                    withOptions:options];
            [sentUser setIsBlocked:YES];
            [self presentBlockPopView:sentUser];
        }
        
    }
}

- (void)unblockPressed {
    NSString *queryString = [NSString stringWithFormat:@"users/%@", [self.user objectForKey:@"id"]];
    NSDictionary *options = @{@"is_blocked": @NO};
    [Network sendAsynchronousHTTPMethod:POST
                            withAPIName:queryString
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                            withOptions:options];
    [self.user setIsBlocked:NO];
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void){
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;}];
}


- (void)followPressed {
    [self.user setIsFollowing:YES];
    [self.user saveKeyAsynchronously:@"is_following"];
    if (self.userState == NOT_SENT_FOLLOWING_PRIVATE_USER) {
        self.userState = NOT_YET_ACCEPTED_PRIVATE_USER;
        [self.user setIsFollowingRequested:YES];
    }
    else {
        self.userState = FOLLOWING_USER;
        [self.user setIsFollowing:YES];
    }
    [self reloadViewForUserState];
    
}

- (void)unfollowPressed {
    if (self.userState == ACCEPTED_PRIVATE_USER) {
        self.userState = NOT_SENT_FOLLOWING_PRIVATE_USER;
    } else {
        self.userState = NOT_FOLLOWING_PUBLIC_USER;
    }
    
    [self.user setIsFollowing:NO];
    [self.user saveKeyAsynchronously:@"is_following"];
    
    [self reloadViewForUserState];
}


- (void)followersButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@3] animated:YES];
}

- (void)followingButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@4] animated:YES];
}

- (void)chatPressed {
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        ChatViewController *chatViewController = [ChatViewController new];
        chatViewController.view.backgroundColor = UIColor.whiteColor;
        [self.navigationController pushViewController:chatViewController animated:YES];
    }
    else {
       
        [self.navigationController pushViewController: [[ConversationViewController alloc] initWithUser:self.user] animated:YES];
    }
   
}


#pragma mark User State

- (void) reloadViewForUserState {
    if (self.userState == OTHER_SCHOOL_USER) {
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
    else if (self.userState == FOLLOWING_USER ||
        self.userState == ATTENDING_EVENT_FOLLOWING_USER ||
        self.userState == ATTENDING_EVENT_ACCEPTED_PRIVATE_USER) {
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
    else if (self.userState == NOT_FOLLOWING_PUBLIC_USER ||
             self.userState == NOT_SENT_FOLLOWING_PRIVATE_USER ||
             self.userState == BLOCKED_USER) {
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
        
        if (self.userState == NOT_FOLLOWING_PUBLIC_USER) _privateLogoImageView.hidden = YES;
        else _privateLogoImageView.hidden = NO;
        _followRequestLabel.hidden = YES;
    }
    else if (self.userState == NOT_YET_ACCEPTED_PRIVATE_USER) {
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
    if (self.userState == PUBLIC_PROFILE || self.userState == PRIVATE_PROFILE) {
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
        
        if (self.userState == PRIVATE_PROFILE) _privateLogoImageView.hidden = NO;
        else _privateLogoImageView.hidden = YES;
        _followRequestLabel.hidden = YES;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Block View

- (void)presentBlockPopView:(User *)user {
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
    isUserBlocked = [self.user isBlocked];
    [self.user setIsBlocked:NO];
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

- (BOOL)shouldShowFollowSummary {
    if ((self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) &&
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
    if (self.userState == PUBLIC_PROFILE || self.userState == PRIVATE_PROFILE) {
        int numberOfCellsForSummary =  [self shouldShowFollowSummary] ? 1 : 0;
        return [_nonExpiredNotificationsParty getObjectArray].count + numberOfCellsForSummary;
    }
    return [self shouldShowInviteCell] ? 1 : 0;
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
        
        if ([goOutsCell respondsToSelector:@selector(layoutMargins)]) {
            goOutsCell.layoutMargins = UIEdgeInsetsMake(0, goOutsCell.contentView.frame.size.width, 0, 0);
        }
        
        return goOutsCell;
    }
    
    else if (indexPath.section == kNotificationsSection) {
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
        Notification *notification = [[_nonExpiredNotificationsParty getObjectArray] objectAtIndex:[indexPath row]];
        if ([notification fromUserID] == (id)[NSNull null]) return notificationCell;
        if ([[notification type] isEqualToString:@"group.unlocked"]) return notificationCell;
        User *user = [[User alloc] initWithDictionary:[notification fromUser]];
        [notificationCell.profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
        notificationCell.descriptionLabel.text = [NSString stringWithFormat:@"%@ %@", [user firstName] , [notification message] ];
        
        if ([user getUserState] == NOT_SENT_FOLLOWING_PRIVATE_USER || [user getUserState] == NOT_YET_ACCEPTED_PRIVATE_USER) {
            notificationCell.rightPostImageView.hidden = YES;
        }
        else notificationCell.rightPostImageView.hidden = NO;
        if ([notificationCell respondsToSelector:@selector(layoutMargins)]) {
            notificationCell.layoutMargins = UIEdgeInsetsZero;
        }
        
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
        return 65;
    }
    else if (indexPath.section == kImageViewSection) {
        return self.imageScrollView.frame.size.height - _nameView.frame.size.height;
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
    if (indexPath.section == kNotificationsSection) {
        if ([self isIndexPathASummaryCell:indexPath]) {
            [self.navigationController pushViewController:[FollowRequestsViewController new] animated:YES];
        }
        else {
            if ([_followRequestSummary intValue] > 0) indexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
            Notification *notification = [[_nonExpiredNotificationsParty getObjectArray] objectAtIndex:indexPath.row];
            User *user = [[User alloc] initWithDictionary:[notification fromUser]];
           
            if ([[notification type] isEqualToString:@"follow"]) {
                FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
                [fancyProfileViewController setStateWithUser:user];
                fancyProfileViewController.eventsParty = self.eventsParty;
                [self.navigationController pushViewController: fancyProfileViewController animated: YES];
            }
            else {
                if ([user getUserState] != NOT_YET_ACCEPTED_PRIVATE_USER && [user getUserState] != NOT_SENT_FOLLOWING_PRIVATE_USER) {
                    Event *event = [[Event alloc] initWithDictionary:[user objectForKey:@"is_attending"]];
                    [self presentEvent:event];
                }
            }
 
            
        }
    }
  
}

- (void)presentEvent:(Event *)event {
    BOOL isEventPresentInArray = NO;
    NSArray *eventsArray = [self.eventsParty getObjectArray];
    for (int i = 0; i < [eventsArray count]; i++) {
        Event *newEvent = [eventsArray objectAtIndex:i];
        if ([[newEvent eventID] isEqualToNumber:[event eventID]]) {
            event = newEvent;
            isEventPresentInArray = YES;
            break;
        }
    }
    if (isEventPresentInArray) {
        EventStoryViewController *eventStoryViewController = [EventStoryViewController new];
        eventStoryViewController.event = event;
        eventStoryViewController.view.backgroundColor = UIColor.whiteColor;
        [self.navigationController pushViewController: eventStoryViewController animated:YES];
    }
    else [self fetchEvent:event];
}

- (void)inviteTapped {
    if ([self.user isTapped]) {
        [self.user setIsTapped:NO];
        [Network sendUntapToUserWithId:[self.user objectForKey:@"id"]];
    }
    else {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Profile", @"Tap Source", nil];
        [EventAnalytics tagEvent:@"Tap User" withDetails:options];
        [self.user setIsTapped:YES];
        [Network sendAsynchronousTapToUserWithIndex:[self.user objectForKey:@"id"]];
    }
    [self.tableView reloadData];
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
            queryString = [NSString stringWithFormat:@"notifications/?page=%@" ,[_page stringValue]];
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
                if ([_page isEqualToNumber:@1]) [self updateLastNotificationsRead];
                _page = @([_page intValue] + 1);
                
                self.tableView.separatorColor = [self.tableView.separatorColor colorWithAlphaComponent: 1.0f];
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

- (void)fetchEvent:(Event *)event {
    [Network sendAsynchronousHTTPMethod:GET withAPIName:[NSString stringWithFormat:@"events/%@", [event eventID]] withHandler:^(NSDictionary *jsonResponse, NSError *error) {        dispatch_async(dispatch_get_main_queue(), ^(void){
        if (!error) {
            Event *newEvent = [[Event alloc] initWithDictionary:jsonResponse];
            EventStoryViewController *eventStoryViewController = [EventStoryViewController new];
            eventStoryViewController.event = newEvent;
            eventStoryViewController.view.backgroundColor = UIColor.whiteColor;
            [self.navigationController pushViewController: eventStoryViewController animated:YES];
        }
    });
    }];
}


- (void)fetchSummaryOfFollowRequests {
    [Network queryAsynchronousAPI:@"notifications/summary/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ([[jsonResponse allKeys] containsObject:@"follow.request"])
                _followRequestSummary = (NSNumber *)[jsonResponse objectForKey:@"follow.request"];
            else
                _followRequestSummary = @0;
            [self.tableView reloadData];
        });
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
    
    self.buttonCallback = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 27 - 14, self.frame.size.height/2  - 13, 27, 27)];
    [self.buttonCallback addTarget:self action:@selector(tapPressed) forControlEvents:UIControlEventTouchUpInside];
    self.tapImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 27, 27)];
    self.tapImageView.image = [UIImage imageNamed:@"tapUnselectedNotification"];
    [self.buttonCallback addSubview:self.tapImageView];
    self.buttonCallback.hidden = YES;
    [self.contentView addSubview:self.buttonCallback];
    
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

- (void) awakeFromNib {
    
}


+ (CGFloat)rowHeight {
    return 100.0f;
}

- (void) setLabelsForUser: (User *) user {
    
    NSNumber *newCount = (NSNumber *)[[user dictionary] objectForKey:@"period_went_out"];
    
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
    self.titleLabel.font = [FontProperties scLightFont: 24];
    self.titleLabel.textColor = [UIColor lightGrayColor];
    self.titleLabel.numberOfLines = 2;
    
    [self.contentView addSubview: self.titleLabel];
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

- (void) setLabelsForUser: (User *) user {
    if ([user isTapped]) {
        self.inviteButton.hidden = YES;
        self.titleLabel.text = @"Tapped";
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70.0f);
    }
    else {
        self.inviteButton.hidden = NO;
        self.titleLabel.text = kInviteTitleTemplate;
    }

}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70.0f);
    self.titleLabel.font = [FontProperties lightFont: 18];
    self.titleLabel.textColor = [UIColor lightGrayColor];
    
    self.inviteButton.titleLabel.font =  [FontProperties lightFont:18.0f];
    self.inviteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.borderColor = UIColor.whiteColor.CGColor;
    self.inviteButton.layer.cornerRadius = 7;
    [self.inviteButton addTarget: self action: @selector(inviteTapped) forControlEvents: UIControlEventTouchUpInside];
    
}
- (void) inviteTapped {
    [self.delegate inviteTapped];
}
@end
