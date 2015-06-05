//
//  WhereAreYouViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/13/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WhereAreYouViewController.h"
#import "Globals.h"
#import "PrivateSwitchView.h"

@implementation WhereAreYouViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.privateSwitchView.closeLockImageView stopAnimating];
    [self.privateSwitchView.openLockImageView stopAnimating];
    CGRect frame =  self.navigationController.navigationBar.frame;
    self.navigationController.navigationBar.frame =  CGRectMake(frame.origin.x, 20, frame.size.width, frame.size.height);
    [WGAnalytics tagView:@"where_are_you" withTargetUser:nil];
    [WGAnalytics tagEvent:@"Where Are You View"];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.backgroundColor = [FontProperties getBlueColor];
    CGRect frame =  self.navigationController.navigationBar.frame;
    self.navigationController.navigationBar.frame =  CGRectMake(frame.origin.x, 20, frame.size.width, frame.size.height);
}

-(void) setup {
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.view.backgroundColor = RGB(248, 248, 248);
    [self initializeNavigationItem];
    
    UIView *blueBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    blueBannerView.backgroundColor = [FontProperties getBlueColor];
    [self.view addSubview:blueBannerView];
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 80)];
    backgroundView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:backgroundView];
    
//    self.whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 80 - 10, 80)];
    self.whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    self.whereAreYouGoingTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Hawaiian Night @ Grey Lady" attributes:@{NSForegroundColorAttributeName:RGB(178, 178, 178)}];
    self.whereAreYouGoingTextField.font = [FontProperties openSansRegular:18.0f];
    self.whereAreYouGoingTextField.textAlignment = NSTextAlignmentCenter;
    self.whereAreYouGoingTextField.textColor = [FontProperties getBlueColor];
    [[UITextField appearance] setTintColor:[FontProperties getBlueColor]];
    self.whereAreYouGoingTextField.delegate = self;
    self.whereAreYouGoingTextField.returnKeyType = UIReturnKeyDone;
    [self.whereAreYouGoingTextField addTarget:self
                                   action:@selector(textFieldDidChange:)
                         forControlEvents:UIControlEventEditingChanged];
    self.whereAreYouGoingTextField.backgroundColor = UIColor.whiteColor;
    [backgroundView addSubview:self.whereAreYouGoingTextField];
    [self.whereAreYouGoingTextField becomeFirstResponder];
    
//    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(self.whereAreYouGoingTextField.frame.size.width - 1, 10, 1, self.whereAreYouGoingTextField.frame.size.height - 20)];
//    lineView.backgroundColor = RGB(216, 216, 216);
//    [self.whereAreYouGoingTextField addSubview:lineView];
    
