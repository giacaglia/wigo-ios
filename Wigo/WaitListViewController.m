//
//  WaitListViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/22/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "WaitListViewController.h"
#import "Globals.h"

WGCollection *groups;

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
    [self fetchGroupsWaitlist];
    [self initializeTitle];
    [self initializeVogueRope];
    [self initializeOvalImages];
    [self initializeShareButton];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Wait List View"];
}

- (void)initializeTitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, 56, 200, 24)];
    titleLabel.text = @"WiGgo WAIT LIST";
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
    shareLabel.text = @"Share Wigo to jump up the list";
    shareLabel.textAlignment = NSTextAlignmentCenter;
    shareLabel.font = [FontProperties mediumFont:18.0f];
    [self.view addSubview:shareLabel];
    
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 125, self.view.frame.size.height - 65, 250, 48)];
    shareButton.backgroundColor = [FontProperties getOrangeColor];
    [shareButton setTitle:@"Share Wigo" forState:UIControlStateNormal];
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
    [WGAnalytics tagEvent:@"Share Pressed"];
    NSArray *activityItems = @[@"Who is going out? #Wigo http://wigo.us/app",[UIImage imageNamed:@"wigoApp" ]];
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

- (void)initializeTableViewOfSchools {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(54, 200, self.view.frame.size.width - 108, self.view.frame.size.height - 300)];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 25;
}

#pragma mark - UITableView Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    WGGroup *school = (WGGroup *)[groups objectAtIndex:[indexPath row]];
    BOOL mySchool = NO;
    
    UILabel *rankingSchool = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 55, 25)];
    rankingSchool.text = [NSString stringWithFormat:@"%@.", school.rank];
    rankingSchool.textColor = RGBAlpha(212, 212, 212, 100);
    rankingSchool.textAlignment = NSTextAlignmentLeft;
    rankingSchool.font = [FontProperties mediumFont:20.0f];
    [cell.contentView addSubview:rankingSchool];
    
    UILabel *nameOfSchool = [[UILabel alloc] initWithFrame:CGRectMake(55, 0, self.view.frame.size.width - 40, 25)];
    nameOfSchool.text = school.name;
    nameOfSchool.textAlignment = NSTextAlignmentLeft;
    nameOfSchool.font = [FontProperties mediumFont:20.0f];
    if (mySchool) nameOfSchool.textColor = [FontProperties getOrangeColor];
    [cell.contentView addSubview:nameOfSchool];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return 4;
}

#pragma mark - Network function

- (void) fetchGroupsWaitlist {
    [WGGroup getWaitlist:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            groups = collection;
        });
    }];
}


@end
