//
//  AmbassadorViewController.m
//  Wigo
//
//  Created by Alex Grinman on 11/21/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "AmbassadorViewController.h"
#import "UIButtonAligned.h"

#import "JBChartView.h"
#import "JBBarChartView.h"
#import "JBLineChartView.h"

#define kNewUsersPrefix @"New users %@"

#define kNewUsersSuffixDay @"today"
#define kNewUsersSuffixWeek @"this week"
#define kNewUsersSuffixMonth @"this month"
#define kNewUsersSuffixAll @"all time"

typedef enum { DAY, WEEK, MONTH, ALLTIME } Period;

@interface AmbassadorViewController()<JBBarChartViewDataSource, JBBarChartViewDelegate>

@property (nonatomic, strong) GroupStats *groupStats;

@property (nonatomic, assign) Period period;
@property (nonatomic, strong) IBOutlet UIButton *dailyButton;
@property (nonatomic, strong) IBOutlet UIButton *weeklyButton;
@property (nonatomic, strong) IBOutlet UIButton *monthlyButton;
@property (nonatomic, strong) IBOutlet UIButton *allTimeButton;

@property (nonatomic, strong) IBOutlet UILabel *numberUsersLabel;
@property (nonatomic, strong) IBOutlet UILabel *numberUsersDescrLabel;

@property (nonatomic, strong) IBOutlet UIButton *campusNotifButton;
@property (nonatomic, strong) IBOutlet UIButton *inviteButton;

@property (nonatomic, strong) IBOutlet UITableViewCell *graphCell;

@property (nonatomic, strong) JBChartView *barGraph;

@end

@implementation AmbassadorViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Ambassador Dashboard";
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    self.numberUsersLabel.text = @"--";
    
    [self initializeLeftBarButton];
    [self stylePeriodSelectionButtons];
    [self styleNumbersLabels];
    [self styleActionButtons];

    [self selectDaily];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self loadStats];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSmallFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) stylePeriodSelectionButtons {
    NSArray *buttons = @[_dailyButton, _weeklyButton, _monthlyButton, _allTimeButton];
    
    for (UIButton *bttn in buttons) {
        
        [bttn setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
        bttn.titleLabel.textAlignment = NSTextAlignmentCenter;
        bttn.titleLabel.font = [FontProperties mediumFont: 15];
        bttn.layer.borderColor = [FontProperties getBlueColor].CGColor;
        bttn.layer.borderWidth = 1;
        bttn.layer.cornerRadius = 4;
        bttn.backgroundColor = [UIColor clearColor];
    }
}

- (void) styleNumbersLabels {
    self.numberUsersLabel.font = [FontProperties mediumFont: 100];
    self.numberUsersLabel.minimumScaleFactor = 0.5;
    self.numberUsersLabel.textColor = [FontProperties getOrangeColor];
    
    self.numberUsersDescrLabel.font = [FontProperties getNormalFont];
}

- (void) styleActionButtons {
    NSArray *buttons = @[_inviteButton, _campusNotifButton];
    
    for (UIButton *bttn in buttons) {
        [bttn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        bttn.titleLabel.textAlignment = NSTextAlignmentCenter;
        bttn.titleLabel.font = [FontProperties mediumFont: 15];
        bttn.layer.borderColor = [FontProperties getOrangeColor].CGColor;
        bttn.layer.borderWidth = 1;
        bttn.layer.cornerRadius = 4;
        bttn.backgroundColor = [FontProperties getOrangeColor];
    }
}

- (void) initializeBarGraph {
    self.barGraph = [[JBBarChartView alloc] init];
    self.barGraph.delegate = self;
    self.barGraph.dataSource = self;
    self.barGraph.frame = self.graphCell.bounds;
    
    [self.graphCell.contentView addSubview: self.barGraph];
}


#pragma mark - Load Stats
- (void) loadStats {
    [WiGoSpinnerView addDancingGToCenterView: self.navigationController.view];
    
    [GroupStats loadStats:^(GroupStats *groupStats, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [WiGoSpinnerView removeDancingGFromCenterView: self.navigationController.view];
        });
        
        if (error) {
            
            //FIXME:Put alert here
            return;
        }
        self.groupStats = groupStats;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self changeDataForPeriod: self.period];
        });
        
    }];
}

#pragma mark - Graph Related

- (void) changeDataForPeriod: (Period) period {
    
    if (self.groupStats == nil) {
        return;
    }
    
    
    if (period == DAY) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixDay];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.todayUserCount];
    }
    else if (period == WEEK) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixWeek];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.weekUserCount];

    }
    else if (period == MONTH) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixMonth];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.monthUserCount];

    }
    else if (period == ALLTIME) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixAll];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.allUsersCount];

    }
    
    if (!self.barGraph) {
        [self initializeBarGraph];
    }
    
    [self.barGraph reloadData];
}

#pragma mark - Go Back
- (void) goBack {
    [self.navigationController popViewControllerAnimated: YES];
}


#pragma mark - Change Period

- (void) clearAllSelections {
    NSArray *buttons = @[_dailyButton, _weeklyButton, _monthlyButton, _allTimeButton];
    
    for (UIButton *bttn in buttons) {
        [bttn setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
        bttn.backgroundColor = [UIColor clearColor];
    }
}

- (void) setButtonSelected: (UIButton *) buttonToSelect {
    [self clearAllSelections];
    
    [buttonToSelect setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    buttonToSelect.backgroundColor = [FontProperties getBlueColor];
}

- (IBAction) selectDaily {
    self.period = DAY;
    [self setButtonSelected: self.dailyButton];
    [self changeDataForPeriod: self.period];
}
    
- (IBAction) selectWeekly {
    self.period = WEEK;
    [self setButtonSelected: self.weeklyButton];
    [self changeDataForPeriod: self.period];
}

- (IBAction) selectMonthly {
    self.period = MONTH;
    [self setButtonSelected: self.monthlyButton];
    [self changeDataForPeriod: self.period];
}

- (IBAction) selectAllTime {
    self.period = ALLTIME;
    [self setButtonSelected: self.allTimeButton];
    [self changeDataForPeriod: self.period];
}

#pragma mark - JBChart Delegate + Datasource

- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    if (self.period == DAY) {
        return self.groupStats.dailyEngagement.xAxisLabels.count;
    } else if (self.period == WEEK) {
        return self.groupStats.weeklyEngagement.xAxisLabels.count;
    } else if (self.period == MONTH) {
        return self.groupStats.monthlyEngagement.xAxisLabels.count;
    } else if (self.period == ALLTIME) {
        return self.groupStats.monthlyEngagement.xAxisLabels.count;
    }
    NSLog(@"Bar Chart error: no index exists!");
    return 0;
}

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    if (self.period == DAY) {
        return [self.groupStats.dailyEngagement.values[index] floatValue];
    } else if (self.period == WEEK) {
        return [self.groupStats.weeklyEngagement.values[index] floatValue];
    } else if (self.period == MONTH) {
        return [self.groupStats.monthlyEngagement.values[index] floatValue];
    } else if (self.period == ALLTIME) {
        return [self.groupStats.monthlyEngagement.values[index] floatValue];
    }
    NSLog(@"Bar Chart error: no index exists!");
    return 0;
}

@end