//    UIButton *whiteTimeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, 0, 80, 80)];
//    whiteTimeButton.backgroundColor = UIColor.whiteColor;
//    [whiteTimeButton addTarget:self action:@selector(timePressed) forControlEvents:UIControlEventTouchUpInside];
//    [backgroundView addSubview:whiteTimeButton];
//    
//    self.clockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(40 - 12.5, 15, 25, 25)];
//    self.clockImageView.image = [UIImage imageNamed:@"clockImage"];
//    [whiteTimeButton addSubview:self.clockImageView];
//    
//    self.startTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, 80, 15)];
//    self.startTimeLabel.text = @"Set start time?";
//    self.startTimeLabel.font = [FontProperties mediumFont:10.0f];
//    self.startTimeLabel.textColor = RGB(178, 178, 178);
//    self.startTimeLabel.textAlignment = NSTextAlignmentCenter;
//    [whiteTimeButton addSubview:self.startTimeLabel];
//    
//    self.startsAtLabel = [[UILabel alloc] initWithFrame:CGRectMake(40 - 20, 20, 40, 20)];
//    self.startsAtLabel.text = @"Starts at";
//    self.startsAtLabel.textAlignment = NSTextAlignmentCenter;
//    self.startsAtLabel.textColor = RGB(178, 178, 178);
//    self.startsAtLabel.font = [FontProperties mediumFont:11.0f];
//    self.startsAtLabel.hidden = YES;
//    [whiteTimeButton addSubview:self.startsAtLabel];
//    
//    self.realStartTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 80, 10)];
//    self.realStartTimeLabel.textAlignment = NSTextAlignmentCenter;
//    self.realStartTimeLabel.textColor = [FontProperties getBlueColor];
//    self.realStartTimeLabel.font = [FontProperties mediumFont:13.0f];
//    self.realStartTimeLabel.hidden = YES;
//    [whiteTimeButton addSubview:self.realStartTimeLabel];
    
    self.eventDetails = [[UIView alloc] initWithFrame:CGRectMake(0, 64 + 90, [UIScreen mainScreen].bounds.size.width, self.view.frame.size.height - 64 - 90)];
    [self.view addSubview:self.eventDetails];
    
    self.datePickerHeader = [[UIView alloc] initWithFrame:CGRectMake(0, self.eventDetails.frame.size.height - 216 - 40, self.view.frame.size.width, 40)];
    self.datePickerHeader.hidden = YES;
    [self.eventDetails addSubview:self.datePickerHeader];
    
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.eventDetails.frame.size.width, 0.5)];
    topLineView.backgroundColor = RGB(151, 151, 151);
    [self.datePickerHeader addSubview:topLineView];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 40)];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitleColor:RGB(170, 170, 170) forState:UIControlStateNormal];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties mediumFont:14.0f];
    [self.datePickerHeader addSubview:cancelButton];
    
    UILabel *selectTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    selectTimeLabel.text = @"Select Time";
    selectTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self.datePickerHeader addSubview:selectTimeLabel];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.datePickerHeader.frame.size.width - 70, 0, 70, 40)];
    [doneButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    doneButton.titleLabel.font = [FontProperties mediumFont:14.0f];
    [self.datePickerHeader addSubview:doneButton];
    
    self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, self.eventDetails.frame.size.height - 216
                                                                     , self.view.frame.size.width, 216)];
    self.datePicker.hidden = YES;
    self.datePicker.backgroundColor = UIColor.whiteColor;
    self.datePicker.datePickerMode = UIDatePickerModeTime;
    [self.datePicker addTarget:self action:@selector(changedTime) forControlEvents:UIControlEventValueChanged];
    [self.eventDetails addSubview:self.datePicker];
    
    self.privateSwitchView = [[PrivateSwitchView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 120, 10, 240, 40)];
    [self.eventDetails addSubview:self.privateSwitchView];
    self.privateSwitchView.privateString = @"Only you can invite people and only\nthose invited can see the event.";
    self.privateSwitchView.publicString =  @"Everyone around you can see and\nattend your event.";
    self.privateSwitchView.privateDelegate = self;
    self.privateSwitchView.backgroundColor = UIColor.whiteColor;
    [self.privateSwitchView.closeLockImageView stopAnimating];
    [self.privateSwitchView.openLockImageView stopAnimating];
    
    self.invitePeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 52, [UIScreen mainScreen].bounds.size.width, 30)];
    self.invitePeopleLabel.text = _privateSwitchView.explanationString;
    self.invitePeopleLabel.textAlignment = NSTextAlignmentCenter;
    self.invitePeopleLabel.numberOfLines = 2;
    self.invitePeopleLabel.font = [FontProperties openSansRegular:12.0f];
    self.invitePeopleLabel.textColor = [FontProperties getBlueColor];
    [self.eventDetails addSubview:self.invitePeopleLabel];
    
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        self.eventDetails.frame = CGRectMake(0, 64 + 75, [UIScreen mainScreen].bounds.size.width, 30);
    }
    
//    self.wgSwitchView = [[WGSwitchView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 120, 90, 240, 40)];
//    self.wgSwitchView.firstString = @"Today";
//    self.wgSwitchView.secondString = @"Future";
//    self.wgSwitchView.movingImageView.image = [UIImage imageNamed:@"calendarIcon"];
//    self.wgSwitchView.switchDelegate = self;
//    self.wgSwitchView.backgroundColor = UIColor.whiteColor;
//    [self.eventDetails addSubview:self.wgSwitchView];
//    
//    self.fsCalendar = [[FSCalendar alloc] initWithFrame:CGRectMake(0, 170, self.view.frame.size.width, 250)];
//    self.fsCalendar.flow = FSCalendarFlowHorizontal;
//    self.fsCalendar.hidden = YES;
//    self.fsCalendar.delegate = self;
//    self.fsCalendar.backgroundColor = UIColor.whiteColor;
//    [self.eventDetails addSubview:self.fsCalendar];
//    
//    NSInteger maxDaysOut = 9;
//    self.fsCalendar.maxDate = [[NSDate date] dateByAddingTimeInterval:60.0*60.0*24.0*maxDaysOut];
//    
//    self.fsCalendarHeader = [[FSCalendarHeader alloc] initWithFrame:CGRectMake(0, 140, self.view.frame.size.width, 30)];
//    self.fsCalendar.header = self.fsCalendarHeader;
//    self.fsCalendarHeader.hidden = YES;
//    self.fsCalendarHeader.backgroundColor = UIColor.whiteColor;
//    [self.eventDetails addSubview:self.fsCalendarHeader];
}

