//
//  WiGoSpinnerView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/10/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WiGoSpinnerView : UIActivityIndicatorView

+ (WiGoSpinnerView *)showOrangeSpinnerAddedTo:(UIView *)view;
+ (WiGoSpinnerView *)showBlueSpinnerAddedTo:(UIView *)view;
+ (BOOL)hideSpinnerForView:(UIView *)view;

@end
