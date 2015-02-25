//
//  BatteryViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "BatteryViewController.h"
#import "Globals.h"
#import "OnboardFollowViewController.h"
#import "ReferalViewController.h"

NSNumber *currentNumGroups;

@implementation BatteryViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = RGBAlpha(0, 0, 0, 0.9f);
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self initializeNameOfSchool];
    [self initializeShareLabel];
    [self initializeShareButton];
    [self fetchPeekSchools];
    
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(checkIfGroupIsUnlocked) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.fetchTimer) [self.fetchTimer fire];
    
    [WGAnalytics tagEvent:@"Battery View"];
    if (self.blurredBackgroundImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.image = self.blurredBackgroundImage;
        [self.view addSubview:imageView];
        [self.view sendSubviewToBack:imageView];
    }
    [self showReferral];
}

-(void) checkIfGroupIsUnlocked {
    __weak typeof(self) weakSelf = self;
    [WGProfile reload:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            return;
        }
        if (WGProfile.currentUser.group.locked &&
            ![WGProfile.currentUser.group.locked boolValue] &&
            !strongSelf.showOnboard) {
            [strongSelf.fetchTimer invalidate];
            strongSelf.fetchTimer = nil;
            strongSelf.showOnboard = YES;
            [strongSelf.placesDelegate setGroupID:WGProfile.currentUser.group.id andGroupName:WGProfile.currentUser.group.name];
            if ([strongSelf isModal]) {
                [strongSelf dismissViewControllerAnimated:NO completion:nil];

//                [strongSelf presentViewController:[OnboardFollowViewController new] animated:YES completion:^{
//                }];
            }
            else {
                [strongSelf.navigationController pushViewController:[OnboardFollowViewController new] animated:YES];
            }
        }
    }];
}


- (void)initializeNameOfSchool {
    if (WGProfile.currentUser.group.name) {
        UILabel *schoolLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, self.view.frame.size.height/2 - 140 - 60 - 20, self.view.frame.size.width - 44, 60)];
        schoolLabel.text = WGProfile.currentUser.group.name;
        schoolLabel.textAlignment = NSTextAlignmentCenter;
        schoolLabel.numberOfLines = 0;
        schoolLabel.lineBreakMode = NSLineBreakByWordWrapping;
        schoolLabel.textColor = UIColor.whiteColor;
        schoolLabel.font = [FontProperties scMediumFont:20];
        [self.view addSubview:schoolLabel];
    }
}

- (void)initializeShareLabel {
    UILabel *shareLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.view.frame.size.height/2  - 140, self.view.frame.size.width - 30, 140)];
    shareLabel.font = [FontProperties mediumFont:18.0f];
    shareLabel.textAlignment = NSTextAlignmentCenter;
    shareLabel.textColor = [UIColor whiteColor];
    shareLabel.numberOfLines = 0;
    shareLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSString *string = [NSString stringWithFormat:@"%@, Wigo will unlock when more people from your school download the app. Email hello@wigo.us to become a campus ambassador and share Wigo to speed things up!", WGProfile.currentUser.firstName];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:string];
    [text addAttribute:NSForegroundColorAttributeName
                 value:RGB(238, 122, 11)
                 range:NSMakeRange(WGProfile.currentUser.firstName.length + 12, 6)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:RGB(238, 122, 11)
                 range:NSMakeRange(WGProfile.currentUser.firstName.length + 77, 13)];
    
    shareLabel.attributedText = text;
    [self.view addSubview:shareLabel];
}