- (void)cancelPressed {
    self.clockImageView.hidden = NO;
    self.startTimeLabel.hidden = NO;
    self.datePickerHeader.hidden = YES;
    self.datePicker.hidden = YES;
    self.startsAtLabel.hidden = YES;
    self.realStartTimeLabel.hidden = YES;
    [self.whereAreYouGoingTextField endEditing:YES];
}

- (void)donePressed {
    self.datePickerHeader.hidden = YES;
    self.datePicker.hidden = YES;
}

- (void)timePressed {
    self.clockImageView.hidden = YES;
    self.startTimeLabel.hidden = YES;
    self.datePickerHeader.hidden = NO;
    self.datePicker.hidden = NO;
    self.startsAtLabel.hidden = NO;
    self.realStartTimeLabel.hidden = NO;
    [self.whereAreYouGoingTextField endEditing:YES];
}

-(void)changedTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"];
    self.realStartTimeLabel.text  = [formatter stringFromDate:self.datePicker.date];
}

- (void)initializeNavigationItem {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    titleLabel.text = @"Create Event";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [FontProperties mediumFont:18.0f];
    self.navigationItem.titleView = titleLabel;
    
    [self.navigationItem setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Cancel" style: UIBarButtonItemStylePlain target: self action: @selector(cancelCreateEvent)] animated: NO];
    
    [self.navigationItem setRightBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Done" style: UIBarButtonItemStylePlain target: self action: @selector(createPressed)] animated: NO];
    
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
    
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

}

- (void)createPressed {
    if (self.whereAreYouGoingTextField.text.length == 0) return;
    
    WGProfile.tapAll = NO;
    WGProfile.currentUser.youAreInCharge = NO;
    self.whereAreYouGoingTextField.enabled = NO;
    self.tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
    
    NSDate *eventDate = nil;
    if(_wgSwitchView.privacyTurnedOn) {
        eventDate = self.fsCalendar.selectedDate;
    }
    
    // convert to noon in local time zone
    eventDate = [eventDate noonOfDateInLocalTimeZone];
    
    [self addLoadingIndicator];
    __weak typeof(self) weakSelf = self;
    [WGEvent createEventWithName:self.whereAreYouGoingTextField.text
                      andPrivate:_privateSwitchView.privacyTurnedOn
                         andDate:eventDate
                      andHandler:^(WGEvent *object, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [UIView animateWithDuration:0.2f animations:^{
          strongSelf.loadingIndicator.frame = CGRectMake(0, 0, strongSelf.loadingView.frame.size.width, strongSelf.loadingView.frame.size.height);
        } completion:^(BOOL finished) {
          if (finished) [strongSelf.loadingView removeFromSuperview];
          [strongSelf.navigationController popViewControllerAnimated:YES];
        }];
    }];
}

- (void)cancelCreateEvent {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)addLoadingIndicator {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(10, 64 + 5, self.view.frame.size.width - 20, 5)];
    self.loadingView.layer.borderColor = [FontProperties getBlueColor].CGColor;
    self.loadingView.layer.borderWidth = 1.0f;
    self.loadingView.layer.cornerRadius = 3.0f;
    [self.view addSubview:self.loadingView];
    
    self.loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.loadingView.frame.size.height)];
    self.loadingIndicator.backgroundColor = [FontProperties getBlueColor];
    [self.loadingView addSubview:self.loadingIndicator];
    
    [UIView animateWithDuration:0.8f animations:^{
        self.loadingIndicator.frame = CGRectMake(0, 0, self.loadingView.frame.size.width*0.7, self.loadingView.frame.size.height);
    }];
}


- (void)textFieldDidChange:(UITextField *)textField {
    if(textField.text.length != 0) {
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
    } else {
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self createPressed];
    return YES;
}

#pragma mark - Private Switch Delegate

- (void)updateUnderliningText {
    self.invitePeopleLabel.text = _privateSwitchView.explanationString;
}


#pragma mark - WGSwitch View Delegate 

- (void)switched {
    self.fsCalendar.hidden = !self.fsCalendar.hidden;
    self.fsCalendarHeader.hidden = !self.fsCalendarHeader.hidden;
    if (self.fsCalendar.isHidden) {
        self.wgSwitchView.secondString = @"Future";
    }
    else {
        [self.whereAreYouGoingTextField endEditing:YES];
    }
}

#pragma mark - FSCalendar Delegate

- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EE, MMMM dd"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *dateString = [dateFormatter stringFromDate:date];
    self.wgSwitchView.secondString = dateString;
}

@end
