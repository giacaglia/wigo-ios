//
//  WGSpinnerView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/10/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+GifPullToRefresh.h"


typedef enum {
    TOP,
    CENTER,
    BOTTOM
} POSITION;

@interface WGSpinnerView : UIActivityIndicatorView

+ (WGSpinnerView *)showOrangeSpinnerAddedTo:(UIView *)view;
+ (WGSpinnerView *)showBlueSpinnerAddedTo:(UIView *)view;
+ (BOOL)hideSpinnerForView:(UIView *)view;

+ (void)addDancingGToUIScrollView:(UIScrollView *)scrollView withBackgroundColor:(UIColor *)backgroundColor withHandler:(void (^)(void))handler;
+ (void)addDancingGToUIScrollView:(UIScrollView *)scrollView withHandler:(void (^)(void))handler;

+ (void)addDancingGToCenterView:(UIView *)view;
+ (BOOL)removeDancingGFromCenterView:(UIView *)view;

+ (void)addDancingGOverlayToCenterView:(UIView *)view withColor:(UIColor *)color;
+ (BOOL)removeDancingGOverlayFromCenterView:(UIView *)view;

@end

@interface WGImageView : UIImageView

@end

@interface WGOverlayView : UIView

@end
