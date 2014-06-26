//
//  ProfileViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ProfileViewController.h"
#import "FontProperties.h"
#import <QuartzCore/QuartzCore.h>
#import "UIButtonAligned.h"
#import "UIPageControlAligned.h"
#import "Profile.h"
#import "UIImageCrop.h"


@interface ProfileViewController ()

@property BOOL isPersonFavorite;
@property int currentPage;
@property UIPageControl *pageControl;
@property UIScrollView *scrollView;
@property UIButton *followButton;
@property BOOL isSeingImages;
@property UILabel *nameOfPersonLabel;

// bio
@property UILabel *bioLabel;
@property UIView *bioLineView;

//favorite
@property UIButton *leftProfileButton;
@property UIImageView *favoriteImageView;
@property UIButton *rightProfileButton;
@property UITapGestureRecognizer *tapScrollView;

//UIScrollView
@property CGPoint pointNow;
@property NSMutableArray *profileImagesArray;

@property UIButton *followingButton;
@property UIButton *followersButton;

@property UIView *lastLineView;

@end

@implementation ProfileViewController


- (id)initWithUser:(User *)user {
    self = [super init];
    if (self) {
        self.user = user;
        self.isMyProfile = NO;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)initWithProfile:(BOOL)isMyProfile
{
    self = [super init];
    if (self) {
        self.isMyProfile = isMyProfile;
        self.view.backgroundColor = [UIColor whiteColor];
        if (self.isMyProfile) {
            self.user = [Profile user];
        }
    }
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    _pageControl.hidden = YES;
}


- (void)viewDidAppear:(BOOL)animated {
    _pageControl.hidden = NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _currentPage = 0;
    _isSeingImages = NO;
    _profileImagesArray = [[NSMutableArray alloc] initWithCapacity:0];
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    
    if (!self.isMyProfile) {
        [self initializeFollowingAndFollowers];
    }
    
    [self initializeProfileImage];
    [self initializeNameOfPerson];
    [self initializeLeftProfileButton];
    [self initializeRightProfileButton];
    [self initializeBioLabel];

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
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initializeRightBarButton {
    UITabBarController *tabController = (UITabBarController *)self.parentViewController;
    tabController.navigationItem.rightBarButtonItem = nil;
    
    if (self.isMyProfile) {
        UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@1];
        [barBt setTitle:@"Edit" forState:UIControlStateNormal];
        [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
        barBt.titleLabel.font = [FontProperties getSubtitleFont];
        [barBt addTarget:self action: @selector(editPressed) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
        [barItem setCustomView:barBt];
        self.navigationItem.rightBarButtonItem = barItem;
    }
    else {
//        UIBarButtonItem *rightBarButtonFollow = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plusPerson"] style:UIBarButtonItemStylePlain target:self action:@selector(followPressed)];
//        rightBarButtonFollow.tintColor = [FontProperties getOrangeColor];
//        self.navigationItem.rightBarButtonItem = rightBarButtonFollow;
    }
}


- (void) initializeFollowingAndFollowers {
    _followingButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 50)];
    [_followingButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchDown];
    UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _followingButton.frame.size.height/2 - 12, _followingButton.frame.size.width, 24)];
    followingLabel.textColor = [FontProperties getOrangeColor];
    followingLabel.textAlignment = NSTextAlignmentCenter;
    followingLabel.text = @"FOLLOWING (67)";
    followingLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:18.0f];
    followingLabel.lineBreakMode = NSLineBreakByWordWrapping;
    followingLabel.numberOfLines = 0;
    [_followingButton addSubview:followingLabel];
    [self.view addSubview:_followingButton];
    
    _followersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, 64 + self.view.frame.size.width + 50, self.view.frame.size.width/2, 50)];
    [_followersButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchDown];
    UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _followersButton.frame.size.height/2 - 12, _followingButton.frame.size.width, 24)];
    followersLabel.textColor = [FontProperties getOrangeColor];
    followersLabel.textAlignment = NSTextAlignmentCenter;
    followersLabel.text = @"FOLLOWERS (45)";
    followersLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:18.0f];

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



