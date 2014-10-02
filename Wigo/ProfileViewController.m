//
//  ProfileViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ProfileViewController.h"
#import "Globals.h"

#import "UIButtonAligned.h"
#import "UIPageControlAligned.h"
#import "UIImageCrop.h"
#import "RWBlurPopover.h"


@interface ProfileViewController ()


// bio
@property UILabel *bioPrefix;
@property UILabel *bioLabel;
@property UIView *bioLineView;
@property UIImageView *privateLogoImageView;

//favorite
@property UIButton *leftProfileButton;
@property UIImageView *favoriteImageView;
@property UIButton *rightProfileButton;
@property UITapGestureRecognizer *tapScrollView;

//UIScrollView
@property int currentPage;

@property UIPageControl *pageControl;
@property BOOL isSeingImages;
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

@end

BOOL isUserBlocked;
BOOL blockShown;
UIButton *tapButton;

@implementation ProfileViewController


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

- (void)viewDidDisappear:(BOOL)animated {
    _pageControl.hidden = YES;
}


- (void)viewDidAppear:(BOOL)animated {
    _pageControl.hidden = NO;
    if ([self.user getUserState] == BLOCKED_USER) [self presentBlockPopView:self.user];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    blockShown = NO;
   
    NSString *isCurrentUser = (self.user == [Profile user]) ? @"Yes" : @"No";
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:isCurrentUser, @"Self", nil];
    
    [EventAnalytics tagEvent:@"Profile View" withDetails:options];

    _currentPage = 0;
    _isSeingImages = NO;
    _profileImagesArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    [self initializeNotificationHandlers];
    [self initializeLeftBarButton];
    [self initializeBioLabel];
    [self initializeRightBarButton];
    [self initializeFollowingAndFollowers];
    [self initializeFollowButton];
    [self initializeFollowRequestLabel];
    [self initializeLeftProfileButton];
    [self initializeRightProfileButton];
    [self reloadView];
}

- (void) initializeNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProfile) name:@"updateProfile" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chooseImage) name:@"chooseImage" object:nil];
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
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) goBack {
    if (![self.user isEqualToUser:[Profile user]]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self.user dictionary]];
        if (isUserBlocked) [userInfo setObject:[NSNumber numberWithBool:isUserBlocked] forKey:@"is_blocked"];
        isUserBlocked = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUserAtTable" object:nil userInfo:userInfo];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initializeRightBarButton {
    UITabBarController *tabController = (UITabBarController *)self.parentViewController;
    tabController.navigationItem.rightBarButtonItem = nil;
    
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        _rightBarBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@1];
        [_rightBarBt setTitle:@"Edit" forState:UIControlStateNormal];
        [_rightBarBt addTarget:self action: @selector(editPressed) forControlEvents:UIControlEventTouchUpInside];
        
    }
    else  {
        _rightBarBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@1];
        [_rightBarBt setTitle:@"More" forState:UIControlStateNormal];
        [_rightBarBt addTarget:self action: @selector(morePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    _rightBarBt.titleLabel.font = [FontProperties getSubtitleFont];
    [_rightBarBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:_rightBarBt];
    self.navigationItem.rightBarButtonItem = barItem;
}


- (void) initializeFollowingAndFollowers {
    _followingButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, 64 + self.view.frame.size.width + 50, self.view.frame.size.width/2, 50)];
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
    
    _followersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 50)];
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
    [self.navigationController pushViewController:self.editProfileViewController animated:YES];
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

    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.width)];
    [_scrollView setShowsHorizontalScrollIndicator:NO];
    _scrollView.layer.borderWidth = 1;
    _scrollView.backgroundColor = RGB(23,23,23);
    _tapScrollView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseImage)];
    _tapScrollView.cancelsTouchesInView = NO;
    [_scrollView addGestureRecognizer:_tapScrollView];
    _scrollView.delegate = self;
    
    // DISPLAY CONTENT PROPERLY (Scroll View)
    // IOS 6 and less
    _scrollView.contentOffset = CGPointZero;
    _scrollView.contentInset = UIEdgeInsetsZero;
    // IOS 7+
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.view addSubview:_scrollView];
    
    
    UIView *firstLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _scrollView.frame.origin.y, self.view.frame.size.width, 1)];
    firstLineView.backgroundColor = [FontProperties getOrangeColor];
    [self.view addSubview:firstLineView];

    _pageControl = [[UIPageControl alloc] init];
    _pageControl.enabled = NO;
    _pageControl.currentPage = 0;
    _pageControl.currentPageIndicatorTintColor = [FontProperties getOrangeColor];
    _pageControl.pageIndicatorTintColor = [UIColor grayColor];

    UIView *pageControlView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 44)];
    [pageControlView addSubview: _pageControl];
    self.navigationItem.titleView = pageControlView;
    [self updateProfile];
}


