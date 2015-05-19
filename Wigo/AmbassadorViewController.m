//
//  AmbassadorViewController.m
//  Wigo
//
//  Created by Alex Grinman on 11/21/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "AmbassadorViewController.h"
#import "UIButtonAligned.h"
#import "MobileContactsViewController.h"
#import "CampusNotificationViewController.h"
#import "TopSchoolViewController.h"
#import "JBChartView.h"
#import "JBBarChartView.h"
#import "JBLineChartView.h"
#import "TopSchool.h"

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

@property (nonatomic, assign) int currentMaxIndex;

@property (nonatomic, strong) UIView *tooltipView;
@property (nonatomic, strong) UILabel *tooltipLabel;

@property (nonatomic, assign) BOOL tooltipVisible;

@property (nonatomic, strong) NSArray *currentPercentLabels;
@end

@implementation AmbassadorViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Dashboard";
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    self.tableView.tableFooterView = [[UIView alloc] init];
    //self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.numberUsersLabel.text = @"--";
    
    [self initializeLeftBarButton];
    [self stylePeriodSelectionButtons];
    [self styleNumbersLabels];
    [self styleActionButtons];

    [self selectDaily];
    
    //only enable scroll if we need to.
    if (self.tableView.contentSize.height < self.tableView.frame.size.height) {
        self.tableView.scrollEnabled = NO;
    } else {
        self.tableView.scrollEnabled = YES;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [WGAnalytics tagEvent:@"Ambassador View"];
    [WGAnalytics tagView:@"ambassador" withTargetUser:nil];
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
    self.barGraph.frame = CGRectMake(0, 0, self.graphCell.frame.size.width - 80, self.graphCell.frame.size.height);
    self.barGraph.center = self.graphCell.contentView.center;
    self.barGraph.maximumValue = 1.0f;
    self.barGraph.minimumValue = 0.0f;
    self.barGraph.headerPadding = 0;
    self.barGraph.footerPadding = 0;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, self.barGraph.frame.size.width, 40)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"Engaged Users (%)";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties getNormalFont];
    titleLabel.textColor = [UIColor grayColor];
    self.barGraph.headerView = titleLabel;
    
    //y-axis
    UIView *yAxis = [[UIView alloc] initWithFrame: CGRectMake(0, titleLabel.frame.size.height + self.barGraph.headerPadding, 40, self.barGraph.frame.size.height - titleLabel.frame.size.height - self.barGraph.footerPadding - 15)];
    yAxis.backgroundColor = [UIColor clearColor];
    
    UILabel *topLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, yAxis.frame.size.width, 20)];
    topLabel.text = @"100%";
    topLabel.font = [FontProperties mediumFont: 12];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.textColor = [UIColor lightGrayColor];
    [yAxis addSubview: topLabel];
    
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, yAxis.frame.size.height-20, yAxis.frame.size.width, 20)];
    bottomLabel.text = @"0%";
    bottomLabel.font = [FontProperties mediumFont: 12];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.textColor = [UIColor lightGrayColor];
    [yAxis addSubview: bottomLabel];
    
    //x-axis
    
    [self.graphCell.contentView addSubview: yAxis];
    
    [self.graphCell.contentView addSubview: self.barGraph];
}