- (void)followPressed {
    _followButton.hidden = YES;
    _leftProfileButton.hidden = NO;
    _rightProfileButton.hidden = NO;
    UIBarButtonItem *unfollowButton = [[UIBarButtonItem alloc] initWithTitle:@"UNFOLLOW" style:UIBarButtonItemStylePlain target:self action:@selector(unfollowPressed)];
    unfollowButton.tintColor = [FontProperties getOrangeColor];
    self.navigationItem.rightBarButtonItem = unfollowButton;
}

- (void)unfollowPressed {
    _followButton.hidden = NO;
    _leftProfileButton.hidden = YES;
    _rightProfileButton.hidden = YES;
    [self initializeRightBarButton];
}

- (void)initializeProfileImage {
    if (self.isMyProfile) {
        self.user = [Profile user];
    }
    int heightOfProfileImage = self.view.frame.size.width;
    // UIScrollView
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, heightOfProfileImage)];
    [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width * [[self.user images] count], 320)];
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
    
    UIView *firstLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _scrollView.frame.origin.y, _scrollView.frame.size.width, 1)];
    firstLineView.backgroundColor = [FontProperties getOrangeColor];
    [self.view addSubview:firstLineView];

    _pageControl = [[UIPageControl alloc] init];
    _pageControl.enabled = NO;
    _pageControl.numberOfPages = [[self.user images] count];
    _pageControl.currentPage = 0;
    _pageControl.currentPageIndicatorTintColor = [FontProperties getOrangeColor];
    _pageControl.pageIndicatorTintColor = [UIColor grayColor];
    // HACK
    _pageControl.center = CGPointMake(90, 25);
    
    UIView *pageControlView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 44)];
    [pageControlView addSubview: _pageControl];
    self.navigationItem.titleView = pageControlView;
    
    for (int i = 0; i < [[self.user images] count]; i++) {
        UIImage *photoImage = [[self.user images] objectAtIndex:i];
        UIImage *croppedImage = [UIImageCrop imageByScalingAndCroppingForSize:CGSizeMake(heightOfProfileImage, heightOfProfileImage) andImage:photoImage];
        UIImageView *profileImgView = [[UIImageView alloc] initWithImage:croppedImage];
        profileImgView.frame = CGRectMake(self.view.frame.size.width * i, 0, self.view.frame.size.width, heightOfProfileImage);
        [_scrollView addSubview:profileImgView];
        [self addBlurredImage:photoImage toImageView:profileImgView];
        [_profileImagesArray addObject:profileImgView];
    }
}

- (void) addBlurredImage:(UIImage *)image toImageView:(UIImageView *)imageView {
    UIImage *imageRightSize = [UIImageCrop imageWithImage:image scaledToSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width)];
    // Add Blurred Image
    UIImage *croppedImage = [UIImageCrop croppingImage:imageRightSize toRect:CGRectMake(0, imageView.frame.size.height - 80, self.view.frame.size.width, 80)];
    UIImageView *croppedImageView = [[UIImageView alloc] initWithImage:croppedImage];
    croppedImageView.frame = CGRectMake(0, imageView.frame.size.height - 80, imageView.frame.size.width, 80);
    croppedImageView = [UIImageCrop blurImageView:croppedImageView];
    [imageView addSubview:croppedImageView];
}

- (void)deleteBlurredImageFromImageView:(UIImageView *)imageView {
    for (UIView *subview in imageView.subviews) {
        [subview removeFromSuperview];
    }
}

- (void) initializeFollowButton {
    _followButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 64 + self.view.frame.size.width + 20, self.view.frame.size.width - 20, 50)];
    [_followButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchDown];
    _followButton.layer.cornerRadius = 15;
    _followButton.layer.borderWidth = 1;
    _followButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    
    UILabel *followLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 15, 135, 20)];
    followLabel.text = @"Follow Alice";
    followLabel.textColor = [FontProperties getOrangeColor];
    followLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:24.0f];
    [_followButton addSubview:followLabel];
    UIImageView *plusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plusPerson"]];
    plusImageView.frame = CGRectMake(202, _followButton.frame.size.height/2 - 11, 28, 20);
    plusImageView.tintColor = [FontProperties getOrangeColor];
    [_followButton addSubview:plusImageView];
    
    [self.view addSubview:_followButton];
}