- (void) updateProfile {
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_profileImagesArray removeAllObjects];
    _pageControl.numberOfPages = [[self.user imagesURL] count];
    // HACK
    _pageControl.center = CGPointMake(90, 25);
    
    for (int i = 0; i < [[self.user imagesURL] count]; i++) {
        UIImageView *profileImgView = [[UIImageView alloc] init];
        profileImgView.contentMode = UIViewContentModeScaleAspectFill;
        profileImgView.clipsToBounds = YES;
        profileImgView.frame = CGRectMake((self.view.frame.size.width + 10) * i, 0, self.view.frame.size.width, self.view.frame.size.width);

        NSDictionary *area = [[self.user imagesArea] objectAtIndex:i];

        __weak UIImageView *weakProfileImgView = profileImgView;
        [profileImgView setImageWithURL:[NSURL URLWithString:[[self.user imagesURL] objectAtIndex:i]] imageArea:area completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [self addBlurredImageToImageView:weakProfileImgView forIndex:i];
        }];
        [_scrollView addSubview:profileImgView];
        [_profileImagesArray addObject:profileImgView];
    }
    [_scrollView setContentSize:CGSizeMake((self.view.frame.size.width + 10) * [[self.user imagesURL] count] - 10, 320)];
    _bioLabel.frame = CGRectMake(7, 64 + self.view.frame.size.width + 90 + 5 + 10, self.view.frame.size.width - 14, 80);
    _bioLabel.text = [NSString stringWithFormat:@"        %@" , [self.user bioString]];
    [_bioLabel sizeToFit];
    _bioLabel.hidden = NO;

}

- (void) addBlurredImageToImageView:(UIImageView *)imageView forIndex:(int)i {
    UIImage *imageRightSize = [UIImageCrop imageFromImageView:imageView];
    UIImage *croppedImage = [UIImageCrop croppingImage:imageRightSize toRect:CGRectMake(0, imageView.frame.size.height - 80, self.view.frame.size.width, 80)];
    UIImageView *croppedImageView = [[UIImageView alloc] initWithImage:croppedImage];
    croppedImageView.frame = CGRectMake(0, imageView.frame.size.height - 80, imageView.frame.size.width, 80);

    UIImage *blurredImage = [UIImageCrop blurredImageFromImageView:croppedImageView withRadius:10.0f];
    croppedImageView.image = blurredImage;
    // IF THE USER IS NOT SEEING THEIR PHOTOS FULL SCREEN then add blur
    if (!_isSeingImages) {
        [imageView addSubview:croppedImageView];
    }
}

- (void)deleteBlurredImageFromImageView:(UIImageView *)imageView {
    for (UIView *subview in imageView.subviews) {
        [subview removeFromSuperview];
    }
}

