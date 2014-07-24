//
//  WiGoSpinnerView.h
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

@interface WiGoSpinnerView : UIActivityIndicatorView

+ (WiGoSpinnerView *)showOrangeSpinnerAddedTo:(UIView *)view;
+ (WiGoSpinnerView *)showBlueSpinnerAddedTo:(UIView *)view;
+ (BOOL)hideSpinnerForView:(UIView *)view;

+ (void)addDancingGToUIScrollView:(UIScrollView *)scrollView withHandler:(void (^)(void))handler;

+ (void)addDancingGToCenterView:(UIView *)view;
+ (BOOL)removeDancingGFromCenterView:(UIView *)view;
@end
