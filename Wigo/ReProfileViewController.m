//
//  ProfileViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ReProfileViewController.h"
#import "Globals.h"

#import "UIButtonAligned.h"
#import "UIPageControlAligned.h"
#import "UIImageCrop.h"
#import "RWBlurPopover.h"
#import "ChatViewController.h"
#import <Parse/Parse.h>

@interface ReProfileViewController ()


// private
@property UIImageView *privateLogoImageView;

//favorite
@property UIButton *leftProfileButton;
@property UIButton *rightProfileButton;
@property UITapGestureRecognizer *tapScrollView;

//UIScrollView
@property UIPageControl *pageControl;
@property UIScrollView *scrollView;
@property CGPoint pointNow;
@property NSMutableArray *profileImagesArray;

//UI
@property UIButtonAligned *rightBarBt;
@property UIButton *followingButton;
@property UIButton *followersButton;
@property UIButton *followButton;
@property UILabel *followRequestLabel;

@property UIView *lastLineView;
@property UIView *nameOfPersonBackground;
@property UILabel *nameOfPersonLabel;


// Notifications table view
@property Party *notificationsParty;
@property NSNumber *page;
@property Party *nonExpiredNotificationsParty;
@property UITableView *notificationsTableView;
@end

BOOL isUserBlocked;
BOOL blockShown;
UIButton *tapButton;

@implementation ReProfileViewController


- (id)initWithUser:(User *)user {
    self = [super init];
    if (self && user && [Profile user]) {
        if ([user isEqualToUser:[Profile user]]) {
            self.user = [Profile user];
            self.userState = [self.user isPrivate] ? PRIVATE_PROFILE : PUBLIC_PROFILE;
        }
        else {
            self.user = user;
            self.userState = [user getUserState];
        }
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    _pageControl.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _pageControl.hidden = NO;
    if ([self.user getUserState] == BLOCKED_USER) [self presentBlockPopView:self.user];
    _page = @1;
    [self fetchNotifications];
    [self updateLastNotificationsRead];
    [self updateBadge];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    blockShown = NO;
    
    NSString *isCurrentUser = (self.user == [Profile user]) ? @"Yes" : @"No";
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:isCurrentUser, @"Self", nil];
    
    [EventAnalytics tagEvent:@"Profile View" withDetails:options];
    
    _profileImagesArray = [[NSMutableArray alloc] initWithCapacity:0];
   
    [self initializeNotificationHandlers];
    [self initializeFollowingAndFollowers];
    [self initializeFollowButton];
    [self initializeFollowRequestLabel];
    [self initializeLeftProfileButton];
    [self initializeMiddleProfileButton];
    [self initializeBottomTableView];
    [self reloadView];
}

- (void) initializeNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProfile) name:@"updateProfile" object:nil];
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unfollowPressed) name:@"unfollowPressed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockPressed:) name:@"blockPressed" object:nil];
}

- (void)reloadView {
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

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initializeProfileImage];
    [self initializeNameOfPerson];
    [self initializeTapButton];
    
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

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



- (void) initializeFollowingAndFollowers {
    _followingButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, self.view.frame.size.width + 50, self.view.frame.size.width/2, 50)];
    [_followingButton addTarget:self action:@selector(followingButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _followingButton.frame.size.height/2 - 12, _followingButton.frame.size.width, 24)];
    followingLabel.textColor = [FontProperties getOrangeColor];
    followingLabel.textAlignment = NSTextAlignmentCenter;
    followingLabel.text = [NSString stringWithFormat:@"Following (%d)", [(NSNumber*)[self.user objectForKey:@"num_following"] intValue]];
    followingLabel.font = [FontProperties getTitleFont];
    followingLabel.lineBreakMode = NSLineBreakByWordWrapping;
    followingLabel.numberOfLines = 0;
    [_followingButton addSubview:followingLabel];
    [self.view addSubview:_followingButton];
    
    _followersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, self.view.frame.size.width, self.view.frame.size.width/2, 50)];
    [_followersButton addTarget:self action:@selector(followersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _followersButton.frame.size.height/2 - 12, _followingButton.frame.size.width, 24)];
    followersLabel.textColor = [FontProperties getOrangeColor];
    followersLabel.font = [FontProperties getTitleFont];
    followersLabel.textAlignment = NSTextAlignmentCenter;
    followersLabel.text = [NSString stringWithFormat:@"Followers (%d)", [(NSNumber*)[self.user objectForKey:@"num_followers"] intValue]];
    followersLabel.lineBreakMode = NSLineBreakByWordWrapping;
    followersLabel.numberOfLines = 0;
    [_followersButton addSubview:followersLabel];
    [self.view addSubview:_followersButton];
}