- (void) initializeFollowButton {
    _followButton = [[UIButton alloc] initWithFrame:CGRectMake(25, 64 + self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
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
    _followRequestLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 64 + self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
    _followRequestLabel.text = @"Your follow request has been sent";
    _followRequestLabel.textAlignment = NSTextAlignmentCenter;
    _followRequestLabel.textColor = [FontProperties getOrangeColor];
    _followRequestLabel.font = [FontProperties scMediumFont:16.0f];
    if (self.userState == NOT_YET_ACCEPTED_PRIVATE_USER) _followRequestLabel.hidden = NO;
    else _followRequestLabel.hidden = YES;
    [self.view addSubview:_followRequestLabel];
}


- (void)chooseImage {
    [self setNeedsStatusBarAppearanceUpdate];
    if (!_isSeingImages) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        _isSeingImages = YES;
        _lastLineView.hidden = NO;
        if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
            _pageControl.center = CGPointMake(73, 25);
        }
        else {
            _pageControl.center = CGPointMake(73, 25);
        }

        self.navigationController.navigationBar.barTintColor = RGB(23, 23, 23);
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"closeButton"] style:UIBarButtonItemStylePlain target:self action:@selector(chooseImage)];
        [closeButton setTintColor:[UIColor whiteColor]];
        self.navigationItem.leftBarButtonItem = closeButton;
        self.navigationItem.rightBarButtonItem = nil;
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                            animations:^{
                                _nameOfPersonBackground.transform =  CGAffineTransformMakeTranslation(0, _nameOfPersonBackground.frame.size.height);
                                _bioLabel.textColor = [UIColor whiteColor];
                                self.view.backgroundColor = RGB(23, 23, 23);
                                _nameOfPersonBackground.backgroundColor = RGB(23, 23, 23);
                                
                                _bioLineView.hidden = YES;
                                _followButton.hidden = YES;
                                _leftProfileButton.hidden = YES;
                                _rightProfileButton.hidden = YES;
                                _followingButton.hidden = YES;
                                _followersButton.hidden = YES;
                                for (UIImageView *profileImageView in _profileImagesArray) {
                                    [self deleteBlurredImageFromImageView:profileImageView];
                                }
                            }
                            completion:nil
         ];
    }
    else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        _tapScrollView.enabled = YES;
        _isSeingImages = NO;
        _lastLineView.hidden = YES;
        [self initializeLeftBarButton];
        [self initializeRightBarButton];
        _pageControl.center = CGPointMake(90, 25);
        [UIView animateWithDuration:0.2
                         animations:^{
                             _bioPrefix.hidden = NO;
                             _bioLabel.hidden = NO;
                             _nameOfPersonBackground.transform =  CGAffineTransformMakeTranslation(0, 0);
                             _nameOfPersonBackground.backgroundColor = RGBAlpha(23, 23, 23, 0.7f);
                             [self.view bringSubviewToFront:_nameOfPersonBackground];
                             self.view.backgroundColor = [UIColor whiteColor];
                             self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
                             _bioLabel.textColor = [UIColor blackColor];
                             [self reloadView];

        } completion:^(BOOL finished) {
            _bioLineView.hidden = NO;

            for (int i = 0; i < [_profileImagesArray count]; i++) {
                UIImageView *profileImageView = [_profileImagesArray objectAtIndex:i];
                [self addBlurredImageToImageView:profileImageView forIndex:i];
            }
        }];
    }
}

