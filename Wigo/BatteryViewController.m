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

UIImageView *orangeImageView;
NSNumber *currentTotal;
NSNumber *currentNumGroups;
int widthShared;
UIImageView *batteryImageView;

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
   
    widthShared = 100;
    [self initializeNameOfSchool];
    [self initializeShareLabel];
    [self initializeShareButton];
    [self initializePeekButton];
    
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(checkIfGroupIsUnlocked) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self checkIfGroupIsUnlocked];
    
    [WGAnalytics tagEvent:@"Battery View"];
    NSNumber *groupID = @1877;
    NSString *groupName = @"Maryland";
    [self.placesDelegate setGroupID:groupID andGroupName:groupName];
}

-(void) checkIfGroupIsUnlocked {
    __weak typeof(self) weakSelf = self;
    [WGProfile reload:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            return;
        }
        if (WGProfile.currentUser.group.locked && ![WGProfile.currentUser.group.locked boolValue]) {
            [strongSelf.fetchTimer invalidate];
            strongSelf.fetchTimer = nil;
            [strongSelf.navigationController pushViewController:[OnboardFollowViewController new] animated:YES];
        }
    }];
}


- (void)initializeNameOfSchool {
    if (WGProfile.currentUser.group.name) {
        UILabel *schoolLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 80, self.view.frame.size.width - 44, 60)];
        schoolLabel.text = WGProfile.currentUser.group.name;
        schoolLabel.textAlignment = NSTextAlignmentCenter;
        schoolLabel.numberOfLines = 0;
        schoolLabel.lineBreakMode = NSLineBreakByWordWrapping;
        schoolLabel.textColor = UIColor.whiteColor;
        schoolLabel.font = [FontProperties scMediumFont:20];
        [self.view addSubview:schoolLabel];
    }
}

- (void)initializeBattery {
    //193
    UILabel *youAreAlmostThereLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, self.view.frame.size.height/2 - 80, self.view.frame.size.width - 44, 20)];
    youAreAlmostThereLabel.text = @"You are almost there...";
    youAreAlmostThereLabel.textAlignment = NSTextAlignmentCenter;
    youAreAlmostThereLabel.textColor = [UIColor whiteColor];
    youAreAlmostThereLabel.font = [FontProperties mediumFont:15.0f];
    [self.view addSubview:youAreAlmostThereLabel];
    
    batteryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"batteryImage"]];
    batteryImageView.frame = CGRectMake(76, self.view.frame.size.height/2 - 55, 168, 57);
    batteryImageView.center = CGPointMake(self.view.center.x, batteryImageView.center.y);
    [self.view addSubview:batteryImageView];
    
    UILabel *orangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(batteryImageView.frame.origin.x+4, self.view.frame.size.height/2 - 51, 14, 48)];
    orangeLabel.backgroundColor = [FontProperties getOrangeColor];
    [self.view addSubview:orangeLabel];
    
    orangeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(batteryImageView.frame.origin.x+10, self.view.frame.size.height/2 - 53, 20, 54)];
    orangeImageView.image = [UIImage imageNamed:@"batteryRectangle"];
    [self.view addSubview:orangeImageView];
    
    [self.view bringSubviewToFront: batteryImageView];
    
  
}

- (void)initializeShareLabel {
    UILabel *shareLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.view.frame.size.height/2  - 100, self.view.frame.size.width - 30, 100)];
    shareLabel.font = [FontProperties mediumFont:18.0f];
    shareLabel.textAlignment = NSTextAlignmentCenter;
    shareLabel.textColor = [UIColor whiteColor];
    shareLabel.numberOfLines = 0;
    shareLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSString *string = [NSString stringWithFormat:@"%@, Wigo will unlock when more people from your school download the app. Share Wigo to speed things up!", WGProfile.currentUser.firstName];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:string];
    [text addAttribute:NSForegroundColorAttributeName
                 value:RGB(238, 122, 11)
                 range:NSMakeRange(WGProfile.currentUser.firstName.length + 12, 6)];
    
    shareLabel.attributedText = text;
    [self.view addSubview:shareLabel];
}