- (void) showPercentsWithValues: (NSArray *) values {
    
    //clear current percents
    if (self.currentPercentLabels) {
        for (UILabel *label in self.currentPercentLabels) {
            [label removeFromSuperview];
        }
    }
    
    CGFloat graphHeight = self.barGraph.frame.size.height - self.barGraph.headerView.frame.size.height - self.barGraph.footerPadding - 15;
    CGFloat labelWidth = self.barGraph.frame.size.width/values.count;

    NSMutableArray *percentLabels = [[NSMutableArray alloc] init];
    
    int idx = 0;
    for (NSNumber *percent in values) {
        CGFloat yPos = graphHeight*(1.0 - [percent floatValue]) - 30;
        
        CGFloat buffer = self.barGraph.headerView.frame.size.height + self.barGraph.headerPadding;
        
        UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(idx*labelWidth, buffer + yPos, labelWidth, 12)];
        label.backgroundColor = [UIColor clearColor];
        label.text = [NSString stringWithFormat: @"%i%@", (int)([percent floatValue]*100), @"%"];
        label.font = [FontProperties mediumFont: 10];
        label.textAlignment = NSTextAlignmentCenter;
        
        if (idx == _currentMaxIndex) {
            label.textColor = [FontProperties getBlueColor];
        } else {
            label.textColor = [UIColor lightGrayColor];
        }
        
        [percentLabels addObject: label];
        [self.barGraph addSubview: label];
        idx++;
    }
    
    self.currentPercentLabels = [NSArray arrayWithArray: percentLabels];
}

- (void) createXAxisWithDates:(NSArray *) dates andPeriod:(Period) period {
    NSDateFormatter *periodDateFormatter = [[NSDateFormatter alloc] init];
    
    if (period == DAY) {
        [periodDateFormatter setDateFormat:@"EEE"];
    }
    else if (period == WEEK) {
        [periodDateFormatter setDateFormat:@"MM/dd"];
    }
    else if (period == MONTH || period == ALLTIME) {
        [periodDateFormatter setDateFormat:@"MMM"];
    }
    
    
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    for (NSString *dateStr in dates) {
        NSDateFormatter *prevDateFormatter = [[NSDateFormatter alloc] init];
        [prevDateFormatter setDateFormat:@"yyyy-MM-dd"];
        
        NSDate *date = [prevDateFormatter dateFromString: dateStr];
        
        NSString *abrevDateLabel = [periodDateFormatter stringFromDate: date];
        [labels addObject: abrevDateLabel];
    }
    
    [self createXAxisWithLabels: labels];
}

- (void) createXAxisWithLabels:(NSArray *) labels {
    UIView *xAxis = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.barGraph.frame.size.width, 30)];
    CGFloat labelWidth = xAxis.frame.size.width/labels.count;
    
    int index = 0;
    for (NSString *label in labels) {
        UILabel *axisLabel = [[UILabel alloc] initWithFrame: CGRectMake(index*labelWidth,0, labelWidth, 30)];
        axisLabel.backgroundColor = [UIColor clearColor];
        axisLabel.text = label;
        axisLabel.font = [FontProperties mediumFont: 10];
        axisLabel.textAlignment = NSTextAlignmentCenter;
        axisLabel.textColor = [UIColor lightGrayColor];
        
        [xAxis addSubview: axisLabel];
        index++;
    }
    
    self.barGraph.footerView = xAxis;
}


#pragma mark - Load Stats
- (void) loadStats {
    [WGSpinnerView addDancingGToCenterView: self.navigationController.view];
    
    [GroupStats loadStats:^(GroupStats *groupStats, NSError *error) {
        [WGSpinnerView removeDancingGFromCenterView: self.navigationController.view];
        if (error) {
            //FIXME:Put alert here
            return;
        }
        self.groupStats = groupStats;
        [self changeDataForPeriod: self.period];
    }];
}

#pragma mark - Graph Related

