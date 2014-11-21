//
//  AmbassadorViewController.m
//  Wigo
//
//  Created by Alex Grinman on 11/21/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "AmbassadorViewController.h"
#import "UIButtonAligned.h"

#define kNewUsersPrefix @"New users %@"

#define kNewUsersSuffixDay @"today"
#define kNewUsersSuffixWeek @"this week"
#define kNewUsersSuffixMonth @"this month"
#define kNewUsersSuffixAll @"all time"

typedef enum { DAY, WEEK, MONTH, ALLTIME } Period;

@interface AmbassadorViewController()

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

@end

@implementation AmbassadorViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Ambassador Dashboard";
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self initializeLeftBarButton];
    [self stylePeriodSelectionButtons];
    [self styleNumbersLabels];
    [self styleActionButtons];

    [self selectDaily];
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
    self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixDay];
}
    
- (IBAction) selectWeekly {
    self.period = WEEK;
    [self setButtonSelected: self.weeklyButton];
    self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixWeek];

}

- (IBAction) selectMonthly {
    self.period = MONTH;
    [self setButtonSelected: self.monthlyButton];
    self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixMonth];

}

- (IBAction) selectAllTime {
    self.period = ALLTIME;
    [self setButtonSelected: self.allTimeButton];
    self.numberUsersDescrLabel.text = [NSString stringWithFormat: kNewUsersPrefix, kNewUsersSuffixAll];

}

@end