- (void)initializeJoinLabel {
    UILabel *joinLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 65 - 35, self.view.frame.size.width - 40, 25)];
    joinLabel.textAlignment = NSTextAlignmentCenter;
    joinLabel.textColor = [UIColor whiteColor];
    joinLabel.font = [FontProperties mediumFont:19.0f];
   
    if (currentNumGroups) {
        NSString *string =[NSString stringWithFormat:@"Join %@ schools already on Wigo", [currentNumGroups stringValue]];
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:string];
        [text addAttribute:NSForegroundColorAttributeName
                     value:[UIColor whiteColor]
                     range:NSMakeRange(0, string.length)];
        [text addAttribute:NSForegroundColorAttributeName
                     value:RGB(238, 122, 11)
                     range:NSMakeRange(5, [currentNumGroups stringValue].length)];
        joinLabel.attributedText = text;
    }
    [self.view addSubview:joinLabel];
}

- (void)initializeShareButton {
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, self.view.frame.size.height/2 + 10, 200, 48)];
//    shareButton.backgroundColor = RGB(238, 122, 11);
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
    NSArray *activityItems;
    if ([WGProfile currentUser].group.name && currentNumGroups) {
        activityItems =  @[[NSString stringWithFormat:@"%@:\n%@ schools are going out on Wigo.\nLet's do this: wigo.us/app", [[WGProfile currentUser].group.name uppercaseString], [currentNumGroups stringValue]], [UIImage imageNamed:@"wigoApp" ]];
    } else {
        activityItems = @[@"Who is going out? #Wigo http://wigo.us/app",[UIImage imageNamed:@"wigoApp" ]];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard, UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypeSaveToCameraRoll];
    [self presentViewController:activityVC animated:YES completion:nil];
    activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed) {
            int width = orangeImageView.frame.size.width;
            float percentage = (float)(width - 40)/(float)98;
            if (percentage < 1) {
                percentage = (float)MIN(0.96, (float)percentage + (float)widthShared/(float)500);
            }
            percentage = MIN(0.96, percentage);
            width = 40 + percentage * (138 - 40);
            [UIView animateWithDuration:3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 orangeImageView.frame = CGRectMake(84, self.view.frame.size.height/2 - 53, width, 54);
                             }
                             completion:nil];
        }
    };
}

- (void)initializePeekButton {
    NSString *peekSchool = @"Maryland University";
    NSString *titleString = [NSString stringWithFormat:@"Live Peek at %@", peekSchool];
    UIButton *peekButton = [[UIButton alloc] initWithFrame:CGRectMake(15, self.view.frame.size.height - 25 - 70, self.view.frame.size.width - 30, 70)];
    [peekButton addTarget:self action:@selector(peekSchoolPressed) forControlEvents:UIControlEventTouchUpInside];
    peekButton.center = CGPointMake(self.view.center.x, peekButton.center.y);
    [peekButton setTitle:titleString forState:UIControlStateNormal];
    [peekButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    peekButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    peekButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    peekButton.titleLabel.numberOfLines = 0;
    peekButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:peekButton];
    
    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(peekButton.frame.size.width - 50, 8, 50, 80)];
    rightArrowImageView.center = CGPointMake(rightArrowImageView.center.x, peekButton.center.y);
    rightArrowImageView.image = [UIImage imageNamed:@"batteryRightPost"];
    [peekButton addSubview:rightArrowImageView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 1)];
    lineView.center = CGPointMake(peekButton.center.x, lineView.center.y);
    lineView.backgroundColor = RGBAlpha(255, 255, 255, 0.3f);
    [peekButton addSubview:lineView];
}

- (void)peekSchoolPressed {
    NSNumber *groupID = @1877;
    NSString *groupName = @"Maryland";
    [self.placesDelegate presentViewWithGroupID:groupID andGroupName:groupName];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void) fetchSummaryGoingOut {
    [WGGroup getGroupSummary:^(NSNumber *total, NSNumber *numGroups, NSNumber *private, NSNumber *public, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            currentTotal = total;
            currentNumGroups = numGroups;
            [self initializeJoinLabel];
            [self chargeBattery];
        });
    }];
}

- (void)chargeBattery {
    if (currentTotal) {
        float percentage = MIN([currentTotal floatValue]/500, 1);
        int width = 40 + percentage * (138 - 40);
        [UIView animateWithDuration:3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             orangeImageView.frame = CGRectMake(orangeImageView.frame.origin.x, self.view.frame.size.height/2 - 53, width, 54);
                         }
                         completion:nil];
    }
}

@end
