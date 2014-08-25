//
//  MoreViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MoreViewController.h"
#import "Globals.h"
#import "RWBlurPopover.h"
@interface MoreViewController ()
@property STATE state;
@end

BOOL once;

@implementation MoreViewController

- (id)initWithState:(STATE)state
{
    self = [super init];
    if (self) {
        _state = state;
    }
    return self;
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)viewDidLoad
{
    once = YES;
    [super viewDidLoad];
    
    if (_state == FOLLOWING_USER ||
        _state == ACCEPTED_PRIVATE_USER ||
        _state == ATTENDING_EVENT_FOLLOWING_USER ||
        _state == ATTENDING_EVENT_ACCEPTED_PRIVATE_USER) {
        UIButton *unfollowButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50, 248, 42)];
        unfollowButton.backgroundColor = RGB(246, 143, 30);
        [unfollowButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
        [unfollowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        unfollowButton.titleLabel.font = [FontProperties getTitleFont];
        [unfollowButton addTarget:self action:@selector(unfollowPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:unfollowButton];
    }
    
    UIButton *blockButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50 + 42 + 12, 248, 42)];
    blockButton.backgroundColor = [UIColor redColor];
    [blockButton addTarget:self action:@selector(blockPressed) forControlEvents:UIControlEventTouchUpInside];
    [blockButton setTitle:@"BLOCK" forState:UIControlStateNormal];
    [blockButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    blockButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:blockButton];

    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50 + 42 + 12 + 42 + 12, 248, 42)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(214, 45, 58) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(214, 45, 58).CGColor;
    cancelButton.layer.borderWidth = 0.5;
    [self.view addSubview:cancelButton];
}


- (void)unfollowPressed {
    if (once) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"unfollowPressed" object:nil];
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)blockPressed {
    if (once) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"blockPressed" object:nil];
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)cancelPressed {
    if (once) {
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
    }
}


@end