- (void) editPressed {
    self.editProfileViewController = [[EditProfileViewController alloc] init];
    self.editProfileViewController.view.backgroundColor = RGB(235, 235, 235);
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: self.editProfileViewController];
    [self presentViewController: navController animated: YES completion: nil];
}

- (void)unfollowPressed {
    self.userState = NOT_FOLLOWING_PUBLIC_USER;
    [self reloadView];
    [self.user setIsFollowing:NO];
    [self.user saveKeyAsynchronously:@"is_following"];
}

- (void)unblockPressed {
    NSString *queryString = [NSString stringWithFormat:@"users/%@", [self.user objectForKey:@"id"]];
    NSDictionary *options = @{@"is_blocked": @NO};
    [Network sendAsynchronousHTTPMethod:POST
                            withAPIName:queryString
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                            withOptions:options];
    [self.user setIsBlocked:NO];
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void){}];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

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
    [self reloadView];
    
}

- (void)morePressed {
    self.moreViewController = [[MoreViewController alloc] initWithUser:self.user];
    [[RWBlurPopover instance] presentViewController:self.moreViewController withOrigin:0 andHeight:self.view.frame.size.height];
}


- (void)initializeProfileImage {
    if (self.userState == PUBLIC_PROFILE || self.userState == PRIVATE_PROFILE) {
        self.user = [Profile user];
    }
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
    [_scrollView setShowsHorizontalScrollIndicator:NO];
    _scrollView.layer.borderWidth = 1;
    _scrollView.backgroundColor = RGB(23,23,23);
    _scrollView.delegate = self;
    
    // DISPLAY CONTENT PROPERLY (Scroll View)
    // IOS 6 and less
    _scrollView.contentOffset = CGPointZero;
    _scrollView.contentInset = UIEdgeInsetsZero;
    // IOS 7+
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.view addSubview:_scrollView];
    
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.enabled = NO;
    _pageControl.currentPage = 0;
    _pageControl.currentPageIndicatorTintColor = UIColor.whiteColor;
    _pageControl.pageIndicatorTintColor = RGBAlpha(255, 255, 255, 0.4f);
    _pageControl.center = CGPointMake(self.view.center.x, 25);

    [self.navigationController.navigationBar addSubview: _pageControl];
    [self updateProfile];
}


- (void) updateProfile {
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_profileImagesArray removeAllObjects];
    _pageControl.numberOfPages = [[self.user imagesURL] count];
    
    for (int i = 0; i < [[self.user imagesURL] count]; i++) {
        UIImageView *profileImgView = [[UIImageView alloc] init];
        profileImgView.contentMode = UIViewContentModeScaleAspectFill;
        profileImgView.clipsToBounds = YES;
        profileImgView.frame = CGRectMake((self.view.frame.size.width + 10) * i, 0, self.view.frame.size.width, self.view.frame.size.width);
        
        NSDictionary *area = [[self.user imagesArea] objectAtIndex:i];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        spinner.center = CGPointMake((self.view.frame.size.width + 10) * i + self.view.frame.size.width/2, self.view.frame.size.width/2);
        [_scrollView addSubview:spinner];
        [spinner startAnimating];
        __weak UIActivityIndicatorView *weakSpinner = spinner;
        NSDictionary *info = @{@"user": self.user,
                               @"images": [self.user images],
                               @"index": [NSNumber numberWithInt:i]};
        [profileImgView setImageWithURL:[NSURL URLWithString:[[self.user imagesURL] objectAtIndex:i]]
                              imageArea:area
                               withInfo:info
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  [weakSpinner stopAnimating];
                              }];
        [_scrollView addSubview:profileImgView];
        [_profileImagesArray addObject:profileImgView];
    }
    [_scrollView setContentSize:CGSizeMake((self.view.frame.size.width + 10) * [[self.user imagesURL] count] - 10, [[UIScreen mainScreen] bounds].size.width)];
}

