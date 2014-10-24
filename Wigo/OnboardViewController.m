//
//  OnboardViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "OnboardViewController.h"
#import "Globals.h"
#import "UIImageViewShake.h"

UIPageControl *pageControl;
UIScrollView *scrollView;
CGPoint startingPointScrollView;

NSMutableArray *arrayOfTitleLabel;
NSMutableArray *arrayOfPhoneImageView;
NSMutableArray *arrayOfLabels;
UIButton *getStartedButton;
BOOL runningAnimations;
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
    arrayOfTitleLabel = [NSMutableArray new];
    arrayOfPhoneImageView = [NSMutableArray new];
    arrayOfLabels = [NSMutableArray new];
    runningAnimations = NO;
    [self initializeScrollView];
    [self initializeTitle];
    [self initializeAnimatedGif];
    [self initializePageControl];
    [self initializeGetStartedButton];
}

- (void)initializeScrollView {
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50)];
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width * 4, self.view.frame.size.height - 50);
    scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:scrollView];
}

- (void)initializeAnimatedGif {
    UIImageView *phoneImageview = [[UIImageView alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height + 40, self.view.frame.size.width - 100, 400)];
    phoneImageview.image = [UIImage imageNamed:@"iphone6"];
    [scrollView addSubview:phoneImageview];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"who" withExtension:@"gif"];
    FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(15, 50, self.view.frame.size.width - 130, 320)];
    imageView.animatedImage = image;
    [phoneImageview addSubview:imageView];
    [UIView animateWithDuration:0.7 animations:^{
        phoneImageview.frame = CGRectMake(50, 100, self.view.frame.size.width - 100, 420);
    }];
    [arrayOfPhoneImageView addObject:phoneImageview];

    UIImageView *phoneImageview2 = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 50, self.view.frame.size.height + 40, self.view.frame.size.width - 100, 400)];
    phoneImageview2.image = [UIImage imageNamed:@"iphone6"];
    [scrollView addSubview:phoneImageview2];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"where" withExtension:@"gif"];
    FLAnimatedImage *image2 = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url2]];
    FLAnimatedImageView *imageView2 = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(15, 50, self.view.frame.size.width - 130, 320)];
    imageView2.animatedImage = image2;
    [phoneImageview2 addSubview:imageView2];
    [arrayOfPhoneImageView addObject:phoneImageview2];
    
    UIImageView *phoneImageview3 = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 2 + 50, self.view.frame.size.height + 40, self.view.frame.size.width - 100, 400)];
    phoneImageview3.image = [UIImage imageNamed:@"iphone6"];
    [scrollView addSubview:phoneImageview3];
    NSURL *url3 = [[NSBundle mainBundle] URLForResource:@"tapping" withExtension:@"gif"];
    FLAnimatedImage *image3 = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url3]];
    FLAnimatedImageView *imageView3 = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(15, 50, self.view.frame.size.width - 130, 320)];
    imageView3.animatedImage = image3;
    [phoneImageview3 addSubview:imageView3];
    [arrayOfPhoneImageView addObject:phoneImageview3];
}

- (void)initializeTitle {
    UIView *containerTitleLabel = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 80)];
    containerTitleLabel.clipsToBounds = YES;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 0, self.view.frame.size.width - 30, 80)];
    titleLabel.text = @"See who at your school\nis going out tonight";
    [self formatLabel:titleLabel];
    [scrollView addSubview:containerTitleLabel];
    [containerTitleLabel addSubview:titleLabel];
    [arrayOfTitleLabel addObject:titleLabel];
    [UIView animateWithDuration:0.7 animations:^{
        titleLabel.frame = CGRectMake(15, 0, self.view.frame.size.width - 30, 80);
    }];
    
    UIView *containerTitleLabel2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 20, self.view.frame.size.width, 80)];
    containerTitleLabel2.clipsToBounds = YES;
    UILabel *titleLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 0, self.view.frame.size.width - 30, 80)];
    titleLabel2.text = @"Let your friends know\nwhere you're headed";
    [self formatLabel:titleLabel2];
    [scrollView addSubview:containerTitleLabel2];
    [containerTitleLabel2 addSubview:titleLabel2];
    [arrayOfTitleLabel addObject:titleLabel2];
    
    UIView *containerTitleLabel3 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 2, 20, self.view.frame.size.width, 80)];
    containerTitleLabel3.clipsToBounds = YES;
    UILabel *titleLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 0, self.view.frame.size.width - 30, 80)];
    titleLabel3.text = @"Rally your crew";
    [self formatLabel:titleLabel3];
    [scrollView addSubview:containerTitleLabel3];
    [containerTitleLabel3 addSubview:titleLabel3];
    [arrayOfTitleLabel addObject:titleLabel3];
    
    UIView *containerTitleLabel4 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3, 20, self.view.frame.size.width, 80)];
    containerTitleLabel4.clipsToBounds = YES;
    UILabel *titleLabel4 = [[UILabel alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 0, self.view.frame.size.width - 30, 80)];
    titleLabel4.text = @"And of course...";
    [self formatLabel:titleLabel4];
    [scrollView addSubview:containerTitleLabel4];
    [containerTitleLabel4 addSubview:titleLabel4];
    [arrayOfTitleLabel addObject:titleLabel4];

}