- (void)initializeNameOfPerson {
    _nameOfPersonBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 64 + self.view.frame.size.width - 80, self.view.frame.size.width, 80)];
    _nameOfPersonBackground.backgroundColor = RGBAlpha(23, 23, 23, 0.7f);
    
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
    else {
        _nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
        _nameOfPersonLabel.text = [self.user fullName];
        _nameOfPersonLabel.textColor = [UIColor whiteColor];
        _nameOfPersonLabel.font = [FontProperties getSubHeaderFont];
    }
    
    _lastLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    _lastLineView.backgroundColor = [FontProperties getOrangeColor];
    _lastLineView.hidden = YES;
    [_nameOfPersonBackground addSubview:_lastLineView];
    [_nameOfPersonBackground bringSubviewToFront:_lastLineView];
    [_nameOfPersonBackground addSubview:_nameOfPersonLabel];
    [self.view addSubview:_nameOfPersonBackground];
    [self.view bringSubviewToFront:_nameOfPersonBackground];
    
    _privateLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 80 - 40 - 11, 16, 22)];
    _privateLogoImageView.image = [UIImage imageNamed:@"privateIcon"];
    if (self.userState == ACCEPTED_PRIVATE_USER || self.userState == NOT_YET_ACCEPTED_PRIVATE_USER || self.userState == PRIVATE_PROFILE) {
        _privateLogoImageView.hidden = NO;
    }
    else _privateLogoImageView.hidden = YES;
    [_nameOfPersonBackground addSubview:_privateLogoImageView];
    [_nameOfPersonBackground bringSubviewToFront:_privateLogoImageView];
    
}

- (void) initializeTapButton {
    if ([[Profile user] isGoingOut] && ![self.user isEqualToUser:[Profile user]]) {
        UIButton *aroundTapButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 64, 60, 60)];
        [aroundTapButton addTarget:self action:@selector(tapPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:aroundTapButton];
        tapButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40 - 20, 64 + 20, 40, 40)];
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
    if (_isSeingImages) [self chooseImage];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[Profile user] setIsAttending:YES];
    [[Profile user] setIsGoingOut:YES];
    [[Profile user] setAttendingEventID:[self.user  attendingEventID]];
    UITabBarController *tabBarController = (UITabBarController *)self.parentViewController.parentViewController;
    tabBarController.selectedViewController
    = [tabBarController.viewControllers objectAtIndex:1];
    [Network postGoingToEventNumber:[[self.user  attendingEventID] intValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
}

- (void)initializeLeftProfileButton {
    _leftProfileButton = [[UIButton alloc] init];
    [_leftProfileButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _leftProfileButton.layer.borderWidth = 1;
    _leftProfileButton.layer.borderColor = RGBAlpha(0, 0, 0, 0.05f).CGColor;

    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        _leftProfileButton.frame = CGRectMake(0, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 100);
     
        UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _leftProfileButton.frame.size.width, 60)];
        followersLabel.textColor = [FontProperties getOrangeColor];
        followersLabel.font = [FontProperties getTitleFont];
        followersLabel.textAlignment = NSTextAlignmentCenter;
        followersLabel.text = [NSString stringWithFormat:@"%d\nFollowers", [(NSNumber*)[self.user objectForKey:@"num_followers"] intValue]];
        followersLabel.lineBreakMode = NSLineBreakByWordWrapping;
        followersLabel.numberOfLines = 0;
        [_leftProfileButton addSubview:followersLabel];
    }
    else  {
        _leftProfileButton.frame = CGRectMake(0, 64 + self.view.frame.size.width, self.view.frame.size.width/4, 100);
        if ([self.user isFavorite]) {
            _favoriteImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favoriteSelected"]];
        }
        else {
            _favoriteImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favorite"]];
        }
        _favoriteImageView.frame = CGRectMake(_leftProfileButton.frame.size.width/2 - 12, _leftProfileButton.frame.size.height/2 - 12 - 11, 24, 24);
        UILabel *favoriteLabel = [[UILabel alloc] initWithFrame:CGRectMake(_leftProfileButton.frame.size.width/2 - 30, _leftProfileButton.frame.size.height/2 + 12 - 3, 60, 15)];
        favoriteLabel.textAlignment = NSTextAlignmentCenter;
        favoriteLabel.text = @"Favorite";
        favoriteLabel.textColor = [FontProperties getOrangeColor];
        favoriteLabel.font = [FontProperties getSubtitleFont];
        [_leftProfileButton addSubview:favoriteLabel];
        [_leftProfileButton addSubview:_favoriteImageView];
    }
    [self.view addSubview:_leftProfileButton];
}

