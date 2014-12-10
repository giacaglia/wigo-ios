//
//  ContactUsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ContactUsViewController.h"
#import "Globals.h"
#import "RWBlurPopover.h"

@interface ContactUsViewController ()

@end

@implementation ContactUsViewController

- (id)init
{
    self = [super init];
    if (self) {
       
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *sendEmailButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50, 248, 42)];
    sendEmailButton.backgroundColor = RGB(246, 143, 30);
    [sendEmailButton setTitle:@"SEND EMAIL" forState:UIControlStateNormal];
    [sendEmailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    sendEmailButton.titleLabel.font = [FontProperties getTitleFont];
    [sendEmailButton addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendEmailButton];
    
    UIButton *copyEmailButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50 + 42 + 12, 248, 42)];
    copyEmailButton.backgroundColor = [FontProperties getBlueColor];
    [copyEmailButton addTarget:self action:@selector(copyEmail) forControlEvents:UIControlEventTouchUpInside];
    [copyEmailButton setTitle:@"COPY EMAIL ADDRESS" forState:UIControlStateNormal];
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

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [EventAnalytics tagEvent:@"Contact Us View"];
}

- (void)sendEmail {
    NSString *path;
    NSString *subject = @"Question about Wigo";
    NSString *toField = @"support@wigo.us";
    BOOL gmailInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlegmail://requests"]];
    if (gmailInstalled) {
        path = [NSString stringWithFormat:@"googlegmail:/co?to=%@&subject=%@", toField, subject];
    }
    else {
        path = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@", toField, subject];
    }
    NSURL *url = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[RWBlurPopover instance] dismissViewControllerAnimated:NO completion:nil];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)copyEmail {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = @"support@wigo.us";
}

- (void)cancelPressed {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}


@end