- (void)initializeGetStartedButton {
    UILabel *titleLabel4 = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 15, 130, self.view.frame.size.width - 30, 100)];
    titleLabel4.text = @"NO SKETCHY RANDOS";
    [self formatLabel:titleLabel4];
    titleLabel4.textColor = [FontProperties getOrangeColor];
    titleLabel4.font = [FontProperties mediumFont:21.0f];
    titleLabel4.hidden = YES;
    [scrollView addSubview:titleLabel4];
    [arrayOfLabels addObject:titleLabel4];
    
    UILabel *titleLabel5 = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 15, 200, self.view.frame.size.width - 30, 100)];
    titleLabel5.text = @"NO ADMINISTRATION";
    [self formatLabel:titleLabel5];
    titleLabel5.textColor = [FontProperties getOrangeColor];
    titleLabel5.font = [FontProperties mediumFont:21.0f];
    titleLabel5.hidden = YES;
    [scrollView addSubview:titleLabel5];
    [arrayOfLabels addObject:titleLabel5];
    
    UILabel *titleLabel6 = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 15, 270, self.view.frame.size.width - 30, 100)];
    titleLabel6.text = @"NO PARENTS";
    [self formatLabel:titleLabel6];
    titleLabel6.textColor = [FontProperties getOrangeColor];
    titleLabel6.font = [FontProperties mediumFont:21.0f];
    titleLabel6.hidden = YES;
    [scrollView addSubview:titleLabel6];
    [arrayOfLabels addObject:titleLabel6];
    
    getStartedButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 3 + 40, self.view.frame.size.height, self.view.frame.size.width - 80, 60)];
    getStartedButton.hidden = YES;
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
    pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height - 40, self.view.frame.size.width - 100, 30)];
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
        UIImageView *phoneImageView = [arrayOfPhoneImageView objectAtIndex:page];
        [UIView animateWithDuration:0.7 animations:^{
            phoneImageView.frame = CGRectMake(self.view.frame.size.width * page + 50, 100, self.view.frame.size.width - 100, 420);
        }];
        UILabel *titleLabel = [arrayOfTitleLabel objectAtIndex:page];
        [UIView animateWithDuration:0.7 animations:^{
            titleLabel.frame = CGRectMake(15, 0, self.view.frame.size.width - 30, 80);
        }];
    }
    if (page == 3) {
        UILabel *titleLabel = [arrayOfTitleLabel objectAtIndex:page];
        [UIView animateWithDuration:0.7 animations:^{
            titleLabel.frame = CGRectMake(15, 0, self.view.frame.size.width - 30, 80);
        } completion:^(BOOL finished) {
            [self animateLabelAtIndex:0];
        }];

    }
}

- (void)animateLabelAtIndex:(int)index{
    if (!runningAnimations) {
        runningAnimations = YES;
        UILabel *label = [arrayOfLabels objectAtIndex:index];
        label.hidden = NO;
        label.transform = CGAffineTransformMakeScale(0.1, 0.1);
        __block int weakIndex = index;
        [UIView animateWithDuration:0.7 animations:^{
            label.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                label.transform = CGAffineTransformMakeScale(0.4, 0.4);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 animations:^{
                    label.transform = CGAffineTransformMakeScale(1.0, 1.0);
                } completion:^(BOOL finished) {
                    weakIndex += 1;
                    runningAnimations = NO;
                    if (weakIndex < [arrayOfLabels count]) [self animateLabelAtIndex:weakIndex];
                    else {
                        getStartedButton.hidden = NO;
                        [UIView animateWithDuration:0.7 animations:^{
                            getStartedButton.frame = CGRectMake(self.view.frame.size.width * 3 + 40, self.view.frame.size.height - 120, self.view.frame.size.width - 80, 60);
                        }];
                    }
                }];
            }];
        }];
    }
  

}



@end