- (void)chooseImage {
    if (!_isSeingImages) {
        _tapScrollView.enabled = NO;
        _isSeingImages = YES;
        _lastLineView.hidden = NO;
        _pageControl.center = CGPointMake(73, 25);

        self.navigationController.navigationBar.barTintColor = RGB(23, 23, 23);
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"closeButton"] style:UIBarButtonItemStylePlain target:self action:@selector(chooseImage)];
        [closeButton setTintColor:[UIColor whiteColor]];
        self.navigationItem.leftBarButtonItem = closeButton;
        self.navigationItem.rightBarButtonItem = nil;
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                            animations:^{
                                _nameOfPersonLabel.transform =  CGAffineTransformMakeTranslation(0, _nameOfPersonLabel.frame.size.height);
                                _bioLabel.textColor = [UIColor whiteColor];
                                self.view.backgroundColor = RGB(23, 23, 23);
                                _nameOfPersonLabel.backgroundColor = RGB(23, 23, 23);
                                
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
        _tapScrollView.enabled = YES;
        _isSeingImages = NO;
        _lastLineView.hidden = YES;
        [UIView animateWithDuration:0.2
                         animations:^{
            _nameOfPersonLabel.transform =  CGAffineTransformMakeTranslation(0, 0);
        } completion:^(BOOL finished) {
            _nameOfPersonLabel.backgroundColor = RGBAlpha(23, 23, 23, 0.7f);
            self.view.backgroundColor = [UIColor whiteColor];
            _bioLineView.hidden = NO;
            _followButton.hidden = NO;
            _bioLabel.textColor = [UIColor blackColor];
            _leftProfileButton.hidden = NO;
            _rightProfileButton.hidden = NO;
            _followingButton.hidden = NO;
            _followersButton.hidden = NO;
            self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
            [self initializeLeftBarButton];
            [self initializeRightBarButton];
            for (UIImageView *profileImageView in _profileImagesArray) {
                [self addBlurredImage:profileImageView.image toImageView:profileImageView];
            }

            _pageControl.center = CGPointMake(90, 25);

            
        }];
    }
}

- (void)initializeNameOfPerson {
    _nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64 + self.view.frame.size.width - 80, self.view.frame.size.width, 80)];
    if (self.user) {
        _nameOfPersonLabel.text = [NSString stringWithFormat: @"%@ %@", [self.user objectForKey:@"first_name"], [self.user objectForKey:@"last_name"]];
    }
    else {
        _nameOfPersonLabel.text = @"Alice Banger";
    }
    _nameOfPersonLabel.textColor = [UIColor whiteColor];
    _nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
    _nameOfPersonLabel.backgroundColor = [UIColor colorWithRed:23/255.0f green:23/255.0f blue:23/255.0f alpha:0.7f];
    _nameOfPersonLabel.font = [FontProperties getSubHeaderFont];
    
    _lastLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _nameOfPersonLabel.frame.size.width, 1)];
    _lastLineView.backgroundColor = [FontProperties getOrangeColor];
    _lastLineView.hidden = YES;
    [_nameOfPersonLabel addSubview:_lastLineView];
    
    [self.view addSubview:_nameOfPersonLabel];
    [self.view bringSubviewToFront:_nameOfPersonLabel];
}

