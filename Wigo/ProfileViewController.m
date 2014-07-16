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

#import "SDWebImage/UIImageView+WebCache.h"



@interface ProfileViewController ()

@property BOOL didImagesLoad;

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
@property UIActivityIndicatorView *spinner;

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
        if (self.isMyProfile) {
            self.user = [Profile user];
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
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    _didImagesLoad = NO;
    _currentPage = 0;
    _isSeingImages = NO;
    _profileImagesArray = [[NSMutableArray alloc] initWithCapacity:0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProfile) name:@"updateProfile" object:nil];
    
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    [self initializeBioLabel];

    if (!self.isMyProfile) {
        [self initializeFollowingAndFollowers];
    }
    
    [self initializeLeftProfileButton];
    [self initializeRightProfileButton];

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!_didImagesLoad) {
        _spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(135,140,150,150)];
        _spinner.transform = CGAffineTransformMakeScale(2, 2);
        _spinner.center = self.view.center;
        _spinner.color = [FontProperties getOrangeColor];
        [_spinner startAnimating];
        [self.view addSubview:_spinner];
        [self.user loadImagesWithCallback:^(
                                            NSArray *imagesArray
                                            ) {
            [_spinner stopAnimating];
            [self initializeProfileImage];
            [self initializeNameOfPerson];
            _didImagesLoad = YES;
        }];
    }
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
    _followingButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, 64 + self.view.frame.size.width + 50, self.view.frame.size.width/2, 50)];
    [_followingButton addTarget:self action:@selector(followingButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _followingButton.frame.size.height/2 - 12, _followingButton.frame.size.width, 24)];
    followingLabel.textColor = [FontProperties getOrangeColor];
    followingLabel.textAlignment = NSTextAlignmentCenter;
    followingLabel.text = [NSString stringWithFormat:@"FOLLOWING (%d)", [(NSNumber*)[self.user objectForKey:@"num_following"] intValue]];
    followingLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:18.0f];
    followingLabel.lineBreakMode = NSLineBreakByWordWrapping;
    followingLabel.numberOfLines = 0;
    [_followingButton addSubview:followingLabel];
    [self.view addSubview:_followingButton];
    
    _followersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/4, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 50)];
    [_followersButton addTarget:self action:@selector(followersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _followersButton.frame.size.height/2 - 12, _followingButton.frame.size.width, 24)];
    followersLabel.textColor = [FontProperties getOrangeColor];
    followersLabel.textAlignment = NSTextAlignmentCenter;
    followersLabel.text = [NSString stringWithFormat:@"FOLLOWERS (%d)", [(NSNumber*)[self.user objectForKey:@"num_followers"] intValue]];
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
    // UIScrollView
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
    
    UIView *firstLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _scrollView.frame.origin.y, _scrollView.frame.size.width, 1)];
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
        [profileImgView setImageWithURL:[NSURL URLWithString:[[self.user imagesURL] objectAtIndex:i]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self addBlurredImage:image toImageView:profileImgView];
                profileImgView.hidden = NO;
            });
        }];
        
        [self addParallaxEffectToView:profileImgView];
        [_scrollView addSubview:profileImgView];
        [_profileImagesArray addObject:profileImgView];
    }
    [_scrollView setContentSize:CGSizeMake((self.view.frame.size.width + 10) * [[self.user imagesURL] count], 320)];
    _bioLabel.text = [NSString stringWithFormat:@"       %@" , [self.user bioString]];
    [_bioLabel sizeToFit];
}

- (void) addBlurredImage:(UIImage *)image toImageView:(UIImageView *)imageView {
    UIImage *imageRightSize = [UIImageCrop image:image scaledToSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width)];
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
    [_followButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchUpInside];
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
        if (self.isMyProfile) {
            _pageControl.center = CGPointMake(73, 25);
        }
        else {
            _pageControl.center = CGPointMake(100, 25);
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
            _bioLabel.textColor = [UIColor blackColor];
            _bioLineView.hidden = NO;
            _followButton.hidden = NO;
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
    _nameOfPersonLabel.text = [self.user fullName];
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
    
//    if ([self.user private]) {
//        UIImageView *privateLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 80 - 40 - 11, 16, 22)];
//        privateLogoImageView.image = [UIImage imageNamed:@"privateIcon"];
//        [_nameOfPersonLabel addSubview:privateLogoImageView];
//        [_nameOfPersonLabel bringSubviewToFront:privateLogoImageView];
//    }

}

