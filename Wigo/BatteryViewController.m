//
//  BatteryViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "BatteryViewController.h"
#import "Globals.h"

UIImageView *orangeImageView;
NSNumber *total;
NSNumber *numGroups;
int widthShared;

@implementation BatteryViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
   
    widthShared = 100;
    [self fetchSummaryGoingOut];
    [self initializeBackground];
    [self initializeNameOfSchool];
    [self initializeShareLabel];
    [self initializeBattery];
    [self initializeShareButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   }

- (void)initializeBackground {
    UIImageView *batteryBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"batteryBackground"]];
    batteryBackground.frame = self.view.frame;
    [self.view addSubview:batteryBackground];
}

- (void)initializeNameOfSchool {
    if ([[Profile user] groupName]) {
        UILabel *schoolLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 60, self.view.frame.size.width - 44, 60)];
        schoolLabel.text = [[Profile user] groupName];
        schoolLabel.textAlignment = NSTextAlignmentCenter;
        schoolLabel.numberOfLines = 0;
        schoolLabel.lineBreakMode = NSLineBreakByWordWrapping;
        schoolLabel.textColor = [UIColor whiteColor];
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
    
    UILabel *orangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, self.view.frame.size.height/2 - 51, 14, 48)];
    orangeLabel.backgroundColor = [FontProperties getOrangeColor];
    [self.view addSubview:orangeLabel];
    
    orangeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(84, self.view.frame.size.height/2 - 53, 20, 54)];
    orangeImageView.image = [UIImage imageNamed:@"batteryRectangle"];
    [self.view addSubview:orangeImageView];
    
    UIImageView *batteryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"batteryImage"]];
    batteryImageView.frame = CGRectMake(76, self.view.frame.size.height/2 - 55, 168, 57);
    [self.view addSubview:batteryImageView];
    
  
}

- (void)initializeShareLabel {
    UILabel *shareLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.view.frame.size.height/2 + 10, self.view.frame.size.width - 20, 100)];
    shareLabel.font = [FontProperties mediumFont:18.0f];
    shareLabel.textAlignment = NSTextAlignmentCenter;
    shareLabel.textColor = [UIColor whiteColor];
    shareLabel.numberOfLines = 0;
    shareLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSString *string = @"WiGo will unlock when more people from your school download the app. Share WiGo to charge the battery and speed things up!";
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:string];
    [text addAttribute:NSForegroundColorAttributeName
                 value:RGB(238, 122, 11)
                 range:NSMakeRange(94, 7)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:RGB(238, 122, 11)
                 range:NSMakeRange(10, 6)];
    
    shareLabel.attributedText = text;
    [self.view addSubview:shareLabel];
}

- (void)initializeJoinLabel {
    UILabel *joinLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 65 - 35, self.view.frame.size.width - 40, 25)];
    joinLabel.textAlignment = NSTextAlignmentCenter;
    joinLabel.textColor = [UIColor whiteColor];
    joinLabel.font = [FontProperties mediumFont:19.0f];
   
    if (numGroups) {
        NSString *string =[NSString stringWithFormat:@"Join %@ schools already on WiGo", [numGroups stringValue]];
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:string];
        [text addAttribute:NSForegroundColorAttributeName
                     value:[UIColor whiteColor]
                     range:NSMakeRange(0, string.length)];
        [text addAttribute:NSForegroundColorAttributeName
                     value:RGB(238, 122, 11)
                     range:NSMakeRange(5, [numGroups stringValue].length)];
        joinLabel.attributedText = text;
    }
    [self.view addSubview:joinLabel];
}

- (void)initializeShareButton {
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, self.view.frame.size.height - 65, 200, 48)];
    shareButton.backgroundColor = RGB(238, 122, 11);
    [shareButton setTitle:@"Share WiGo" forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    shareButton.titleLabel.font = [FontProperties getBigButtonFont];
    shareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    shareButton.layer.borderColor = [UIColor clearColor].CGColor;
    shareButton.layer.borderWidth = 1;
    shareButton.layer.cornerRadius = 15;
    [shareButton addTarget:self action:@selector(sharedPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareButton];
}

- (void)sharedPressed {
    [EventAnalytics tagEvent:@"Share Pressed"];
    NSArray *activityItems;
    if ([[Profile user] groupName] && numGroups) {
        activityItems =  @[[NSString stringWithFormat:@"%@:\n%@ schools are going out on WiGo.\nLet's do this: wigo.us/app", [[[Profile user] groupName] uppercaseString], [numGroups stringValue]], [UIImage imageNamed:@"wigoApp" ]];
    }
    else {
        activityItems = @[@"Who is going out tonight? #WiGo http://wigo.us/app",[UIImage imageNamed:@"wigoApp" ]];
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


- (void) fetchSummaryGoingOut {
    [Network queryAsynchronousAPI:@"groups/summary/" withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if ([[jsonResponse allKeys] containsObject:@"total"]) {
                total = [jsonResponse objectForKey:@"total"];
            }
            if ([[jsonResponse allKeys] containsObject:@"num_groups"]) {
                numGroups = [jsonResponse objectForKey:@"num_groups"];
            }
            [self initializeJoinLabel];
            [self chargeBattery];
        });
    }];
}

- (void)chargeBattery {
    if (total) {
        float percentage = MIN([total floatValue]/500, 1);
        int width = 40 + percentage * (138 - 40);
        [UIView animateWithDuration:3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             orangeImageView.frame = CGRectMake(84, self.view.frame.size.height/2 - 53, width, 54);
                         }
                         completion:nil];
    }
}

@end