- (void)initializeLeftProfileButton {
    if (self.isMyProfile) {
        _leftProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 100)];
        [_leftProfileButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchDown];
        UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _leftProfileButton.frame.size.width, 60)];
        followersLabel.textColor = [FontProperties getOrangeColor];
        followersLabel.textAlignment = NSTextAlignmentCenter;
        followersLabel.text = @"FOLLOWERS\n(1990)";
        followersLabel.lineBreakMode = NSLineBreakByWordWrapping;
        followersLabel.numberOfLines = 0;
        [_leftProfileButton addSubview:followersLabel];
    }
    else {
        _leftProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64 + self.view.frame.size.width, self.view.frame.size.width/4, 100)];
        [_leftProfileButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchDown];
        
        _favoriteImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favorite"]];
        _favoriteImageView.frame = CGRectMake(_leftProfileButton.frame.size.width/2 - 12, _leftProfileButton.frame.size.height/2 - 12, 24, 24);
        _leftProfileButton.layer.borderWidth = 1;
        _leftProfileButton.layer.borderColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.05f].CGColor;
        [_leftProfileButton addSubview:_favoriteImageView];
    }
    [self.view addSubview:_leftProfileButton];
}

- (void)leftProfileButtonPressed {
    if (self.isMyProfile) {
        self.peopleViewController = [[PeopleViewController alloc] init];
        [self.navigationController pushViewController:self.peopleViewController animated:YES];
    }
    else {
        if (_isPersonFavorite) {
            _favoriteImageView.image = [UIImage imageNamed:@"favorite"];
        }
        else {
            _favoriteImageView.image = [UIImage imageNamed:@"favoriteSelected"];
        }
        _isPersonFavorite = !_isPersonFavorite;
    }
}

- (void)initializeRightProfileButton {
    if (self.isMyProfile) {
        _rightProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 100)];
        [_rightProfileButton addTarget:self action:@selector(rightProfileButtonPressed) forControlEvents:UIControlEventTouchDown];
        _rightProfileButton.layer.borderWidth = 1;
        _rightProfileButton.layer.borderColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.05f].CGColor;

        UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _rightProfileButton.frame.size.width, 60)];
        followingLabel.textColor = [FontProperties getOrangeColor];
        followingLabel.textAlignment = NSTextAlignmentCenter;
        followingLabel.text = @"FOLLOWING\n(50)";
        followingLabel.lineBreakMode = NSLineBreakByWordWrapping;
        followingLabel.numberOfLines = 0;
        [_rightProfileButton addSubview:followingLabel];
    }
    else {
        _rightProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(3*self.view.frame.size.width/4, 64 + self.view.frame.size.width, self.view.frame.size.width/4, 100)];
        [_rightProfileButton addTarget:self action:@selector(rightProfileButtonPressed) forControlEvents:UIControlEventTouchDown];
        _rightProfileButton.layer.borderWidth = 1;
        _rightProfileButton.layer.borderColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.05f].CGColor;

        UIImageView *chatImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatImage"]];
        chatImageView.frame = CGRectMake(_rightProfileButton.frame.size.width/2 - 12, _rightProfileButton.frame.size.height/2 - 12, 24, 24);
        [_rightProfileButton addSubview:chatImageView];
    }
    [self.view addSubview:_rightProfileButton];
}

- (void)rightProfileButtonPressed {
    if (self.isMyProfile) {
        self.peopleViewController = [[PeopleViewController alloc] init];
        [self.navigationController pushViewController:self.peopleViewController animated:YES];
    }
    else {
        self.conversationViewController = [[ConversationViewController alloc] init];
        [self.navigationController pushViewController:self.conversationViewController animated:YES];
    }
}

- (void) initializeBioLabel {
    _bioLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 483, self.view.frame.size.width, 1)];
    _bioLineView.backgroundColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.05f];
    [self.view addSubview:_bioLineView];
    _bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 64 + self.view.frame.size.width + 90, self.view.frame.size.width - 26, 80)];
    _bioLabel.text = [self.user bioString];
    _bioLabel.textColor = [UIColor blackColor];
    _bioLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _bioLabel.numberOfLines = 0;
    _bioLabel.font = [FontProperties getBioFont];
    [self.view addSubview:_bioLabel];
}

#pragma mark UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width; // you need to have a **iVar** with getter for scrollView
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    _pageControl.currentPage = page; // you need to have a **iVar** with getter for pageControl
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
    [_scrollView setContentOffset:CGPointMake(self.view.frame.size.width * page, 0.0f) animated:YES];
}



@end
