//
//  WaitListViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/5/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WaitListViewController.h"
#import "Globals.h"
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface WaitListViewController () <FBSDKAppInviteDialogDelegate>
@end

@implementation WaitListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self initializeThanks];
}

-(void) initializeThanks {
    UILabel *thankYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, 60)];
    thankYouLabel.text = @"Thank you";
    thankYouLabel.textColor = UIColor.blackColor;
    thankYouLabel.textAlignment = NSTextAlignmentCenter;
    thankYouLabel.font = [FontProperties semiboldFont:30.0f];
    [self.view addSubview:thankYouLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, 60)];
    subtitleLabel.text = @"We have added you to our signup queue.";
    subtitleLabel.textColor = UIColor.blackColor;
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [FontProperties lightFont:20.0f];
    subtitleLabel.numberOfLines = 2;
    [self.view addSubview:subtitleLabel];
    
    UIImageView *puzzleImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 302, 160)];
    puzzleImgView.center = self.view.center;
    puzzleImgView.image = [UIImage imageNamed:@"puzzle"];
    [self.view addSubview:puzzleImgView];
    
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    numberLabel.center = CGPointMake(self.view.center.x, self.view.center.y - 20);
    numberLabel.text = @"1,392";
    numberLabel.font = [FontProperties semiboldFont:30.0f];
    numberLabel.textColor = [FontProperties getBlueColor];
    numberLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:numberLabel];
    
    UILabel *pplAheadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    pplAheadLabel.center = CGPointMake(self.view.center.x, self.view.center.y + 20);
    pplAheadLabel.text = @"People ahead of you";
    pplAheadLabel.font = [FontProperties lightFont:16.0f];
    pplAheadLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:pplAheadLabel];
    
    UILabel *skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 70 - 69 - 30, self.view.frame.size.width, 30)];
    skipLabel.text = @"Or... Skip the line!";
    skipLabel.font = [FontProperties mediumFont:18.0f];
    skipLabel.textColor = [FontProperties getBlueColor];
    skipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:skipLabel];
    
    UILabel *shareAppNow = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 70 - 69, self.view.frame.size.width, 69)];
    shareAppNow.text = @"If you share this app now to 5 of your\nfriends we will reward you with\nimmediate access!";
    shareAppNow.numberOfLines = 0;
    shareAppNow.textAlignment = NSTextAlignmentCenter;
    shareAppNow.font = [FontProperties lightFont:16.0f];
    [self.view addSubview:shareAppNow];
    
    UIButton *shareNowButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width, 60)];
    [shareNowButton addTarget:self action:@selector(shareNowPressed) forControlEvents:UIControlEventTouchUpInside];
    shareNowButton.backgroundColor = [FontProperties getBlueColor];
    [shareNowButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [shareNowButton setTitle:@"Share now" forState:UIControlStateNormal];
    shareNowButton.titleLabel.font = [FontProperties mediumFont:18.0f];
    [self.view addSubview:shareNowButton];
}

-(void) shareNowPressed {
    FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:@"https://fb.me/847330831988239"];
    //optionally set previewImageURL
    content.previewImageURL = [NSURL URLWithString:@"http://www.wigo.us/static/img/logo.png"];
    
    // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
    [FBSDKAppInviteDialog showWithContent:content
                                 delegate:self];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog
 didCompleteWithResults:(NSDictionary *)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog
       didFailWithError:(NSError *)error {
    NSLog(@"error: %@", error.localizedDescription);
}

@end
