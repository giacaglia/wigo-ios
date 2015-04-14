//
//  WhereAreYouViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/13/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WhereAreYouViewController.h"
#import "Globals.h"
#import "FSCalendar.h"
#import "PrivateSwitchView.h"

@implementation WhereAreYouViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = UIColor.whiteColor;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.privateSwitchView.closeLockImageView stopAnimating];
    [self.privateSwitchView.openLockImageView stopAnimating];
}

- (void)setup {
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    UIScrollView *backgroundScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    backgroundScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 380 + 110 + 200);
    backgroundScrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:backgroundScrollView];
    
    UILabel *eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 45, 10, 90, 30)];
    eventNameLabel.text = @"Event Name";
    eventNameLabel.textColor = [FontProperties getBlueColor];
    eventNameLabel.textAlignment = NSTextAlignmentCenter;
    eventNameLabel.font = [FontProperties scMediumFont:15.0f];
    [backgroundScrollView addSubview:eventNameLabel];
    
    UIView *lineUnderEventName = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 45, 40, 90, 1)];
    lineUnderEventName.backgroundColor = [FontProperties getBlueColor];
    [backgroundScrollView addSubview:lineUnderEventName];
    
    self.whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 50)];
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
    [backgroundScrollView addSubview:self.whereAreYouGoingTextField];
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.view.frame.size.height - 1, self.view.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [[FontProperties getBlueColor] colorWithAlphaComponent: 0.5f].CGColor;
    [backgroundScrollView.layer addSublayer:bottomBorder];
    
    self.eventDetails = [[UIView alloc] initWithFrame:CGRectMake(0, 110, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [backgroundScrollView addSubview:self.eventDetails];
    
    UILabel *eventTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 30)];
    eventTypeLabel.text = @"Event Type";
    eventTypeLabel.textAlignment = NSTextAlignmentCenter;
    eventTypeLabel.textColor = [FontProperties getBlueColor];
    eventTypeLabel.font = [FontProperties scMediumFont:15.0f];
    [self.eventDetails addSubview:eventTypeLabel];
    
    UIView *lineUnderEventType = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 45, 30, 90, 1)];
    lineUnderEventType.backgroundColor = [FontProperties getBlueColor];
    [self.eventDetails addSubview:lineUnderEventType];
    
    self.privateSwitchView = [[PrivateSwitchView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 120, 40, 240, 40)];
    [self.eventDetails addSubview:self.privateSwitchView];
    self.privateSwitchView.privateString = @"Only you can invite people and only\nthose invited can see the event.";
    self.privateSwitchView.publicString =  @"The whole school can see and attend your event.";
    self.privateSwitchView.privateDelegate = self;
    [self.privateSwitchView.closeLockImageView stopAnimating];
    [self.privateSwitchView.openLockImageView stopAnimating];
    
    self.invitePeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 82, [UIScreen mainScreen].bounds.size.width, 30)];
    self.invitePeopleLabel.text = _privateSwitchView.explanationString;
    self.invitePeopleLabel.textAlignment = NSTextAlignmentCenter;
    self.invitePeopleLabel.numberOfLines = 2;
    self.invitePeopleLabel.font = [FontProperties openSansRegular:12.0f];
    self.invitePeopleLabel.textColor = [FontProperties getBlueColor];
    [self.eventDetails addSubview:self.invitePeopleLabel];
    
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        self.eventDetails.frame = CGRectMake(0, 77, [UIScreen mainScreen].bounds.size.width, 30);
    }
    
    [self.whereAreYouGoingTextField becomeFirstResponder];
    
//    FSCalendar *fsCalendar = [[FSCalendar alloc] initWithFrame:CGRectMake(0, 130, self.view.frame.size.width, 250)];
//    fsCalendar.flow = FSCalendarFlowHorizontal;
//    [self.eventDetails addSubview:fsCalendar];
//
//    FSCalendarHeader *fsCalendarHeader = [[FSCalendarHeader alloc] initWithFrame:CGRectMake(0, 110, self.view.frame.size.width, 20)];
//    fsCalendar.header = fsCalendarHeader;
//    [self.eventDetails addSubview:fsCalendarHeader];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    titleLabel.text = @"Create Event";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [FontProperties mediumFont:18.0f];
    self.navigationItem.titleView = titleLabel;
    
    [self.navigationItem setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Cancel" style: UIBarButtonItemStylePlain target: self action: @selector(cancelCreateEvent)] animated: NO];

    [self.navigationItem setRightBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Done" style: UIBarButtonItemStylePlain target: self action: @selector(createPressed)] animated: NO];

    [self.navigationItem.leftBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

    [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

    
    
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
//                              __weak typeof(strongSelf) weakOfStrong = strongSelf;
//                              [WGProfile.currentUser goingToEvent:object withHandler:^(BOOL success, NSError *error) {
//                                  __strong typeof(weakOfStrong) strongOfStrong = weakOfStrong;
//                                  if (error) {
//                                      [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
//                                      [[WGError sharedInstance] logError:error forAction:WGActionSave];
//                                      return;
//                                  }
//                                  
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
//                              }];
                          }];
                      }];
}

- (void)cancelCreateEvent {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)updateUnderliningText {
    self.invitePeopleLabel.text = _privateSwitchView.explanationString;
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

@end