- (void) changeDataForPeriod: (Period) period {
    
    if (self.groupStats == nil) {
        return;
    }
    
    if (!self.barGraph) {
        [self initializeBarGraph];
    }
    
    if (period == DAY) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixDay];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.todayUserCount];
        _currentMaxIndex = [self maxValueIndex: self.groupStats.dailyEngagement.values];
        [self createXAxisWithDates:self.groupStats.dailyEngagement.xAxisLabels andPeriod: period];
        [self showPercentsWithValues: self.groupStats.dailyEngagement.values];
    }
    else if (period == WEEK) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixWeek];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.weekUserCount];
        _currentMaxIndex = [self maxValueIndex: self.groupStats.weeklyEngagement.values];
        [self createXAxisWithDates:self.groupStats.weeklyEngagement.xAxisLabels andPeriod: period];
        [self showPercentsWithValues: self.groupStats.weeklyEngagement.values];

    }
    else if (period == MONTH) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixMonth];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.monthUserCount];
        _currentMaxIndex = [self maxValueIndex: self.groupStats.monthlyEngagement.values];
        [self createXAxisWithDates:self.groupStats.monthlyEngagement.xAxisLabels andPeriod: period];
        [self showPercentsWithValues: self.groupStats.monthlyEngagement.values];

    }
    else if (period == ALLTIME) {
        self.numberUsersDescrLabel.text = [NSString stringWithFormat: @"Total Users"];
        self.numberUsersLabel.text = [NSString stringWithFormat: @"%@", _groupStats.allUsersCount];
        _currentMaxIndex = [self maxValueIndex: self.groupStats.monthlyEngagement.values];
        [self createXAxisWithDates:self.groupStats.monthlyEngagement.xAxisLabels andPeriod: period];
        [self showPercentsWithValues: self.groupStats.monthlyEngagement.values];

    }

    

    
    [self.barGraph reloadData];
}

#pragma mark - Go Back
- (void) goBack {
    [self.navigationController popViewControllerAnimated: YES];
}

- (IBAction)inviteFrendsTapped:(id)sender {
    //[self presentViewController:[MobileContactsViewController new] animated:YES completion:nil];
    TopSchoolViewController *topSchools = [[TopSchoolViewController alloc] init];
    topSchools.view.frame = self.view.frame;
    [self.navigationController pushViewController: topSchools animated: true];
}

- (IBAction) sendCampusNotificationTapped {
    CampusNotificationViewController *campusNotifViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"CampusNotificationViewController"];
    
    [self.navigationController pushViewController: campusNotifViewController animated: YES];
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

- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView {
    return [UIColor clearColor];
}

- (UIColor *)barChartView:(JBBarChartView *)barChartView colorForBarViewAtIndex:(NSUInteger)index {
    if (index == _currentMaxIndex) {
        return [FontProperties getBlueColor];
    }
    return [UIColor grayColor];
}

- (CGFloat)barPaddingForBarChartView:(JBBarChartView *)barChartView {
    return 10;
}

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
    return 0.0f;
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint {
//    float percentage = 0;
//    if (self.period == DAY) {
//        percentage = [self.groupStats.dailyEngagement.values[index] floatValue]*100.0f;
//    } else if (self.period == WEEK) {
//        percentage = [self.groupStats.weeklyEngagement.values[index] floatValue]*100.0f;
//    } else if (self.period == MONTH) {
//        percentage = [self.groupStats.monthlyEngagement.values[index] floatValue]*100.0f;
//    } else if (self.period == ALLTIME) {
//        percentage = [self.groupStats.monthlyEngagement.values[index] floatValue]*100.0f;
//    }
    
    //tool tip visiblity
//    [self setTooltipVisible:YES animated:YES atTouchPoint:touchPoint];
//    self.tooltipLabel.text = [NSString stringWithFormat: @"%i%@", (int)percentage, @"%"];
//    
//    if (index == _currentMaxIndex) {
//        self.tooltipView.backgroundColor = [FontProperties getBlueColor];
//    } else {
//        self.tooltipView.backgroundColor = [UIColor grayColor];
//    }
}

- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
    [self setTooltipVisible:NO animated:YES];
}


#pragma mark - Helpers

- (int ) maxValueIndex: (NSArray *) numbers {
    NSNumber *max = @0;
    int maxIndex = 0;
    
    int index = 0;
    for (NSNumber *val in numbers) {
        if ([val compare: max] == NSOrderedDescending) {
            max = val;
            maxIndex = index;
        }
        index++;
    }
    
    return maxIndex;
}

#pragma mark - ToolTip 

