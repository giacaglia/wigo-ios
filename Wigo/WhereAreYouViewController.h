//
//  WhereAreYouViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/13/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PrivateSwitchView.h"
#import "WGSwitchView.h"
#import "FSCalendar.h"

@interface WhereAreYouViewController : UIViewController<UITextFieldDelegate,
                                                    PrivacySwitchDelegate,
                                                    WGSwitchDelegate,
                                                    FSCalendarDelegate>
@property (nonatomic, strong) UITextField *whereAreYouGoingTextField;
@property (nonatomic, strong) UIView *eventDetails;
@property (nonatomic, strong) PrivateSwitchView *privateSwitchView;
@property (nonatomic, strong) WGSwitchView *wgSwitchView;
@property (nonatomic, strong) UILabel *invitePeopleLabel;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *loadingIndicator;
@property (nonatomic, strong) FSCalendar *fsCalendar;
@property (nonatomic, strong) FSCalendarHeader *fsCalendarHeader;

// Setting time
@property (nonatomic, strong) UIImageView *clockImageView;
@property (nonatomic, strong) UILabel *startTimeLabel;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UILabel *startsAtLabel;
@property (nonatomic, strong) UILabel *realStartTimeLabel;
@property (nonatomic, strong) UIView *datePickerHeader;
@end