- (void) initializeFollowButton {
    _followButton = [[UIButton alloc] initWithFrame:CGRectMake(25, self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
    [_followButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchUpInside];
    _followButton.layer.cornerRadius = 15;
    _followButton.layer.borderWidth = 1;
    _followButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    
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
    
    [self.view addSubview:_followButton];
}


- (void)initializeFollowRequestLabel {
    _followRequestLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
    _followRequestLabel.text = @"Your follow request has been sent";
    _followRequestLabel.textAlignment = NSTextAlignmentCenter;
    _followRequestLabel.textColor = [FontProperties getOrangeColor];
    _followRequestLabel.font = [FontProperties scMediumFont:16.0f];
    if (self.userState == NOT_YET_ACCEPTED_PRIVATE_USER) _followRequestLabel.hidden = NO;
    else _followRequestLabel.hidden = YES;
    [self.view addSubview:_followRequestLabel];
}

- (void)initializeNameOfPerson {
    UIImageView *topGradientBackground =[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    topGradientBackground.image = [UIImage imageNamed:@"topGradientBackground"];
    [self.view addSubview:topGradientBackground];
    [self.view bringSubviewToFront:topGradientBackground];
    [self.view bringSubviewToFront:_pageControl];
    
//    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 65, 44)];
//    [backButton setImage:[UIImage imageNamed:@"whiteBackButton"] forState:UIControlStateNormal];
//    [backButton setTitle:@" Back" forState:UIControlStateNormal];
//    [backButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
//    backButton.titleLabel.font = [FontProperties getSubtitleFont];
//    [backButton addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:backButton];
    
//    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 75, 0, 65, 44)];
//    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
//        [rightButton setTitle:@"Edit" forState:UIControlStateNormal];
//        [rightButton addTarget:self action: @selector(editPressed) forControlEvents:UIControlEventTouchUpInside];
//        
//    }
//    else  {
//        [rightButton setTitle:@"More" forState:UIControlStateNormal];
//        [rightButton addTarget:self action: @selector(morePressed) forControlEvents:UIControlEventTouchUpInside];
//    }
//    rightButton.titleLabel.font = [FontProperties getSubtitleFont];
//    [self.view addSubview:rightButton];

    _nameOfPersonBackground = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width - 80, self.view.frame.size.width, 80)];
    UIImageView *gradientBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    gradientBackground.image = [UIImage imageNamed:@"backgroundGradient"];
    [_nameOfPersonBackground addSubview:gradientBackground];
    
    _nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 15, self.view.frame.size.width - 14, 50)];
    if ([self.user getUserState] == ATTENDING_EVENT_FOLLOWING_USER ||
        [self.user getUserState] == ATTENDING_EVENT_ACCEPTED_PRIVATE_USER) {
        _nameOfPersonLabel.numberOfLines = 0;
        _nameOfPersonLabel.textAlignment = NSTextAlignmentLeft;
        if ([[Profile user] isAttending] && [[self.user attendingEventID] isEqualToNumber:[[Profile user] attendingEventID]]) {
            NSString *textOfLabel = [NSString stringWithFormat:@"%@ is also going to: %@", [self.user fullName], [self.user attendingEventName]];
            NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:textOfLabel];
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [self.user fullName].length)];
            [string addAttribute:NSForegroundColorAttributeName value:RGB(201, 202, 204) range:NSMakeRange([self.user fullName].length, string.length - [self.user fullName].length)];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            style.lineSpacing = 5;
            [style setAlignment:NSTextAlignmentCenter];
            [string addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, [string length])];
            _nameOfPersonLabel.attributedText = string;
        }
        else {
            NSString *textOfLabel = [NSString stringWithFormat:@"%@ is going to: %@", [self.user fullName], [self.user attendingEventName]];
            NSMutableString *cutOffText;
            if (textOfLabel.length > 67) {
                cutOffText = [NSMutableString stringWithString:[textOfLabel substringWithRange: NSMakeRange(0, MIN(64, textOfLabel.length))]];
                [cutOffText appendString:@"..."];
            }
            else {
                cutOffText = [NSMutableString stringWithString:textOfLabel];
            }
            
            NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:cutOffText];
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [self.user fullName].length)];
            [string addAttribute:NSForegroundColorAttributeName value:RGB(201, 202, 204) range:NSMakeRange([self.user fullName].length, string.length - [self.user fullName].length)];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            style.lineSpacing = 5;
            [string addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, [string length])];
            _nameOfPersonLabel.attributedText = string;
            
            UIButton *goHereTooButton = [[UIButton alloc] init];
            [goHereTooButton setTitle:@"GO HERE" forState:UIControlStateNormal];
            [goHereTooButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            goHereTooButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            goHereTooButton.titleLabel.font = [FontProperties getSmallPhotoFont];
            goHereTooButton.layer.borderColor = RGB(201, 202, 204).CGColor;
            goHereTooButton.layer.borderWidth = 1;
            goHereTooButton.layer.cornerRadius = 4;
            [goHereTooButton addTarget:self action:@selector(goThereTooPressed) forControlEvents:UIControlEventTouchUpInside];
            
            CGFloat requiredWidth =  [_nameOfPersonLabel.text sizeWithAttributes:@{NSFontAttributeName:[FontProperties getSmallFont]}].width;
            if (requiredWidth < self.view.frame.size.width - 14 - 10) {
                CGRect frame = _nameOfPersonLabel.frame;
                frame.origin.y -= 10;
                _nameOfPersonLabel.frame = frame;
                _nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
                goHereTooButton.frame = CGRectMake(self.view.frame.size.width/2 - 48, 45, 95, 25);
                [_nameOfPersonBackground addSubview:goHereTooButton];
                
            }
            else {
                goHereTooButton.frame = CGRectMake(_nameOfPersonBackground.frame.size.width - 95 - 7, _nameOfPersonLabel.frame.origin.y + _nameOfPersonLabel.frame.size.height - 25, 95, 25);
                [_nameOfPersonBackground addSubview:goHereTooButton];
            }
            
        }
    }
    else if ([self.user isGoingOut] && ![self.user isEqualToUser:[Profile user]]) {
        _nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
        NSString *textOfLabel = [NSString stringWithFormat:@"%@ is going out", [self.user fullName]];
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:textOfLabel];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [self.user fullName].length)];
        [string addAttribute:NSForegroundColorAttributeName value:RGB(201, 202, 204) range:NSMakeRange([self.user fullName].length, string.length - [self.user fullName].length)];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = 5;
        [style setAlignment:NSTextAlignmentCenter];
        [string addAttribute:NSParagraphStyleAttributeName
                       value:style
                       range:NSMakeRange(0, [string length])];
        _nameOfPersonLabel.attributedText = string;
    }
    else {
        _nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
        _nameOfPersonLabel.text = [self.user fullName];
        _nameOfPersonLabel.textColor = [UIColor whiteColor];
        _nameOfPersonLabel.font = [FontProperties getSubHeaderFont];
    }
    
    [_nameOfPersonBackground addSubview:_nameOfPersonLabel];
    [self.view addSubview:_nameOfPersonBackground];
    [self.view bringSubviewToFront:_nameOfPersonBackground];
    
    _privateLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 80 - 40 - 9, 16, 22)];
    _privateLogoImageView.image = [UIImage imageNamed:@"privateIcon"];
    if (self.userState == ACCEPTED_PRIVATE_USER || self.userState == NOT_YET_ACCEPTED_PRIVATE_USER || self.userState == PRIVATE_PROFILE) {
        _privateLogoImageView.hidden = NO;
    }
    else _privateLogoImageView.hidden = YES;
    [_nameOfPersonBackground addSubview:_privateLogoImageView];
    [_nameOfPersonBackground bringSubviewToFront:_privateLogoImageView];
    
}