- (void)setTooltipVisible:(BOOL)tooltipVisible animated:(BOOL)animated atTouchPoint:(CGPoint)touchPoint
{
    _tooltipVisible = tooltipVisible;
    
    JBChartView *chartView = self.barGraph;
    
    if (!chartView)
    {
        return;
    }
    
    if (!self.tooltipView)
    {
        self.tooltipView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 40, 40)];
        self.tooltipView.backgroundColor = [UIColor grayColor];
        
        self.tooltipLabel = [[UILabel alloc] initWithFrame: self.tooltipView.bounds];
        self.tooltipLabel.backgroundColor = [UIColor clearColor];
        self.tooltipLabel.text = @"";
        self.tooltipLabel.font = [FontProperties boldFont: 14];
        self.tooltipLabel.textAlignment = NSTextAlignmentCenter;
        self.tooltipLabel.textColor = [UIColor whiteColor];
        
        [self.tooltipView addSubview: self.tooltipLabel];
        
        
        self.tooltipView.layer.cornerRadius = self.tooltipView.frame.size.width/2;
        
        self.tooltipView.alpha = 0.0;
        [self.graphCell.contentView addSubview:self.tooltipView];
    }
    
    
    dispatch_block_t adjustTooltipPosition = ^{
        CGPoint originalTouchPoint = [self.graphCell.contentView convertPoint:touchPoint fromView:chartView];
        CGPoint convertedTouchPoint = originalTouchPoint; // modified
        JBChartView *chartView = self.barGraph;
        
        if (chartView)
        {
            CGFloat minChartX = (chartView.frame.origin.x + ceil(self.tooltipView.frame.size.width * 0.5));
            if (convertedTouchPoint.x < minChartX)
            {
                convertedTouchPoint.x = minChartX;
            }
            CGFloat maxChartX = (chartView.frame.origin.x + chartView.frame.size.width - ceil(self.tooltipView.frame.size.width * 0.5));
            if (convertedTouchPoint.x > maxChartX)
            {
                convertedTouchPoint.x = maxChartX;
            }
            self.tooltipView.frame = CGRectMake(convertedTouchPoint.x - ceil(self.tooltipView.frame.size.width * 0.5), CGRectGetMaxY(chartView.headerView.frame), self.tooltipView.frame.size.width, self.tooltipView.frame.size.height);
            
//            CGFloat minTipX = (chartView.frame.origin.x + self.tooltipTipView.frame.size.width);
//            if (originalTouchPoint.x < minTipX)
//            {
//                originalTouchPoint.x = minTipX;
//            }
//            CGFloat maxTipX = (chartView.frame.origin.x + chartView.frame.size.width - self.tooltipTipView.frame.size.width);
//            if (originalTouchPoint.x > maxTipX)
//            {
//                originalTouchPoint.x = maxTipX;
//            }
//            self.tooltipTipView.frame = CGRectMake(originalTouchPoint.x - ceil(self.tooltipTipView.frame.size.width * 0.5), CGRectGetMaxY(self.tooltipView.frame), self.tooltipTipView.frame.size.width, self.tooltipTipView.frame.size.height);
        }
    };
    
    dispatch_block_t adjustTooltipVisibility = ^{
        self.tooltipView.alpha = _tooltipVisible ? 1.0 : 0.0;
       // self.tooltipTipView.alpha = _tooltipVisible ? 1.0 : 0.0;
    };
    
    if (tooltipVisible)
    {
        adjustTooltipPosition();
    }
    
    if (animated)
    {
        [UIView animateWithDuration: 0.2 animations:^{
            adjustTooltipVisibility();
        } completion:^(BOOL finished) {
            if (!tooltipVisible)
            {
                adjustTooltipPosition();
            }
        }];
    }
    else
    {
        adjustTooltipVisibility();
    }
}

- (void)setTooltipVisible:(BOOL)tooltipVisible animated:(BOOL)animated
{
    [self setTooltipVisible:tooltipVisible animated:animated atTouchPoint:CGPointZero];
}

- (void)setTooltipVisible:(BOOL)tooltipVisible
{
    [self setTooltipVisible:tooltipVisible animated:NO];
}

@end
