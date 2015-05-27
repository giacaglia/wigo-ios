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
    
    self.whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 80)];
    self.whereAreYouGoingTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Señor Frogs @ 8pm (3rd & Main)" attributes:@{NSForegroundColorAttributeName:RGBAlpha(122, 193, 226, 0.5)}];
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
    [self.view addSubview:self.whereAreYouGoingTextField];
    [self.whereAreYouGoingTextField becomeFirstResponder];
    
    self.eventDetails = [[UIView alloc] initWithFrame:CGRectMake(0, 64 + 90, [UIScreen mainScreen].bounds.size.width, self.view.frame.size.height - 64 - 90)];
    [self.view addSubview:self.eventDetails];
    
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
//    self.fsCalendarHeader = [[FSCalendarHeader alloc] initWithFrame:CGRectMake(0, 140, self.view.frame.size.width, 30)];
//    self.fsCalendar.header = self.fsCalendarHeader;
//    self.fsCalendarHeader.hidden = YES;
//    self.fsCalendarHeader.backgroundColor = UIColor.whiteColor;
//    [self.eventDetails addSubview:self.fsCalendarHeader];

    //    [UIView animateWithDuration: 0.2 animations:^{
    //        self.tabBarController.navigationItem.titleView.alpha = 0.0f;
    //        self.tabBarController.navigationItem.leftBarButtonItem.customView.alpha = 0.0f;
    //        self.tabBarController.navigationItem.rightBarButtonItem.customView.alpha = 0.0f;
    //
    //        [self.whereAreYouGoingTextField becomeFirstResponder];
    //        _whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0, 50);
    //        _whereAreYouGoingView.alpha = 1.0f;
    //
    //    } completion:^(BOOL finished) {
    //
    //        [self.tabBarController.navigationItem setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Cancel" style: UIBarButtonItemStylePlain target: self action: @selector(cancelledAddEventTapped)] animated: NO];
    //
    //        [self.tabBarController.navigationItem setRightBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Create" style: UIBarButtonItemStylePlain target: self action: @selector(createPressed)] animated: NO];
    //
    //        [self.tabBarController.navigationItem.leftBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
    //
    //        [self.tabBarController.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
    //
    //        self.placesTableView.userInteractionEnabled = NO;
    //    }];
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
    [self addLoadingIndicator];
    __weak typeof(self) weakSelf = self;
    [WGEvent createEventWithName:self.whereAreYouGoingTextField.text
                      andPrivate:_privateSwitchView.privacyTurnedOn
                      andHandler:^(WGEvent *object, NSError *error) {
                          __strong typeof(weakSelf) strongSelf = weakSelf;
                          [UIView animateWithDuration:0.2f animations:^{
                              strongSelf.loadingIndicator.frame = CGRectMake(0, 0, strongSelf.loadingView.frame.size.width, strongSelf.loadingView.frame.size.height);
                          } completion:^(BOOL finished) {
                              if (finished) [strongSelf.loadingView removeFromSuperview];
                              [strongSelf.navigationController popViewControllerAnimated:YES];
//                                  [strongOfStrong removeProfileUserFromAnyOtherEvent];
//                                  [strongOfStrong dismissKeyboard];
//                                  
//                                  WGProfile.currentUser.isGoingOut = @YES;
//                                  WGProfile.currentUser.eventAttending = object;
//                                  
//                                  WGEventAttendee *attendee = [[WGEventAttendee alloc] initWithJSON:@{ @"user" : WGProfile.currentUser }];
//                                  
//                                  if ([strongOfStrong.allEvents containsObject:object]) {
//                                      WGEvent *joinedEvent = (WGEvent *)[strongOfStrong.allEvents objectWithID:object.id];
//                                      [joinedEvent.attendees insertObject:attendee atIndex:0];
//                                  } else {
//                                      if (object.attendees) {
//                                          [object.attendees insertObject:attendee atIndex:0];
//                                      } else {
//                                          WGCollection *eventAttendees = [WGCollection serializeArray:@[ [attendee deserialize] ] andClass:[WGEventAttendee class]];
//                                          object.attendees = eventAttendees;
//                                      }
//                                  }
//                                  [strongOfStrong fetchEventsFirstPage];
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
