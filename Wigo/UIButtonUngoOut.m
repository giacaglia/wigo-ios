//
//  UIButtonUngoOut.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/17/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UIButtonUngoOut.h"
#import "RWBlurPopover.h"
#import "Globals.h"

@implementation UIButtonUngoOut

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitle:@"YOU ARE GOING OUT!" forState:UIControlStateNormal];
        [self setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
        self.titleLabel.font = SC_MEDIUM_FONT(15.0f);
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addTarget:self action:@selector(ungoOutPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void) ungoOutPressed {
    UIViewController *cancelViewController = [[UIViewController alloc] init];
    
    UIButton *stayInButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 0, 248, 42)];
    stayInButton.backgroundColor = [UIColor whiteColor];
    [stayInButton addTarget:self action:@selector(stayInPressed) forControlEvents:UIControlEventTouchUpInside];
    [stayInButton setTitle:@"STAY IN" forState:UIControlStateNormal];
    [stayInButton setTitleColor:RGB(214, 45, 58) forState:UIControlStateNormal];
    stayInButton.titleLabel.font = [FontProperties getTitleFont];
    stayInButton.layer.borderColor = RGB(214, 45, 58).CGColor;
    stayInButton.layer.borderWidth = 0.5;
    [cancelViewController.view addSubview:stayInButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 0 + 42 + 12, 248, 42)];
    cancelButton.backgroundColor = RGB(214, 45, 58);
    [cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    [cancelViewController.view addSubview:cancelButton];
    
    cancelViewController.view.backgroundColor = [UIColor clearColor];
    [[RWBlurPopover instance] presentViewController:cancelViewController withOrigin:0 andHeight:140];
}

- (void) stayInPressed {
    User *profileUser = [Profile user];
    [profileUser setIsGoingOut:NO];
    [profileUser saveKeyAsynchronously:@"is_goingout"];
    [profileUser setIsGoingOut:NO];
    [Profile setUser:profileUser];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateViewNotGoingOut" object:nil];
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}

- (void) cancel {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}


@end
