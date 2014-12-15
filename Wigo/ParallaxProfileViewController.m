//
//  ParallaxProfileViewController.m
//  Wigo
//
//  Created by Alex Grinman on 12/12/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "ParallaxProfileViewController.h"

@interface ParallaxProfileViewController()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *profileImagesScrollView;
@property UITapGestureRecognizer *profileTapRecognizer;
@property UIPageControl *pageControl;

@property NSMutableArray *profileImagesArray;

@end
@implementation ParallaxProfileViewController

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

- (void) viewDidLoad {
    _profileImagesArray = [[NSMutableArray alloc] initWithCapacity:0];

    [self initializeProfileImageScrollView];
    [self updateProfile];
    
    [self addHeaderOverlayView: self.profileImagesScrollView];
}

#pragma mark - Profile Image ScrollView

- (void)initializeProfileImageScrollView {
    if (self.userState == PUBLIC_PROFILE || self.userState == PRIVATE_PROFILE) {
        self.user = [Profile user];
    }   
    
    _profileImagesScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
    [_profileImagesScrollView setShowsHorizontalScrollIndicator:NO];
    _profileImagesScrollView.layer.borderWidth = 1;
    _profileImagesScrollView.backgroundColor = RGB(23,23,23);
    _profileTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseImage)];
    _profileTapRecognizer.cancelsTouchesInView = NO;
    [_profileImagesScrollView addGestureRecognizer: _profileTapRecognizer];
    _profileImagesScrollView.delegate = self;
    
    // DISPLAY CONTENT PROPERLY (Scroll View)
    // IOS 6 and less
    _profileImagesScrollView.contentOffset = CGPointZero;
    _profileImagesScrollView.contentInset = UIEdgeInsetsZero;
    // IOS 7+
    self.automaticallyAdjustsScrollViewInsets = NO;
    
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
    [_profileImagesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
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
        [_profileImagesScrollView addSubview:spinner];
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
        [_profileImagesScrollView addSubview:profileImgView];
        [_profileImagesArray addObject:profileImgView];
    }
    [_profileImagesScrollView setContentSize:CGSizeMake((self.view.frame.size.width + 10) * [[self.user imagesURL] count] - 10, [[UIScreen mainScreen] bounds].size.width)];
}
@end
