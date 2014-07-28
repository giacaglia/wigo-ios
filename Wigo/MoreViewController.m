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

@end

@implementation MoreViewController

- (id)init
{
    self = [super init];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *sendEmailButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50, 248, 42)];
    sendEmailButton.backgroundColor = RGB(246, 143, 30);
    [sendEmailButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
    [sendEmailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    sendEmailButton.titleLabel.font = [FontProperties getTitleFont];
    [sendEmailButton addTarget:self action:@selector(unfollowPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendEmailButton];
    
    UIButton *copyEmailButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50 + 42 + 12, 248, 42)];
    copyEmailButton.backgroundColor = [UIColor redColor];
    [copyEmailButton addTarget:self action:@selector(blockPressed) forControlEvents:UIControlEventTouchUpInside];
    [copyEmailButton setTitle:@"BLOCK" forState:UIControlStateNormal];
    [copyEmailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    copyEmailButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:copyEmailButton];
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"unfollowPressed" object:nil];
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}

- (void)blockPressed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"blockPressed" object:nil];
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];

}

- (void)cancelPressed {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}


@end