- (void)initializeShareButton {
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, self.view.frame.size.height/2 + 10, 200, 48)];
    [shareButton setTitle:@"Share Wigo" forState:UIControlStateNormal];
    [shareButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    shareButton.titleLabel.font = [FontProperties getBigButtonFont];
    shareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    shareButton.layer.borderColor = UIColor.whiteColor.CGColor;
    shareButton.layer.borderWidth = 1;
    shareButton.layer.cornerRadius = 8;
    [shareButton addTarget:self action:@selector(sharedPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareButton];
}

- (void)sharedPressed {
    [WGAnalytics tagEvent:@"Share Pressed"];
    NSArray *activityItems = @[@"This Wigo app is going to change the game! http://wigo.us/app",[UIImage imageNamed:@"wigoApp" ]];

    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard, UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypeSaveToCameraRoll];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)initializePeekButton {
    NSDictionary *sectionDictionary = [self.schoolSections objectAtIndex:1];
    NSArray *arrayOfSchools = [sectionDictionary objectForKey:@"schools"];
    NSDictionary *schoolDictionary = [arrayOfSchools objectAtIndex:0];
    self.groupID = [schoolDictionary objectForKey:@"id"];
    self.groupName = [schoolDictionary objectForKey:@"name"];
    [self.placesDelegate setGroupID:self.groupID andGroupName:self.groupName];
    NSString *str = @"0001F440";
    NSScanner *hexScan = [NSScanner scannerWithString:str];
    unsigned int hexNum;
    [hexScan scanHexInt:&hexNum];
    UTF32Char inputChar = hexNum;
    NSString *res = [[NSString alloc] initWithBytes:&inputChar length:4 encoding:NSUTF32LittleEndianStringEncoding];
    UILabel *eyeballsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 100, self.view.frame.size.width, 30)];
    eyeballsLabel.text = res;
    eyeballsLabel.textAlignment = NSTextAlignmentCenter;
    eyeballsLabel.font = [FontProperties mediumFont:30.0f];
    [self.view addSubview:eyeballsLabel];
    
    NSString *titleString = [NSString stringWithFormat:@"Live Peek at %@", self.groupName];
    UIButton *peekButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 70, self.view.frame.size.width, 70)];
    [peekButton addTarget:self action:@selector(peekSchoolPressed) forControlEvents:UIControlEventTouchUpInside];
    peekButton.center = CGPointMake(self.view.center.x, peekButton.center.y);
    [peekButton setTitle:titleString forState:UIControlStateNormal];
    [peekButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    peekButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    peekButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    peekButton.titleLabel.numberOfLines = 0;
    peekButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:peekButton];
    
    UIImageView *orangeBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, peekButton.frame.size.width, peekButton.frame.size.height)];
    orangeBackgroundImageView.image = [UIImage imageNamed:@"orangeGradientBackground"];
    [peekButton addSubview:orangeBackgroundImageView];
    [peekButton bringSubviewToFront:orangeBackgroundImageView];
    
    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(peekButton.frame.size.width - 5 - 30, peekButton.frame.size.height/2 - 4, 5, 8)];
    rightArrowImageView.image = [UIImage imageNamed:@"batteryRightPost"];
    [peekButton addSubview:rightArrowImageView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(peekButton.frame.size.width/2 - 50, 0, 100, 1)];
    lineView.backgroundColor = RGBAlpha(255, 255, 255, 0.3f);
    [peekButton addSubview:lineView];
}

- (void)showReferral {
    if (WGProfile.currentUser.findReferrer) {
        [self presentViewController:[ReferalViewController new] animated:YES completion:nil];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-d-MM HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        WGProfile.currentUser.findReferrer = NO;
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {}];
    }
}

- (void)peekSchoolPressed {
    [self.fetchTimer invalidate];
    [self.placesDelegate presentViewWithGroupID:self.groupID andGroupName:self.groupName];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)fetchPeekSchools {
    __weak typeof(self) weakSelf = self;
    [WGApi get:@"groups/peek/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!error && [WGProfile.currentUser.group.verified boolValue]) {
            strongSelf.schoolSections = [jsonResponse objectForKey:@"sections"];
            [strongSelf initializePeekButton];
        }
    }];
}

- (BOOL)isModal {
    if([self presentingViewController])
        return YES;
    if([[self presentingViewController] presentedViewController] == self)
        return YES;
    if([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController])
        return YES;
    if([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
        return YES;
    
    return NO;
}

@end