- (void)leftProfileButtonPressed {
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        [self followersButtonPressed];
    }
    else {
        if ([self.user isFavorite]) {
            [self.user setIsFavorite:NO];
            [self.user saveKeyAsynchronously:@"is_favorite"];
            _favoriteImageView.image = [UIImage imageNamed:@"favorite"];
        }
        else {
            [self.user setIsFavorite:YES];
            [self.user saveKeyAsynchronously:@"is_favorite"];
            _favoriteImageView.image = [UIImage imageNamed:@"favoriteSelected"];
        }
    }
}

- (void)initializeRightProfileButton {
    _rightProfileButton = [[UIButton alloc] init];
    [_rightProfileButton addTarget:self action:@selector(rightProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _rightProfileButton.layer.borderWidth = 1;
    _rightProfileButton.layer.borderColor = RGBAlpha(0, 0, 0, 0.05f).CGColor;
    
    if (self.userState == PRIVATE_PROFILE || self.userState == PUBLIC_PROFILE) {
        _rightProfileButton.frame = CGRectMake(self.view.frame.size.width/2, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 100);
        UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _rightProfileButton.frame.size.width, 60)];
        followingLabel.textColor = [FontProperties getOrangeColor];
        followingLabel.font = [FontProperties getTitleFont];
        followingLabel.textAlignment = NSTextAlignmentCenter;
        followingLabel.text = [NSString stringWithFormat:@"%d\nFollowing", [(NSNumber*)[self.user objectForKey:@"num_following"] intValue]];
        followingLabel.lineBreakMode = NSLineBreakByWordWrapping;
        followingLabel.numberOfLines = 0;
        [_rightProfileButton addSubview:followingLabel];
    }
    else {
        _rightProfileButton.frame = CGRectMake(3*self.view.frame.size.width/4, 64 + self.view.frame.size.width, self.view.frame.size.width/4, 100);
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
}

- (void)followersButtonPressed {
    [self.user setObject:@3 forKey:@"tabNumber"];
    self.peopleViewController = [[PeopleViewController alloc] initWithUser:self.user];
    [self.navigationController pushViewController:self.peopleViewController animated:YES];
}

- (void)followingButtonPressed {
    [self.user setObject:@4 forKey:@"tabNumber"];
    self.peopleViewController = [[PeopleViewController alloc] initWithUser:self.user];
    [self.navigationController pushViewController:self.peopleViewController animated:YES];
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

- (void) initializeBioLabel {
    _bioLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 483, self.view.frame.size.width, 1)];
    _bioLineView.backgroundColor = RGBAlpha(0, 0, 0, 0.05f);
    [self.view addSubview:_bioLineView];
    
    _bioPrefix = [[UILabel alloc] initWithFrame:CGRectMake(7, 64 + self.view.frame.size.width + 90 + 5 + 10, 40, 20)];
    _bioPrefix.text = @"Bio: ";
    _bioPrefix.textColor = [UIColor grayColor];
    _bioPrefix.font = [FontProperties getTitleFont];
    [_bioPrefix sizeToFit];
    [self.view addSubview:_bioPrefix];
    
    _bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 64 + self.view.frame.size.width + 90 + 5 + 10, self.view.frame.size.width - 14, 80)];
    _bioLabel.font = [FontProperties getSmallFont];
    _bioLabel.text = [NSString stringWithFormat:@"        %@" , [self.user bioString]];
    _bioLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _bioLabel.numberOfLines = 0;
    _bioLabel.textAlignment = NSTextAlignmentLeft;
    _bioLabel.hidden = YES;
    [self.view addSubview:_bioLabel];
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
    
    UIButton *unblockButton = [[UIButton alloc] initWithFrame:CGRectMake(25, 64 + self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
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

@end
