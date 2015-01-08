//
//  WiGoSpinnerView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/10/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "WiGoSpinnerView.h"
#import "FontProperties.h"

@implementation WiGoSpinnerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (WiGoSpinnerView *)initWithView:(UIView *)view {
    return nil;
}

+ (WiGoSpinnerView *)showOrangeSpinnerAddedTo:(UIView *)view {
    WiGoSpinnerView *spinner = [[WiGoSpinnerView alloc] initWithFrame:CGRectMake(135,140,80,80)];
    spinner.center = view.center;
    spinner.transform = CGAffineTransformMakeScale(2, 2);
    spinner.color = [FontProperties getOrangeColor];
    [spinner startAnimating];
    [view addSubview:spinner];
	return spinner;
}

+ (WiGoSpinnerView *)showBlueSpinnerAddedTo:(UIView *)view {
    WiGoSpinnerView *spinner = [[WiGoSpinnerView alloc] initWithFrame:CGRectMake(135,140,80,80)];
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
		if ([v isKindOfClass:[WiGoSpinnerView class]]) {
			viewToRemove = v;
		}
	}
	if (viewToRemove != nil) {
		WiGoSpinnerView *spinner = (WiGoSpinnerView *)viewToRemove;
        [spinner removeFromSuperview];
		return YES;
	} else {
		return NO;
	}
}



#pragma mark - Dancing G at Top of ScrollView

+ (void)addDancingGToUIScrollView:(UIScrollView *)scrollView withBackgroundColor:(UIColor *)backgroundColor withHandler:(void (^)(void))handler {
    __weak UIScrollView *tempScrollView = scrollView;
    [tempScrollView addPullToRefreshWithDrawingImgs:[WiGoSpinnerView getDrawingImgs] andLoadingImgs:[WiGoSpinnerView getLoadingImgs] andActionHandler:^{
        handler();
    }];
    scrollView.refreshControl.backgroundColor = backgroundColor;
    
}

+ (void)addDancingGToUIScrollView:(UIScrollView *)scrollView withHandler:(void (^)(void))handler {
    __weak UIScrollView *tempScrollView = scrollView;
    [tempScrollView addPullToRefreshWithDrawingImgs:[WiGoSpinnerView getDrawingImgs] andLoadingImgs:[WiGoSpinnerView getLoadingImgs] andActionHandler:^{
        handler();
    }];
}

#pragma mark - Dancing G at Center of view

+ (void)addDancingGToCenterView:(UIView *)view {
    UIImageView *centeredImageView =[[UIImageView alloc] initWithFrame:CGRectMake(view.frame.size.width/2 - 30, view.frame.size.height/2 - 30, 60, 60)];
    NSArray *loadingImages = [WiGoSpinnerView getLoadingImgs];
    centeredImageView.animationImages = loadingImages;
    centeredImageView.animationDuration = (CGFloat)loadingImages.count/20.0;
    [centeredImageView startAnimating];
    [view addSubview:centeredImageView];
}

+ (BOOL)removeDancingGFromCenterView:(UIView *)view {
    UIView *viewToRemove = nil;
	for (UIView *v in [view subviews]) {
		if ([v isKindOfClass:[UIImageView class]]) {
			viewToRemove = v;
		}
	}
	if (viewToRemove != nil) {
		UIImageView *spinner = (UIImageView *)viewToRemove;
        [spinner removeFromSuperview];
		return YES;
	} else {
		return NO;
	}
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