- (void)initializeLeftProfileButton {
    if (self.isMyProfile) {
        _leftProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64 + self.view.frame.size.width, self.view.frame.size.width/2, 100)];
        [_leftProfileButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _leftProfileButton.frame.size.width, 60)];
        followersLabel.textColor = [FontProperties getOrangeColor];
        followersLabel.textAlignment = NSTextAlignmentCenter;
        followersLabel.text = [NSString stringWithFormat:@"%d\nFOLLOWERS", [(NSNumber*)[self.user objectForKey:@"num_followers"] intValue]];
        followersLabel.lineBreakMode = NSLineBreakByWordWrapping;
        followersLabel.numberOfLines = 0;
        [_leftProfileButton addSubview:followersLabel];
    }
    else {
        _leftProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64 + self.view.frame.size.width, self.view.frame.size.width/4, 100)];
        [_leftProfileButton addTarget:self action:@selector(leftProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
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
        [self followersButtonPressed];
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
        [_rightProfileButton addTarget:self action:@selector(rightProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _rightProfileButton.layer.borderWidth = 1;
        _rightProfileButton.layer.borderColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.05f].CGColor;

        UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _rightProfileButton.frame.size.width, 60)];
        followingLabel.textColor = [FontProperties getOrangeColor];
        followingLabel.textAlignment = NSTextAlignmentCenter;
        followingLabel.text = [NSString stringWithFormat:@"%d\nFOLLOWING", [(NSNumber*)[self.user objectForKey:@"num_following"] intValue]];
        followingLabel.lineBreakMode = NSLineBreakByWordWrapping;
        followingLabel.numberOfLines = 0;
        [_rightProfileButton addSubview:followingLabel];
    }
    else {
        _rightProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(3*self.view.frame.size.width/4, 64 + self.view.frame.size.width, self.view.frame.size.width/4, 100)];
        [_rightProfileButton addTarget:self action:@selector(rightProfileButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _rightProfileButton.layer.borderWidth = 1;
        _rightProfileButton.layer.borderColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.05f].CGColor;

        UIImageView *chatImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatImage"]];
        chatImageView.frame = CGRectMake(_rightProfileButton.frame.size.width/2 - 12, _rightProfileButton.frame.size.height/2 - 12, 24, 24);
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
    if (self.isMyProfile) {
        [self followingButtonPressed];
    }
    else {
        self.conversationViewController = [[ConversationViewController alloc] initWithUser:self.user];
        [self.navigationController pushViewController:self.conversationViewController animated:YES];
    }
}

- (void) initializeBioLabel {
    _bioLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 483, self.view.frame.size.width, 1)];
    _bioLineView.backgroundColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.05f];
    [self.view addSubview:_bioLineView];
    
    UILabel *bioPrefix = [[UILabel alloc] initWithFrame:CGRectMake(5, 64 + self.view.frame.size.width + 90 + 5 + 10, 40, 20)];
    bioPrefix.text = @"Bio: ";
    bioPrefix.textColor = [UIColor grayColor];
    bioPrefix.font = [FontProperties getTitleFont];
    [bioPrefix sizeToFit];
    [self.view addSubview:bioPrefix];
    
    _bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 64 + self.view.frame.size.width + 90 + 5 + 10, self.view.frame.size.width, 80)];
    _bioLabel.font = [FontProperties getSmallFont];
    _bioLabel.text = [NSString stringWithFormat:@"      %@" , [self.user bioString]];
    _bioLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _bioLabel.numberOfLines = 0;
    [_bioLabel sizeToFit];
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
    [_scrollView setContentOffset:CGPointMake((self.view.frame.size.width + 10) * page, 0.0f) animated:YES];
}

- (void)addParallaxEffectToView:(UIView *)view {
    // Set vertical effect
    UIInterpolatingMotionEffect *verticalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.y"
     type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-20);
    verticalMotionEffect.maximumRelativeValue = @(20);
    
    // Set horizontal effect
    UIInterpolatingMotionEffect *horizontalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.x"
     type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-20);
    horizontalMotionEffect.maximumRelativeValue = @(20);
    
    // Create group to combine both
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    
    // Add both effects to your view
    [view addMotionEffect:group];
}



@end
