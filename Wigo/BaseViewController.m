//
//  UIViewController+BaseViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/10/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "BaseViewController.h"
#import "Globals.h"

@implementation BaseViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [self initializeTopBlue];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self initializeTopBlue];
    [self updateBarButtonItems:1.0f];
    self.blueBannerView.hidden = NO;
    CGRect frame =  self.navigationController.navigationBar.frame;
    self.navigationController.navigationBar.frame =  CGRectMake(frame.origin.x, 20, frame.size.width, frame.size.height);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    self.blueBannerView.hidden = NO;
//    CGRect frame =  self.navigationController.navigationBar.frame;
//    self.navigationController.navigationBar.frame =  CGRectMake(frame.origin.x, 20, frame.size.width, frame.size.height);
    [self updateBarButtonItems:1.0f];
}


- (void)initializeTopBlue {
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[[FontProperties getBlueColor] imageFromColor] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.backgroundColor = [FontProperties getBlueColor];
    self.navigationController.navigationBar.barTintColor = [FontProperties getBlueColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.selectedImageTintColor = [FontProperties getBlueColor];
    self.blueBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    self.blueBannerView.backgroundColor = [FontProperties getBlueColor];
    self.blueBannerView.hidden = NO;
    [self.view addSubview:self.blueBannerView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.navigationController.navigationBar.frame;
    //    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + self.labelSwitch.frame.size.height);
    CGFloat size = frame.size.height - 20;
    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat scrollDiff = scrollOffset - self.previousScrollViewYOffset;
    CGFloat scrollHeight = scrollView.frame.size.height;
    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;
    
    if (scrollOffset <= -scrollView.contentInset.top) {
        frame.origin.y = 20;
    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
        frame.origin.y = -size;
    } else {
        // HACK to prevent the app to go up and down.
        if (frame.origin.y == 20 && scrollOffset == - 60) {
            frame.origin.y = 20;
        }
        else {
            frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
        }
    }
    
    self.navigationController.navigationBar.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    
    //    self.navigationController.navigationBar.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - self.labelSwitch.frame.size.height);
    //    self.labelSwitch.frame = CGRectMake(frame.origin.x, frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.labelSwitch.frame.size.width, self.labelSwitch.frame.size.height);
    //    self.labelSwitch.transparency  = 1 - framePercentageHidden;
    if (self.navigationController.navigationBar.frame.origin.y +
        self.navigationController.navigationBar.frame.size.height <= 20 ||
        self.navigationController.navigationBar.frame.origin.y >= 0) {
        self.blueBannerView.hidden = NO;
    }
    else {
        self.blueBannerView.hidden = YES;
    }
    
    [self updateBarButtonItems:(1 - framePercentageHidden)];
    self.previousScrollViewYOffset = scrollOffset;
    if (scrollView.contentOffset.x != 0) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
    }
}

- (void)updateBarButtonItems:(CGFloat)alpha
{
    [self.tabBarController.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.tabBarController.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.tabBarController.navigationItem.titleView.alpha = alpha;
}

- (void)stoppedScrolling
{
    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < 20) {
        [self animateNavBarTo:-(frame.size.height - 21)];
    }
}

- (void)animateNavBarTo:(CGFloat)y
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.navigationController.navigationBar setFrame:frame];
        [self updateBarButtonItems:alpha];
    }];
}


@end