- (void) initializeTapButton {
    if ([[Profile user] isGoingOut] && ![self.user isEqualToUser:[Profile user]] && ([self.user getUserState] == ATTENDING_EVENT_FOLLOWING_USER || [self.user getUserState] == FOLLOWING_USER || [self.user getUserState] == ATTENDING_EVENT_ACCEPTED_PRIVATE_USER) ) {
        UIButton *aroundTapButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 0, 60, 60)];
        [aroundTapButton addTarget:self action:@selector(tapPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:aroundTapButton];
        tapButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40 - 20, 20, 40, 40)];
        if ([self.user isTapped]) {
            [tapButton setBackgroundImage:[UIImage imageNamed:@"tapSelectedProfile"] forState:UIControlStateNormal];
        }
        else {
            [tapButton setBackgroundImage:[UIImage imageNamed:@"tapUnselectedProfile"] forState:UIControlStateNormal];
        }
        [tapButton addTarget:self action:@selector(tapPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view bringSubviewToFront:tapButton];
        [self.view addSubview:tapButton];
    }
}

- (void)tapPressed {
    if ([self.user isTapped]) {
        [tapButton setBackgroundImage:[UIImage imageNamed:@"tapUnselectedProfile"] forState:UIControlStateNormal];
        [self.user setIsTapped:NO];
        [Network sendUntapToUserWithId:[self.user objectForKey:@"id"]];
    }
    else {
        [tapButton setBackgroundImage:[UIImage imageNamed:@"tapSelectedProfile"] forState:UIControlStateNormal];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Profile", @"Tap Source", nil];
        [EventAnalytics tagEvent:@"Tap User" withDetails:options];
        [self.user setIsTapped:YES];
        [Network sendAsynchronousTapToUserWithIndex:[self.user objectForKey:@"id"]];
    }
}

