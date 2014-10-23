//
//  WaitListViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/22/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "WaitListViewController.h"
#import "Globals.h"

@implementation WaitListViewController


- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeTitle];
    [self initializeVogueRope];
    [self initializeListOfSchools];
    [self initializeOvalImages];
    [self initializeShareButton];
}

- (void)initializeTitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, 56, 200, 24)];
    titleLabel.text = @"WiGo WAIT LIST";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties scMediumFont:20.0f];
    [self.view addSubview:titleLabel];
}

- (void)initializeVogueRope {
    UIImageView *vogueRopeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 30, self.view.frame.size.width - 20, 150)];
    vogueRopeImageView.image = [UIImage imageNamed:@"VogueRope"];
    [self.view addSubview:vogueRopeImageView];
}

- (void)initializeShareButton {
    UILabel *shareLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 90 - 16, self.view.frame.size.width - 40, 25)];
    shareLabel.text = @"Share WiGo to jump up the list";
    shareLabel.textAlignment = NSTextAlignmentCenter;
    shareLabel.font = [FontProperties mediumFont:18.0f];
    [self.view addSubview:shareLabel];
    
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 125, self.view.frame.size.height - 65, 250, 48)];
    shareButton.backgroundColor = [FontProperties getOrangeColor];
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
    NSArray *activityItems = @[@"Who is going out tonight? #WiGo http://wigo.us/app",[UIImage imageNamed:@"wigoApp" ]];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard, UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypeSaveToCameraRoll];
    [self presentViewController:activityVC animated:YES completion:nil];
}


- (void)initializeOvalImages {
    UIImageView *ovalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(58, 240, 5, 32)];
    ovalImageView.image = [UIImage imageNamed:@"oval"];
    [self.view addSubview:ovalImageView];
    
    UIImageView *newOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(58, 400, 5, 32)];
    newOvalImageView.image = [UIImage imageNamed:@"oval"];
    [self.view addSubview:newOvalImageView];
}

- (void)initializeListOfSchools {
    [self viewForSchool:@{@"rank": @"1.", @"name": @"Virginia University"} andFrame: CGRectMake(54, 200, self.view.frame.size.width - 108, 25)];
    
    [self viewForSchool:@{@"rank": @"83.", @"name": @"Columbia"} andFrame:CGRectMake(54, 300, self.view.frame.size.width - 108, 25)];
    
    [self viewForSchool:@{@"rank": @"84.", @"name": @"MIT"} andFrame:CGRectMake(54, 330, self.view.frame.size.width - 108, 25)];
    
    [self viewForSchool:@{@"rank": @"85.", @"name": @"Harvard"} andFrame:CGRectMake(54, 360, self.view.frame.size.width - 108, 25)];
}

- (void)viewForSchool:(NSDictionary *)school andFrame:(CGRect)frame {
    UIView *schoolView = [[UIView alloc] initWithFrame:frame];
   
    UILabel *rankingSchool = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 25)];
    rankingSchool.text = [school objectForKey:@"rank"];
    rankingSchool.textColor = RGBAlpha(212, 212, 212, 100);
    rankingSchool.textAlignment = NSTextAlignmentLeft;
    rankingSchool.font = [FontProperties mediumFont:20.0f];
    [schoolView addSubview:rankingSchool];
    
    UILabel *nameOfSchool = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, schoolView.frame.size.width - 40, 25)];
    nameOfSchool.text = [school objectForKey:@"name"];
    nameOfSchool.textAlignment = NSTextAlignmentLeft;
    nameOfSchool.font = [FontProperties mediumFont:20.0f];
    [schoolView addSubview:nameOfSchool];
    
    [self.view addSubview:schoolView];
}

@end
