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
    UILabel *thankYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/4 - 0.1*self.view.frame.size.width - 50, self.view.frame.size.width, 40)];
    thankYouLabel.text = @"Thank you";
    thankYouLabel.textColor = UIColor.blackColor;
    thankYouLabel.textAlignment = NSTextAlignmentCenter;
    thankYouLabel.font = [FontProperties semiboldFont:30.0f];
    if (isIphone6Plus|| isIphone6) thankYouLabel.font = [FontProperties semiboldFont:34.0f];
    [self.view addSubview:thankYouLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/4 - 0.1*self.view.frame.size.width, self.view.frame.size.width, 60)];
    subtitleLabel.text = @"We have added you to our\nsignup queue.";
    subtitleLabel.textColor = UIColor.blackColor;
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [FontProperties lightFont:20.0f];
    if (isIphone6Plus || isIphone6) subtitleLabel.font = [FontProperties lightFont:24.0f];
    subtitleLabel.numberOfLines = 2;
    [self.view addSubview:subtitleLabel];
    
    UIImageView *leftPuzzleImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0.05*[UIScreen mainScreen].bounds.size.width, 0.4*[UIScreen mainScreen].bounds.size.width)];
    leftPuzzleImgView.center = CGPointMake(leftPuzzleImgView.center.x, self.view.center.y);
    leftPuzzleImgView.image = [UIImage imageNamed:@"leftPuzzle"];
    [self.view addSubview:leftPuzzleImgView];
    
    UIImageView *puzzleImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0.76*[UIScreen mainScreen].bounds.size.width, 0.4*[UIScreen mainScreen].bounds.size.width)];
    puzzleImgView.center = self.view.center;
    puzzleImgView.image = [UIImage imageNamed:@"puzzle"];
    [self.view addSubview:puzzleImgView];
    
    UIImageView *rightPuzzleImgView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 16, 0, 0.05*[UIScreen mainScreen].bounds.size.width, 0.4*[UIScreen mainScreen].bounds.size.width)];
    rightPuzzleImgView.center = CGPointMake(rightPuzzleImgView.center.x, self.view.center.y);
    rightPuzzleImgView.image = [UIImage imageNamed:@"rightPuzzle"];
    [self.view addSubview:rightPuzzleImgView];
    
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    numberLabel.center = CGPointMake(self.view.center.x, self.view.center.y - 20);
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSString *formattedOutput = [formatter stringFromNumber:WGProfile.currentUser.waitListPos];
    numberLabel.text = formattedOutput;
    numberLabel.font = [FontProperties semiboldFont:30.0f];
    if (isIphone6Plus || isIphone6) numberLabel.font = [FontProperties semiboldFont:34.0f];
    numberLabel.textColor = [FontProperties getBlueColor];
    numberLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:numberLabel];
    
    UILabel *pplAheadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    pplAheadLabel.center = CGPointMake(self.view.center.x, self.view.center.y + 20);
    pplAheadLabel.text = @"People ahead of you";
    pplAheadLabel.font = [FontProperties lightFont:16.0f];
    if (isIphone6Plus || isIphone6) pplAheadLabel.font = [FontProperties lightFont:18.0f];
    pplAheadLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:pplAheadLabel];
    
    UIButton *sharebutton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 70 - 69 - 25, self.view.frame.size.width, 70 + 69 + 25)];
    [sharebutton addTarget:self action:@selector(shareNowPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sharebutton];
    
    UILabel *skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 70 - 69 - 25, self.view.frame.size.width, 25)];
    skipLabel.text = @"Or... Skip the line!";
    skipLabel.font = [FontProperties mediumFont:18.0f];
    if (isIphone6Plus || isIphone6) {
        skipLabel.font = [FontProperties mediumFont:22.0f];
        skipLabel.frame = CGRectMake(0,  self.view.frame.size.height - 70 - 69 - 25 - 10, self.view.frame.size.width, 25);
    }
    skipLabel.textColor = [FontProperties getBlueColor];
    skipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:skipLabel];
    
    UILabel *shareAppNow = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 70 - 69, self.view.frame.size.width, 69)];
    shareAppNow.text = @"Get early access by sharing Wigo with\nyour friends. The more friends you share\nwith, the sooner you'll get access.";
    shareAppNow.numberOfLines = 0;
    shareAppNow.textAlignment = NSTextAlignmentCenter;
    shareAppNow.font = [FontProperties lightFont:16.0f];
    if (isiPhone4s) shareAppNow.font = [FontProperties lightFont:14.0f];
    if (isIphone6Plus || isIphone6) shareAppNow.font = [FontProperties lightFont:18.0f];
    [self.view addSubview:shareAppNow];
    
    UIButton *shareNowButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width, 60)];
    [shareNowButton addTarget:self action:@selector(shareNowPressed) forControlEvents:UIControlEventTouchUpInside];
    shareNowButton.backgroundColor = [FontProperties getBlueColor];
    [shareNowButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [shareNowButton setTitle:@"Share now" forState:UIControlStateNormal];
    shareNowButton.titleLabel.font = [FontProperties mediumFont:18.0f];
    if (isIphone6Plus || isIphone6) shareNowButton.titleLabel.font = [FontProperties mediumFont:22.0f];
    [self.view addSubview:shareNowButton];
    
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reloadUser) userInfo:nil repeats:YES];
}

-(void) reloadUser {
    __weak typeof(self) weakSelf = self;
    [WGProfile reload:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (![WGProfile.currentUser.status isEqual:kStatusWaiting]) {
            [strongSelf dismissViewControllerAnimated:YES completion:nil];
            [strongSelf.fetchTimer invalidate];
            strongSelf.fetchTimer = nil;
        }
    }];
}

-(void) shareNowPressed {
    FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:@"https://fb.me/847330831988239"];
    //optionally set previewImageURL
    content.previewImageURL = [NSURL URLWithString:@"https://scontent.xx.fbcdn.net/hphotos-xta1/v/t1.0-9/11238216_1439554293026893_6205650579948710271_n.jpg?oh=2bd7fda52e6044eb96f3a5d7c9e5115e&oe=55DB23AB"];
    
    // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
    [FBSDKAppInviteDialog showWithContent:content
                                 delegate:self];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog
 didCompleteWithResults:(NSDictionary *)result {
    WGProfile.currentUser.status = @"active";
    [WGProfile.currentUser save:^(BOOL success, NSError *error) {}];
    [TabBarAuxiliar clearOutAllNotifications];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog
       didFailWithError:(NSError *)error {
    NSLog(@"error: %@", error.localizedDescription);
}

@end