- (void)goThereTooPressed {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Profile", @"Go Here Source", nil];
    [EventAnalytics tagEvent:@"Go Here" withDetails:options];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[Profile user] setIsAttending:YES];
    [[Profile user] setIsGoingOut:YES];
    [[Profile user] setAttendingEventID:[self.user  attendingEventID]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabs" object:nil];
    
    [Network postGoingToEventNumber:[[self.user  attendingEventID] intValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
}

- (void)initializeLeftProfileButton {
    _leftProfileButton = [[UIButton alloc] init];
    
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        _leftProfileButton.frame = CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width/3, 70);
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
    }

    [self.view addSubview:_leftProfileButton];
}

- (void)leftProfileButtonPressed {
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        [self followersButtonPressed];
    }
}

- (void)initializeMiddleProfileButton {
    _rightProfileButton = [[UIButton alloc] init];
    [_rightProfileButton addTarget:self action:@selector(rightProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        _rightProfileButton.frame = CGRectMake(self.view.frame.size.width/3, self.view.frame.size.width, self.view.frame.size.width/3, 70);
        
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
        
    }
    else {
        _rightProfileButton.frame = CGRectMake(3*self.view.frame.size.width/4, self.view.frame.size.width, self.view.frame.size.width/4, 100);
        UIImageView *chatImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatImage"]];
        chatImageView.frame = CGRectMake(_rightProfileButton.frame.size.width/2 - 12, _rightProfileButton.frame.size.height/2 - 12 - 11, 24, 24);
        UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(_rightProfileButton.frame.size.width/2 - 20, _rightProfileButton.frame.size.height/2 + 12 - 3, 40, 15)];
        chatLabel.textAlignment = NSTextAlignmentCenter;
        chatLabel.text = @"Chat";
        chatLabel.textColor = [FontProperties getOrangeColor];
        chatLabel.font = [FontProperties getSubtitleFont];
        [_rightProfileButton addSubview:chatLabel];
        [_rightProfileButton addSubview:chatImageView];
    }
    [self.view addSubview:_rightProfileButton];
    
    UIButton *chatButton = [[UIButton alloc] initWithFrame:CGRectMake(2*self.view.frame.size.width/3, self.view.frame.size.width, self.view.frame.size.width/3, 70)];
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
    
    [self.view addSubview:chatButton];
}

- (void)followersButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@3] animated:YES];
}

- (void)followingButtonPressed {
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:self.user andTab:@4] animated:YES];
}

