//
//  OnboardViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "OnboardViewController.h"
#import "Globals.h"

UIPageControl *pageControl;
UIScrollView *scrollView;
CGPoint startingPointScrollView;

NSMutableArray *arrayOfTitleLabel;
NSMutableArray *arrayOfImageView;

@implementation OnboardViewController


- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    arrayOfImageView = [NSMutableArray new];
    arrayOfTitleLabel = [NSMutableArray new];
    [self initializeScrollView];
    [self initializeTitle];
    [self initializeAnimatedGif];
    [self initializePageControl];
    [self initializeGetStartedButton];
}

- (void)initializeScrollView {
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 60)];
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width * 4, self.view.frame.size.height - 60);
    scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:scrollView];
}

- (void)initializeAnimatedGif {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"who" withExtension:@"gif"];
    FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height, self.view.frame.size.width - 100, 380)];
    imageView.animatedImage = image;
    [UIView animateWithDuration:0.7 animations:^{
        imageView.frame = CGRectMake(50, 130, self.view.frame.size.width - 100, 380);
    }];
    [scrollView addSubview:imageView];
    [arrayOfImageView addObject:imageView];

    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"where" withExtension:@"gif"];
    FLAnimatedImage *image2 = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url2]];
    FLAnimatedImageView *imageView2 = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 50, self.view.frame.size.height, self.view.frame.size.width - 100, 380)];
    imageView2.animatedImage = image2;
    [scrollView addSubview:imageView2];
    [arrayOfImageView addObject:imageView2];
    
    NSURL *url3 = [[NSBundle mainBundle] URLForResource:@"taps" withExtension:@"gif"];
    FLAnimatedImage *image3 = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url3]];
    FLAnimatedImageView *imageView3 = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 2 + 50, self.view.frame.size.height, self.view.frame.size.width - 100, 380)];
    imageView3.animatedImage = image3;
    [scrollView addSubview:imageView3];
    [arrayOfImageView addObject:imageView3];
}

- (void)initializeTitle {
    UIView *containerTitleLabel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    containerTitleLabel.clipsToBounds = YES;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 15, self.view.frame.size.width - 30, 100)];
    titleLabel.text = @"See who at your school\nis going out tonight";
    [self formatLabel:titleLabel];
    [scrollView addSubview:containerTitleLabel];
    [containerTitleLabel addSubview:titleLabel];
    [arrayOfTitleLabel addObject:titleLabel];
    [UIView animateWithDuration:0.7 animations:^{
        titleLabel.frame = CGRectMake(15, 15, self.view.frame.size.width - 30, 100);
    }];
    
    UIView *containerTitleLabel2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, 100)];
    containerTitleLabel2.clipsToBounds = YES;
    UILabel *titleLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 20, self.view.frame.size.width - 30, 100)];
    titleLabel2.text = @"Let your friends know\nwhere you're headed";
    [self formatLabel:titleLabel2];
    [scrollView addSubview:containerTitleLabel2];
    [containerTitleLabel2 addSubview:titleLabel2];
    [arrayOfTitleLabel addObject:titleLabel2];
    
    UIView *containerTitleLabel3 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 2, 0, self.view.frame.size.width, 100)];
    containerTitleLabel3.clipsToBounds = YES;
    UILabel *titleLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 20, self.view.frame.size.width - 30, 100)];
    titleLabel3.text = @"Rally your crew";
    [self formatLabel:titleLabel3];
    [scrollView addSubview:containerTitleLabel3];
    [containerTitleLabel3 addSubview:titleLabel3];
    [arrayOfTitleLabel addObject:titleLabel3];
}

- (void)initializeGetStartedButton {
    UILabel *titleLabel4 = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 15, 20, self.view.frame.size.width - 30, 100)];
    titleLabel4.text = @"NO ADMNISTRATION";
    [self formatLabel:titleLabel4];
    titleLabel4.textColor = [FontProperties getOrangeColor];
    titleLabel4.font = [FontProperties mediumFont:21.0f];
    [scrollView addSubview:titleLabel4];
    
    UILabel *titleLabel5 = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 15, 80, self.view.frame.size.width - 30, 100)];
    titleLabel5.text = @"NO PARENTS";
    [self formatLabel:titleLabel5];
    titleLabel5.textColor = [FontProperties getOrangeColor];
    titleLabel5.font = [FontProperties mediumFont:21.0f];
    [scrollView addSubview:titleLabel5];
    
    UILabel *titleLabel6 = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 15, 140, self.view.frame.size.width - 30, 100)];
    titleLabel6.text = @"NO B.S.";
    [self formatLabel:titleLabel6];
    titleLabel6.textColor = [FontProperties getOrangeColor];
    titleLabel6.font = [FontProperties mediumFont:21.0f];
    [scrollView addSubview:titleLabel6];
    
    UIButton *getStartedButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 40, self.view.frame.size.height - 150, self.view.frame.size.width - 80, 60)];
    [getStartedButton setTitle:@"GET STARTED" forState:UIControlStateNormal];
    [getStartedButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    getStartedButton.titleLabel.font = [FontProperties getBigButtonFont];
    getStartedButton.layer.cornerRadius = 10.0f;
    getStartedButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    getStartedButton.layer.borderWidth = 1.0f;
    [getStartedButton addTarget:self action:@selector(getStartedPressed)  forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:getStartedButton];
}

- (void)getStartedPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)formatLabel:(UILabel *)label {
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [FontProperties lightFont:21.0f];
    label.textColor = RGB(112, 112, 112);
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
}

- (void)initializePageControl {
    pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height - 50, self.view.frame.size.width - 100, 40)];
    pageControl.enabled = NO;
    pageControl.currentPage = 0;
    pageControl.numberOfPages = 4;
    pageControl.pageIndicatorTintColor = RGB(233, 233, 233);
    pageControl.currentPageIndicatorTintColor =  RGB(163, 163, 163);
    [self.view addSubview:pageControl];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    pageControl.currentPage = page;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    startingPointScrollView = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        if (scrollView.contentOffset.x < startingPointScrollView.x) {
            [self stoppedScrollingToLeft:YES];
        } else if (scrollView.contentOffset.x >= startingPointScrollView.x) {
            [self stoppedScrollingToLeft:NO];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView.contentOffset.x < startingPointScrollView.x) {
        [self stoppedScrollingToLeft:YES];
    } else if (scrollView.contentOffset.x >= startingPointScrollView.x) {
        [self stoppedScrollingToLeft:NO];
    }
}

- (void)stoppedScrollingToLeft:(BOOL)leftBoolean
{
    CGFloat pageWidth = scrollView.frame.size.width; // you need to have a **iVar** with getter for scrollView
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
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
    [self changeToPage:page];
}

- (void)changeToPage:(int)page {
    [scrollView setContentOffset:CGPointMake(self.view.frame.size.width * page, 0.0f) animated:YES];
    if (page >= 1 && page < 3) {
        UIImageView *imageView = [arrayOfImageView objectAtIndex:page];
        [UIView animateWithDuration:0.7 animations:^{
            imageView.frame = CGRectMake(self.view.frame.size.width * page + 50, 130, self.view.frame.size.width - 100, 380);
        }];
        UILabel *titleLabel = [arrayOfTitleLabel objectAtIndex:page];
        [UIView animateWithDuration:0.7 animations:^{
            titleLabel.frame = CGRectMake(15, 20, self.view.frame.size.width - 30, 100);
        }];
    }
}



@end
