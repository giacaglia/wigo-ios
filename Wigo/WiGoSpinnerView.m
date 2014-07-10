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
                                                                                

@end