- (void)rightProfileButtonPressed {
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        [self followingButtonPressed];
    }
    else {
        self.conversationViewController = [[ConversationViewController alloc] initWithUser:self.user];
        [self.navigationController pushViewController:self.conversationViewController animated:YES];
    }
}

- (void)chatPressed {
    ChatViewController *chatViewController = [ChatViewController new];
    chatViewController.view.backgroundColor = UIColor.whiteColor;
    [self.navigationController pushViewController:chatViewController animated:YES];
}

#pragma mark UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    _pageControl.currentPage = page;
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _pointNow = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        if (scrollView.contentOffset.x < _pointNow.x) {
            [self stoppedScrollingToLeft:YES];
        } else if (scrollView.contentOffset.x >= _pointNow.x) {
            [self stoppedScrollingToLeft:NO];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView.contentOffset.x < _pointNow.x) {
        [self stoppedScrollingToLeft:YES];
    } else if (scrollView.contentOffset.x >= _pointNow.x) {
        [self stoppedScrollingToLeft:NO];
    }
}

- (void)stoppedScrollingToLeft:(BOOL)leftBoolean
{
    CGFloat pageWidth = _scrollView.frame.size.width; // you need to have a **iVar** with getter for scrollView
    float fractionalPage = _scrollView.contentOffset.x / pageWidth;
    NSInteger page;
    if (leftBoolean) {
        if (fractionalPage - floor(fractionalPage) < 0.8) {
            page = floor(fractionalPage);
        }
        else {
            page = ceil(fractionalPage);
        }
    }
    else {
        if (fractionalPage - floor(fractionalPage) < 0.2) {
            page = floor(fractionalPage);
        }
        else {
            page = ceil(fractionalPage);
        }
    }
    [_scrollView setContentOffset:CGPointMake((self.view.frame.size.width + 10) * page, 0.0f) animated:YES];
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
    
    UIButton *unblockButton = [[UIButton alloc] initWithFrame:CGRectMake(25, self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
    [unblockButton addTarget:self action:@selector(unblockPressed) forControlEvents:UIControlEventTouchUpInside];
    unblockButton.layer.cornerRadius = 15;
    unblockButton.layer.borderWidth = 1;
    unblockButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [unblockButton setTitle:[NSString stringWithFormat:@"Unblock %@", [user firstName]] forState:UIControlStateNormal];
    [unblockButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    unblockButton.titleLabel.font = [FontProperties scMediumFont:24.0f];
    [popViewController.view addSubview:unblockButton];
    
    [[RWBlurPopover instance] presentViewController:popViewController withOrigin:0 andHeight:popViewController.view.frame.size.height];
}

- (void)dismissAndGoBack {
    isUserBlocked = [self.user isBlocked];
    [self.user setIsBlocked:NO];
    [self goBack];
    [[RWBlurPopover instance] dismissViewControllerAnimated:NO completion:^(void){}];
}

#pragma mark - Notifications bottom

- (void)initializeBottomTableView {
    _notificationsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width + 60, self.view.frame.size.width, self.view.frame.size.height - 412)];
    _notificationsTableView.delegate = self;
    _notificationsTableView.dataSource = self;
    _notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_notificationsTableView registerClass:[NotificationCell_old class] forCellReuseIdentifier:kNotificationCellName_old];
    [self.view addSubview:_notificationsTableView];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationCell_old *notificationCell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellName_old forIndexPath:indexPath];
    Notification *notification = [[_nonExpiredNotificationsParty getObjectArray] objectAtIndex:[indexPath row]];
    if ([notification fromUserID] == (id)[NSNull null]) return notificationCell;
    if ([[notification type] isEqualToString:@"group.unlocked"]) return notificationCell;
    User *user = [[User alloc] initWithDictionary:[notification fromUser]];
    [notificationCell.profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    notificationCell.descriptionLabel.text = [NSString stringWithFormat:@"%@ %@", [user firstName] ,[notification message] ];
    return notificationCell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [_nonExpiredNotificationsParty getObjectArray].count;
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
                [_notificationsTableView reloadData];
                [_notificationsTableView didFinishPullToRefresh];
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


@implementation NotificationCell_old

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

