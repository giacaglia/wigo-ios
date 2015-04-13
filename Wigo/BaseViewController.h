//
//  UIViewController+BaseViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/10/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

@property (nonatomic, assign) CGFloat previousScrollViewYOffset;
@property (nonatomic, strong) UIView *blueBannerView;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
@end
