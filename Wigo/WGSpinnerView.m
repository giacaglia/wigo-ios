//
//  WGSpinnerView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/10/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "WGSpinnerView.h"
#import "FontProperties.h"

@implementation WGSpinnerView

+ (WGSpinnerView *)initWithView:(UIView *)view {
    return nil;
}

+ (WGSpinnerView *)showOrangeSpinnerAddedTo:(UIView *)view {
    WGSpinnerView *spinner = [[WGSpinnerView alloc] initWithFrame:CGRectMake(135,140,80,80)];
    spinner.center = view.center;
    spinner.transform = CGAffineTransformMakeScale(2, 2);
    spinner.color = [FontProperties getOrangeColor];
    [spinner startAnimating];
    [view addSubview:spinner];
	return spinner;
}

+ (WGSpinnerView *)showBlueSpinnerAddedTo:(UIView *)view {
    WGSpinnerView *spinner = [[WGSpinnerView alloc] initWithFrame:CGRectMake(135,140,80,80)];
    spinner.center = view.center;
    spinner.transform = CGAffineTransformMakeScale(2, 2);
    spinner.color = [FontProperties getBlueColor];
    [spinner startAnimating];
    [view addSubview:spinner];
	return spinner;
}

+ (BOOL)hideSpinnerForView:(UIView *)view {
	UIView *viewToRemove = nil;
	for (UIView *v in [view subviews]) {
		if ([v isKindOfClass:[WGSpinnerView class]]) {
			viewToRemove = v;
		}
	}
	if (viewToRemove != nil) {
		WGSpinnerView *spinner = (WGSpinnerView *)viewToRemove;
        [spinner removeFromSuperview];
		return YES;
	} else {
		return NO;
	}
}

#pragma mark - Dancing G at Top of ScrollView

+ (void)addDancingGToUIScrollView:(UIScrollView *)scrollView withBackgroundColor:(UIColor *)backgroundColor withHandler:(void (^)(void))handler {
    __weak UIScrollView *tempScrollView = scrollView;
    [tempScrollView addPullToRefreshWithDrawingImgs:[WGSpinnerView getDrawingImgs] andLoadingImgs:[WGSpinnerView getLoadingImgs] andActionHandler:^{
        handler();
    }];
    scrollView.refreshControl.backgroundColor = backgroundColor;
    
}

+ (void)addDancingGToUIScrollView:(UIScrollView *)scrollView withHandler:(void (^)(void))handler {
    __weak UIScrollView *tempScrollView = scrollView;
    [tempScrollView addPullToRefreshWithDrawingImgs:[WGSpinnerView getDrawingImgs] andLoadingImgs:[WGSpinnerView getLoadingImgs] andActionHandler:^{
        handler();
    }];
}

#pragma mark - Dancing G at Center of view

+ (BOOL)isDancingGInCenterView:(UIView *)view {
    for (UIView *subview in [view subviews]) {
        if ([subview isKindOfClass:[WGImageView class]]) {
            [(WGImageView *) subview removeFromSuperview];
            return YES;
        }
    }
    return NO;
}

+ (void)addDancingGToCenterView:(UIView *)view {
    WGImageView *centeredImageView =[[WGImageView alloc] initWithFrame:CGRectMake(view.frame.size.width/2 - 30, view.frame.size.height/2 - 30, 60, 60)];
    NSArray *loadingImages = [WGSpinnerView getLoadingImgs];
    centeredImageView.animationImages = loadingImages;
    centeredImageView.animationDuration = (CGFloat)loadingImages.count/20.0;
    [centeredImageView startAnimating];
    [view addSubview:centeredImageView];
}

+ (BOOL)removeDancingGFromCenterView:(UIView *)view {
	for (UIView *subview in [view subviews]) {
		if ([subview isKindOfClass:[WGImageView class]]) {
            [(WGImageView *) subview removeFromSuperview];
            return YES;
		}
	}
    return NO;
}

#pragma mark - Dancing G with Overlay at Center of View

+ (void)addDancingGOverlayToCenterView:(UIView *)view withColor:(UIColor *)color {
    WGOverlayView *fullOverlay = [[WGOverlayView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
    
    fullOverlay.backgroundColor = color;
    [WGSpinnerView addDancingGToCenterView:fullOverlay];
    [view addSubview:fullOverlay];
}

+ (BOOL)removeDancingGOverlayFromCenterView:(UIView *)view {
    for (UIView *subview in [view subviews]) {
        if ([subview isKindOfClass:[WGOverlayView class]]) {
            [(WGOverlayView *) subview removeFromSuperview];
            return YES;
        }
    }
    return NO;
}

#pragma mark - Helper Functions

+ (NSArray *)getLoadingImgs {
    NSMutableArray *DancingGLoadingImgs = [NSMutableArray array];
    for (NSUInteger i  = 0; i <= 70; i++) {
        int fileNumber = (4*i)%31;
        NSString *fileName = [NSString stringWithFormat:@"dancingG-%d.png",fileNumber];
        [DancingGLoadingImgs addObject:[UIImage imageNamed:fileName]];
    }
    return [NSArray arrayWithArray:DancingGLoadingImgs];
}

+ (NSArray *)getDrawingImgs {
    NSMutableArray *DancingGDrawingImgs = [NSMutableArray array];
    for (NSUInteger i  = 0; i <= 1; i++) {
        int fileNumber = (4*i)%31;
        NSString *fileName = [NSString stringWithFormat:@"dancingG-%d.png",fileNumber];
        [DancingGDrawingImgs addObject:[UIImage imageNamed:fileName]];
    }
    return [NSArray arrayWithArray:DancingGDrawingImgs];
}

@end

@implementation WGImageView

@end

@implementation WGOverlayView

@end
