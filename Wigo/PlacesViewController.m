//
//  PlacesViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PlacesViewController.h"
#import "Globals.h"
#import "RWBlurPopover.h"

//View Extensions
#import "UIButtonAligned.h"
#import "UIButtonUngoOut.h"
#import "WigoConfirmationViewController.h"
#import "MobileContactsViewController.h"
#import "InviteViewController.h"
#import "SignViewController.h"
#import "SignNavigationViewController.h"
#import "PeekViewController.h"
#import "EventStoryViewController.h"
#import "FancyProfileViewController.h"
#import "FXBlurView.h"

//#define sizeOfEachCell [[UIScreen mainScreen] bounds].size.width/1.6
#define sizeOfEachCell 64 + [EventPeopleScrollView containerHeight] + 10

#define kEventCellName @"EventCell"
#define kHighlightOldEventCel @"HighlightOldEventCell"
#define kOldEventCellName @"OldEventCell"

#import "WGEvent.h"
#import "WGProfile.h"

#define kOldEventShowHighlightsCellName @"OldEventShowHighlightsCellName"

@interface PlacesViewController () {
    UIView *_dimView;
    BOOL isLoaded;

}

@property UIView *whereAreYouGoingView;
@property UITextField *whereAreYouGoingTextField;
@property UIButton *clearButton;
@property UIButton *createButton;

@property int tagInteger;
@property Party *contentParty;
@property Party *filteredContentParty;
@property NSMutableArray *filteredPartyUserArray;

//@property NSMutableArray *filteredContentList;
@property BOOL isSearching;
@property NSMutableArray *placeSubviewArray;
@property UIImageView *searchIconImageView;
@property UIView *searchBarBorderView;

@property UIImageView *whereImageView;
@property UILabel *whereLabel;
@property int yPositionOfWhereSubview;
@property  UIButton *goingSomewhereButton;

@property UITableView *placesTableView;

//private pressed
@property UIScrollView *scrollViewSender;
@property CGPoint scrollViewPoint;

// Events Summary
@property Party *eventsParty;
@property Party *oldEventsParty;
@property NSMutableArray *partyUserArray;

// Go OUT Button
@property UIButtonUngoOut *ungoOutButton;
@property BOOL spinnerAtCenter;

// Events By Days
@property (nonatomic, strong) NSMutableArray *pastDays;
@property (nonatomic, strong) NSMutableDictionary *dayToEventObjArray;

//Go Elsewhere
@property (nonatomic, strong) GoOutNewPlaceHeader *goElsewhereView;
@end

BOOL fetchingEventAttendees;
BOOL shouldAnimate;
BOOL presentedMobileContacts;
NSNumber *page;
NSMutableArray *eventPageArray;
int sizeOfEachImage;
BOOL shouldReloadEvents;
int firstIndexOfNegativeEvent;

@implementation PlacesViewController {
    int numberOfFetchedParties;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.automaticallyAdjustsScrollViewInsets = NO;
    eventPageArray = [[NSMutableArray alloc] init];
    fetchingEventAttendees = NO;
    shouldAnimate = NO;
    presentedMobileContacts = NO;
    shouldReloadEvents = YES;
    firstIndexOfNegativeEvent = -1;
    self.eventOffsetDictionary = [NSMutableDictionary new];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }

    [self initializeFlashScreen];

    _spinnerAtCenter = YES;
    [self initializeWhereView];
    
    // Hack to set the user key
    [WGProfile setCurrentUser:[WGUser serialize:@{ @"key" : @"0068HVzaTEuLVHASiUk7uaeu3i" }]];
    
    [WGProfile reload:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            return;
        }
        [WGProfile currentUser].firstName = @"Adam";
        [[WGProfile currentUser] save:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                return;
            }
            NSLog(@"%@", [WGProfile currentUser].firstName);
            NSLog(@"%@", [[WGProfile currentUser].created joinedString]);
        }];
    }];
    
    /* [WGEvent get:^(WGCollection *collection, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            return;
        }
        
        for (WGEvent *event in collection) {
            NSLog(@"Event: %@", event.id);
            for (WGEventAttendee *attendee in event.attendees) {
                NSLog(@"Attendee: %@ %@", attendee.user.firstName, attendee.user.lastName);
                NSLog(@"Event from Attendee: %@", attendee.user.isAttending.name);
            };
            [event getMessages:^(WGCollection *collection, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                for (WGEventMessage *eventMessage in collection) {
                    NSLog(@"Author: %@ %@", eventMessage.user.firstName, eventMessage.user.lastName);
                    NSLog(@"Media: %@", eventMessage.media);
                    NSLog(@"Message: %@", eventMessage.message);
                    NSLog(@"Event: %@", event.name);
                };
            }];
        }
    }]; */
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = RGB(100, 173, 215);
    [self.navigationController.navigationBar setBackgroundImage:[self imageWithColor:RGB(100, 173, 215)] forBarMetrics:UIBarMetricsDefault];

    [self initializeNotificationObservers];
    [self initializeNavigationBar];


    if (!self.visitedProfile) {
        self.eventOffsetDictionary = [NSMutableDictionary new];
    }
    self.visitedProfile = NO;
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    [self.navigationController.navigationBar setBackgroundImage:[self imageWithColor:UIColor.whiteColor] forBarMetrics:UIBarMetricsDefault];
}

- (void) viewDidAppear:(BOOL)animated {
    [EventAnalytics tagEvent:@"Where View"];
  
    [self.view endEditing:YES];
    [self fetchIsThereNewPerson];
    if (shouldReloadEvents) {
        [self fetchEventsFirstPage];
    }
    else {
        shouldReloadEvents = YES;
    }
    [self shouldShowCreateButton];

}

- (BOOL) shouldShowCreateButton {
    if ([self isPeeking]) {
        self.goElsewhereView.hidden = YES;
        self.goElsewhereView.plusButton.enabled = NO;
        self.goingSomewhereButton.hidden = YES;
        self.goingSomewhereButton.enabled = NO;
        return NO;
    }
    else {
        self.goElsewhereView.hidden = NO;
        //self.goElsewhereView.plusButton.hidden = NO;
        self.goElsewhereView.plusButton.enabled = YES;
        //self.goingSomewhereButton.hidden = NO;
        self.goingSomewhereButton.enabled = YES;
        return YES;
    }
}

- (BOOL) isPeeking {
    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        return NO;
    }
    
    return YES;
}

- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void) initializeNavigationBar {
  
    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        CGRect profileFrame = CGRectMake(3, 0, 30, 30);
        UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        [profileImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]] placeholderImage:[[UIImage alloc] init] imageArea:[[Profile user] coverImageArea]];
        [profileButton addSubview:profileImageView];
        [profileButton addTarget:self action:@selector(profileSegue)
                forControlEvents:UIControlEventTouchUpInside];
        [profileButton setShowsTouchWhenHighlighted:YES];
        if (!self.leftRedDotLabel) {
            self.leftRedDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, -5, 13, 13)];
            self.leftRedDotLabel.backgroundColor = [FontProperties getOrangeColor];
            self.leftRedDotLabel.layer.borderColor = [UIColor clearColor].CGColor;
            self.leftRedDotLabel.clipsToBounds = YES;
            self.leftRedDotLabel.layer.borderWidth = 3;
            self.leftRedDotLabel.layer.cornerRadius = 8;
        }
        [profileButton addSubview:self.leftRedDotLabel];
        if ([(NSNumber *)[[Profile user] objectForKey:@"num_unread_conversations"] intValue] > 0 ||
            [(NSNumber *)[[Profile user] objectForKey:@"num_unread_notifications"] intValue] > 0) {
            self.leftRedDotLabel.hidden = NO;
        }
        else {
            self.leftRedDotLabel.hidden = YES;
        }
        UIBarButtonItem *profileBarButton = [[UIBarButtonItem alloc] initWithCustomView:profileButton];
        self.navigationItem.leftBarButtonItem = profileBarButton;
        
        self.rightButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 10, 30, 30) andType:@3];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 8, 22, 17)];
        imageView.image = [UIImage imageNamed:@"followPlusWhite"];
        [self.rightButton addTarget:self action:@selector(followPressed)
                   forControlEvents:UIControlEventTouchUpInside];
        [self.rightButton addSubview:imageView];
        [self.rightButton setShowsTouchWhenHighlighted:YES];
        UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.rightButton];
        self.navigationItem.rightBarButtonItem = rightBarButton;
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }

    [self updateTitleView];
}

- (void)initializeFlashScreen {
    SignViewController *signViewController = [[SignViewController alloc] init];
    SignNavigationViewController *signNavigationViewController = [[SignNavigationViewController alloc] initWithRootViewController:signViewController];
    [self presentViewController:signNavigationViewController animated:NO completion:nil];
}


- (void)initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateViewNotGoingOut)
                                                 name:@"updateViewNotGoingOut"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollUp)
                                                 name:@"scrollUp"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chooseEvent:)
                                                 name:@"chooseEvent"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchEventsFirstPage)
                                                 name:@"fetchEvents"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchUserInfo)
                                                 name:@"fetchUserInfo"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentContactsView)
                                                 name:@"presentContactsView"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadViewAfterSigningUser)
                                                 name:@"loadViewAfterSigningUser"
                                               object:nil];

}

- (void)loadViewAfterSigningUser {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canFetchAppStartup"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchAppStart" object:nil];
}


- (void)scrollUp {
    [_placesTableView setContentOffset:CGPointZero animated:YES];
}

- (void) updateViewNotGoingOut {
    [[Profile user] setIsGoingOut:NO];
    [self updateTitleView];
    [self fetchEventsFirstPage];
}

- (void) updateTitleView {
    if (!self.groupName) self.groupName = [[Profile user] groupName];
    UIButton *schoolButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [schoolButton setTitle:self.groupName forState:UIControlStateNormal];
    [schoolButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [schoolButton addTarget:self action:@selector(showSchools) forControlEvents:UIControlEventTouchUpInside];
    schoolButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  
    CGFloat fontSize = 20.0f;
    CGSize size;
    while (fontSize > 0.0f)
    {
        size = [self.groupName sizeWithAttributes:
                       @{NSFontAttributeName:[FontProperties scMediumFont:fontSize]}];
        //TODO: not use fixed length
        if (size.width <= 210) break;
        
        fontSize -= 2.0;
    }
    schoolButton.titleLabel.font = [FontProperties scMediumFont:fontSize];

    UIImageView *triangleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(size.width + 5, 0, 6, 5)];
    [schoolButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    triangleImageView.image = [UIImage imageNamed:@"whiteTriangle"];
    [schoolButton addSubview:triangleImageView];

    
    self.navigationItem.titleView = schoolButton;
}

- (void)showSchools {
    PeekViewController *peekViewController = [PeekViewController new];
    peekViewController.placesDelegate = self;
    [self presentViewController:peekViewController animated:YES completion:nil];
}

- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(cancelledAddEventTapped)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [_dimView addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    _ungoOutButton.enabled = YES;
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.2 animations:^{
        _placesTableView.transform = CGAffineTransformMakeTranslation(0, 0);
        _whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0,-50);
        _whereAreYouGoingView.alpha = 0;
        _dimView.alpha = 0;
    } completion:^(BOOL finished) {
        [_dimView removeFromSuperview];
    }];
    [self clearTextField];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == _whereAreYouGoingView) {
        return NO;
    }
    if (touch.view == _createButton) {
        [self createPressed];
    }
    return YES;
}

- (void)initializeWhereView {
    _placesTableView = [[UITableView alloc] initWithFrame: CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64) style: UITableViewStyleGrouped];

    _placesTableView.sectionHeaderHeight = 0;
    _placesTableView.sectionFooterHeight = 0;
    _placesTableView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:_placesTableView];
    _placesTableView.dataSource = self;
    _placesTableView.delegate = self;
    _placesTableView.showsVerticalScrollIndicator = NO;
    [_placesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    //[_placesTableView setSeparatorColor:UIColor.clearColor];
    [_placesTableView registerClass:[EventCell class] forCellReuseIdentifier:kEventCellName];
    [_placesTableView registerClass:[HighlightOldEventCell class] forCellReuseIdentifier:kHighlightOldEventCel];
    [_placesTableView registerClass:[OldEventShowHighlightsCell class] forCellReuseIdentifier:kOldEventShowHighlightsCellName];
    _placesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _yPositionOfWhereSubview = 280;
    [self addRefreshToScrollView];
    [self initializeGoingSomewhereElseButton];
    
}

- (void)chooseEvent:(NSNotification *)notification {
    if ([[Profile user] key]) {
        NSNumber *eventID = [[notification userInfo] valueForKey:@"eventID"];
        [self goOutToEventNumber:eventID];
    }
}

- (void)followPressed {
    if ([Profile user]) {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
        [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:[Profile user]] animated:YES];
    }
}

- (void)invitePressed {
    if ([[Profile user] attendingEventID]) {
        [self presentViewController:[[InviteViewController alloc] initWithEventName:[[Profile user] attendingEventName] andID:[[Profile user] attendingEventID]] animated:YES completion:nil];
    }

}

- (void) goHerePressed:(id)sender {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Places", @"Go Here Source", nil];
    [EventAnalytics tagEvent:@"Go Here" withDetails:options];
    shouldAnimate = YES;
    _whereAreYouGoingTextField.text = @"";
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    [self addProfileUserToEventWithNumber:(int)buttonSender.tag];
    [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self goOutToEventNumber:[NSNumber numberWithInt:(int)buttonSender.tag]];
//    if ([self shouldPresentGrowthHack]) [self presentGrowthHack];
}

- (void)goOutToEventNumber:(NSNumber*)eventID {
    User *profileUser = [Profile user];
    [profileUser setIsGoingOut:YES];
    [profileUser setAttendingEventID:eventID];
    [self updateTitleView];
    [[Profile user] setEventID:eventID];
    [Network postGoingToEventNumber:[eventID intValue]];
    [self fetchEventsFirstPage];
}

- (void)initializeGoingSomewhereElseButton {
    int sizeOfButton = [[UIScreen mainScreen] bounds].size.width/6.4;
    _goingSomewhereButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - sizeOfButton - 10, self.view.frame.size.height - sizeOfButton - 10, sizeOfButton, sizeOfButton)];
    [_goingSomewhereButton addTarget:self action:@selector(goingSomewhereElsePressed) forControlEvents:UIControlEventTouchUpInside];
    _goingSomewhereButton.backgroundColor = [FontProperties getBlueColor];
    _goingSomewhereButton.layer.borderWidth = 1.0f;
    _goingSomewhereButton.layer.borderColor = [UIColor clearColor].CGColor;
    _goingSomewhereButton.layer.cornerRadius = sizeOfButton/2;
    _goingSomewhereButton.layer.shadowColor = [UIColor blackColor].CGColor;
    _goingSomewhereButton.layer.shadowOpacity = 0.4f;
    _goingSomewhereButton.layer.shadowRadius = 5.0f;
    _goingSomewhereButton.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    
    [self.view addSubview:_goingSomewhereButton];
    [self.view bringSubviewToFront:_goingSomewhereButton];
    
    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(sizeOfButton/2 - 7, sizeOfButton/2 - 7, 15, 15)];
    sendOvalImageView.image = [UIImage imageNamed:@"plusStoryButton"];
    [_goingSomewhereButton addSubview:sendOvalImageView];
}

- (void) goingSomewhereElsePressed {
    [self scrollUp];

    if (!_dimView) {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *bgImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
        
        CGFloat yOrigin = self.whereAreYouGoingTextField.frame.origin.y + self.whereAreYouGoingTextField.frame.size.height;
        _dimView = [[UIView alloc] initWithFrame: CGRectMake(0, yOrigin, self.view.frame.size.width, self.view.frame.size.height - self.whereAreYouGoingTextField.frame.size.height)];
        
        
        UIImageView *blurredView = [[UIImageView alloc] initWithFrame: CGRectMake(_dimView.bounds.origin.x, _dimView.bounds.origin.y, _dimView.bounds.size.width, _dimView.bounds.size.height)];
        [blurredView setImage: [bgImage blurredImageWithRadius: 20.0f iterations: 4 tintColor: [UIColor blackColor]]];
        
        [_dimView addSubview: blurredView];
        
        UIView *overlay = [[UIView alloc] initWithFrame: _dimView.bounds];
        overlay.backgroundColor = [UIColor blackColor];
        overlay.alpha = 0.5f;
        
        [_dimView addSubview: overlay];
        
        _dimView.alpha = 0;
    }
    
    if ([self.view.subviews indexOfObject: _dimView] == NSNotFound) {
        [self.view addSubview: _dimView];
        [self initializeTapHandler];
    }
    
    [self showWhereAreYouGoingView];

    
    [UIView animateWithDuration: 0.2 animations:^{
        _dimView.alpha = 1.0;
        
        self.navigationItem.titleView.alpha = 0.0f;
        self.navigationItem.leftBarButtonItem.customView.alpha = 0.0f;
        self.navigationItem.rightBarButtonItem.customView.alpha = 0.0f;
        
        [_whereAreYouGoingTextField becomeFirstResponder];
        self.whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0, 50);
        //_placesTableView.transform = CGAffineTransformMakeTranslation(0, 50);
        self.whereAreYouGoingView.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        
        [self.navigationItem setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Cancel" style: UIBarButtonItemStylePlain target: self action: @selector(cancelledAddEventTapped)] animated: NO];
        
        [self.navigationItem setRightBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Create" style: UIBarButtonItemStylePlain target: self action: @selector(createPressed)] animated: NO];
        
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

        //[self dismissKeyboard];
        _ungoOutButton.enabled = NO;
        _placesTableView.userInteractionEnabled = NO;
        [self textFieldDidChange:_whereAreYouGoingTextField];
    }];
    



}

- (void) cancelledAddEventTapped {
    [self initializeNavigationBar];
    [self dismissKeyboard];
}

- (void)profileSegue {
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: [Profile user]];
    fancyProfileViewController.eventsParty = self.eventsParty;
    [self.navigationController pushViewController: fancyProfileViewController animated: YES];
}

- (void)choseProfile:(id)sender {
    _scrollViewPoint = _scrollViewSender.contentOffset;
    _scrollViewSender = (UIScrollView *)[sender superview];
    _scrollViewSender.contentOffset = CGPointMake(_scrollViewSender.contentSize.width - 245, 0);
    _scrollViewSender.scrollEnabled = NO;
    UITableViewCell *cellSender = (UITableViewCell *)[_scrollViewSender superview];

    UIViewController *newViewController = [[UIViewController alloc] init];
    newViewController.view = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:cellSender]];
    newViewController.view.backgroundColor = [UIColor whiteColor];

    UIImageView *privateLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 120, 300, 15)];
    privateLineImageView.image = [UIImage imageNamed:@"privateLine"];
    [newViewController.view addSubview:privateLineImageView];
    
    UILabel *privateExplanation = [[UILabel alloc] initWithFrame:CGRectMake(30, 130, newViewController.view.frame.size.width -  60, 80)];
    privateExplanation.text = @"These users are private.\n Go here to meet them in person!";
    privateExplanation.font = [FontProperties getTitleFont];
    privateExplanation.textAlignment = NSTextAlignmentCenter;
    privateExplanation.numberOfLines = 0;
    privateExplanation.lineBreakMode = NSLineBreakByWordWrapping;
    [newViewController.view addSubview:privateExplanation];
    
    UIButton *gotItButton = [[UIButton alloc] initWithFrame:CGRectMake(108, 210, 100, 30)];
    [gotItButton setTitle:@"Got It" forState:UIControlStateNormal];
    [gotItButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    gotItButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    gotItButton.titleLabel.font = [FontProperties getTitleFont];
    gotItButton.backgroundColor = RGB(56, 56, 56);
    gotItButton.layer.cornerRadius = 5;
    gotItButton.layer.borderWidth = 1;
    [gotItButton addTarget:self action:@selector(gotItPressed) forControlEvents:UIControlEventTouchUpInside];
    [newViewController.view addSubview:gotItButton];
    
    [[RWBlurPopover instance] presentViewController:newViewController withOrigin:200 andHeight:250];
}

- (void) gotItPressed {
    _scrollViewSender.contentOffset = _scrollViewPoint;
    _scrollViewSender.scrollEnabled = YES;
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void){}];
}

#pragma mark - Where Are You Going? View and Delegate

- (void)showWhereAreYouGoingView {
    
    _whereAreYouGoingView = [[UIView alloc] initWithFrame:CGRectMake(0, 14, self.view.frame.size.width, 50)];
    _whereAreYouGoingView.backgroundColor = [UIColor whiteColor];
    _whereAreYouGoingView.alpha = 0;
    
    [self.view addSubview:_whereAreYouGoingView];
    
    _whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, _whereAreYouGoingView.frame.size.width - 10, 50)];
    _whereAreYouGoingTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Where are you going?" attributes:@{NSForegroundColorAttributeName:RGBAlpha(122, 193, 226, 0.5)}];
    _whereAreYouGoingTextField.font = [FontProperties mediumFont:18.0f];
    _whereAreYouGoingTextField.textColor = [FontProperties getBlueColor];
    [[UITextField appearance] setTintColor:[FontProperties getBlueColor]];
    _whereAreYouGoingTextField.delegate = self;
    [_whereAreYouGoingTextField addTarget:self
                                   action:@selector(textFieldDidChange:)
                         forControlEvents:UIControlEventEditingChanged];
    _whereAreYouGoingTextField.returnKeyType = UIReturnKeyDone;
    
    [_whereAreYouGoingView addSubview:_whereAreYouGoingTextField];
    
    //[self addCreateButtonToTextField];
    
//    _clearButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 25 - 100, _whereAreYouGoingView.frame.size.height/2 - 9, 25, 25)];
//    [_clearButton addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clearButton"]]];
//    [_clearButton addTarget:self action:@selector(clearTextField) forControlEvents:UIControlEventTouchUpInside];
    //[_whereAreYouGoingView addSubview:_clearButton];
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, _whereAreYouGoingView.frame.size.height - 1, _whereAreYouGoingView.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [[FontProperties getBlueColor] colorWithAlphaComponent: 0.5f].CGColor;
    [_whereAreYouGoingView.layer addSublayer:bottomBorder];
}

- (void)clearTextField {
    _placesTableView.userInteractionEnabled = YES;
    _whereAreYouGoingTextField.text = @"";
    [self textFieldDidChange:_whereAreYouGoingTextField];
}


- (void) addCreateButtonToTextField {
    _createButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 90, _whereAreYouGoingView.frame.size.height/2 - 12, 80, 25)];
    [_createButton setTitle:@"CREATE" forState:UIControlStateNormal];
    _createButton.isAccessibilityElement = YES;
    _createButton.accessibilityLabel = @"Create";
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _createButton.backgroundColor = [FontProperties getBlueColor];
    [_createButton addTarget:self action:@selector(createPressed) forControlEvents:UIControlEventTouchUpInside];
    _createButton.titleLabel.font = [FontProperties scMediumFont:12.0f];
    _createButton.layer.cornerRadius = 5;
    _createButton.layer.borderWidth = 1;
    _createButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [_whereAreYouGoingView addSubview:_createButton];
    [_whereAreYouGoingView bringSubviewToFront:_createButton];
}

- (void)createPressed {
    if ([_whereAreYouGoingTextField.text length] != 0) {
        [self createEventWithName:_whereAreYouGoingTextField.text];
        [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        NSNumber *eventID = [Network createEventWithName:_whereAreYouGoingTextField.text];
        [self updateTitleView];
        [self fetchEventsFirstPage];
        [Network postGoingToEventNumber:[eventID intValue]];
        User *profileUser = [Profile user];
        [profileUser setIsAttending:YES];
        [profileUser setIsGoingOut:YES];
        [profileUser setAttendingEventID:eventID];
//        if ([self shouldPresentGrowthHack]) [self presentGrowthHack];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    [_filteredContentParty removeAllObjects];
    _filteredPartyUserArray = [[NSMutableArray alloc] init];
    if([textField.text length] != 0) {
        _isSearching = YES;
        //_createButton.hidden = NO;
        //_clearButton.hidden = NO;
        [self searchTableList:textField.text];
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
    }
    else {
        _isSearching = NO;
        _createButton.hidden = YES;
        _clearButton.hidden = YES;
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

    }

    [_placesTableView reloadData];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self createPressed];
    return YES;
}

- (void)searchTableList:(NSString *)searchString {
    NSArray *contentNameArray = [_contentParty getNameArray];
    NSArray *searchArray = [searchString componentsSeparatedByString:@" "];
    if ([searchArray count] > 1) {
        for (int i = 0; i < [contentNameArray count]; i++) {
            NSString *tempStr = [contentNameArray objectAtIndex:i];
            NSComparisonResult result = [tempStr compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
            if (result == NSOrderedSame && ![[_filteredContentParty getNameArray] containsObject:tempStr]) {
                [_filteredContentParty addObject: [[[_contentParty getObjectArray] objectAtIndex:i] dictionary]];
                [_filteredPartyUserArray addObject:[_partyUserArray objectAtIndex:i]];
            }
        }
    }
    else {
        for (int i = 0; i < [contentNameArray count]; i++) {
            NSString *tempStr = [contentNameArray objectAtIndex:i];
            NSArray *firstAndLastNameArray = [tempStr componentsSeparatedByString:@" "];
            for (NSString *firstOrLastName in firstAndLastNameArray) {
                NSComparisonResult result = [firstOrLastName compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
                if (result == NSOrderedSame && ![[_filteredContentParty getNameArray] containsObject:tempStr]) {
                    [_filteredContentParty addObject: [[[_contentParty getObjectArray] objectAtIndex:i] dictionary]];
                    [_filteredPartyUserArray addObject:[_partyUserArray objectAtIndex:i]];
                }
            }
        }
    }

}

#pragma mark - Tablew View Data Source
#define kTodaySection 0
#define kHighlightsEmptySection 1


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self shouldShowHighlights]) {
        //[Today section] [Button show highlights]
        return 1 + 1 + 1;
    }
    else if (self.pastDays.count > 0) {
        //[Today section] [Highlighs section] (really just space for a header) + pastDays sections
        return 1 + 1 + self.pastDays.count;
    }
    //just today section
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kTodaySection) {
        if (_isSearching) {
            return [_filteredContentParty count];
        }
        else {
            int hasNextPage = ([_eventsParty hasNextPage] ? 1 : 0);
            return [_contentParty count] + hasNextPage;
        }
    }
    else if (section == kHighlightsEmptySection) {
        return 0;
    }
    else if ([self shouldShowHighlights] && section > 1) {
        return 1;
    }
    else if (self.pastDays.count > 0 && section > 1) {
        NSString *day = [self.pastDays objectAtIndex: section - 2];
        return ((NSArray *)[self.dayToEventObjArray objectForKey: day]).count;
    }

    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kTodaySection) { //today section
        return [TodayHeader height];
    }
    else if (section == kHighlightsEmptySection) { //highlights section seperator
        return [HighlightsHeader height];
    }
    else if ([self shouldShowHighlights] && section > 1) {
        return 0;
    }
    else if (self.pastDays.count > 0 && section > 1) { //past day headers
        return [PastDayHeader height: (section - 2 == 0)];
    }
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kTodaySection) {
        return [TodayHeader initWithDay: [NSDate date]];
    }
    else if (section == kHighlightsEmptySection) {
        return [HighlightsHeader init];
    }
    else if ([self shouldShowHighlights] && section > 1) {
        return 0;
    }
    else if (self.pastDays.count > 0 && section > 1) { //past day headers
        return [PastDayHeader initWithDay: [self.pastDays objectAtIndex: section - 2] isFirst: (section - 2) == 0];
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == kTodaySection) {
        self.goElsewhereView = [GoOutNewPlaceHeader init];
        if ([_contentParty count] > 0) [self.goElsewhereView setupWithMoreThanOneEvent:YES];
        else [self.goElsewhereView setupWithMoreThanOneEvent:NO];
        [self.goElsewhereView.addEventButton addTarget: self action: @selector(goingSomewhereElsePressed) forControlEvents: UIControlEventTouchUpInside];
        [self shouldShowCreateButton];
        return self.goElsewhereView;
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == kTodaySection) {
        return [GoOutNewPlaceHeader height];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == kTodaySection) {
        return sizeOfEachCell;

    }
    else if (indexPath.section == kHighlightsEmptySection) {
        return 0;
    }
    else if ([self shouldShowHighlights] && indexPath.section > 1) {
        return [OldEventShowHighlightsCell height];
    }
    else if (self.pastDays.count > 0 && indexPath.section > 1) { //past day rows
        
        NSString *day = [self.pastDays objectAtIndex: indexPath.section - 2];
        NSArray *eventObjectArray = ((NSArray *)[self.dayToEventObjArray objectForKey: day]);

        Event *event = (Event *)[eventObjectArray objectAtIndex:[indexPath row]];
        if ([event containsHighlight]) {
            return 215;
        }
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kTodaySection) {
        EventCell *cell = [tableView dequeueReusableCellWithIdentifier:kEventCellName];

        cell.placesDelegate = self;
        if (_isSearching) {
            if (indexPath.row == [_filteredContentParty count]) {
                return cell;
            }
        }
        else {
            if (indexPath.row == [_contentParty  count]) {
                [self fetchEvents];
                return cell;
            }
        }
        
        Event *event;
        if (_isSearching) {
            int sizeOfArray = (int)[_filteredContentParty  count];
            if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
            event = [[Event alloc] initWithDictionary:[[_filteredContentParty getObjectArray] objectAtIndex:[indexPath row]]];
        }
        else {
            int sizeOfArray = (int)[_contentParty count];
            if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
            event = [[_contentParty getObjectArray] objectAtIndex:[indexPath row]];
        }
        cell.event = event;
        if (self.groupNumberID) {
            cell.eventPeopleScrollView.groupID = self.groupNumberID;
        }
        else {
            cell.eventPeopleScrollView.groupID = nil;
        }
        cell.eventPeopleScrollView.placesDelegate = self;
        if ([[self.eventOffsetDictionary allKeys] containsObject:[[event eventID] stringValue]] && self.visitedProfile) {
            cell.eventPeopleScrollView.contentOffset = CGPointMake([(NSNumber *)[self.eventOffsetDictionary objectForKey:[[event eventID] stringValue]] intValue],0);
        }
        [cell updateUI];
        if (![[[event dictionary] objectForKey:@"is_read"] boolValue] &&
            [[[event dictionary] objectForKey:@"num_messages"] intValue] > 0) {
            cell.chatBubbleImageView.hidden = NO;
            cell.chatBubbleImageView.image = [UIImage  imageNamed:@"cameraBubble"];
            cell.postStoryImageView.image = [UIImage imageNamed:@"orangePostStory"];
        }
        else if ( [[[event dictionary] objectForKey:@"num_messages"] intValue] > 0) {
            cell.chatBubbleImageView.hidden = NO;
            cell.chatBubbleImageView.image = [UIImage  imageNamed:@"blueCameraBubble"];
            cell.postStoryImageView.image = [UIImage imageNamed:@"postStory"];
        }
        else {
            cell.chatBubbleImageView.hidden = YES;
            cell.postStoryImageView.image = [UIImage imageNamed:@"postStory"];
        }
        return cell;
    }
    else if (indexPath.section == kHighlightsEmptySection) {
        return nil;
    }
    else if ([self shouldShowHighlights] && indexPath.section > 1) {
        OldEventShowHighlightsCell *cell = [tableView dequeueReusableCellWithIdentifier:kOldEventShowHighlightsCellName];
        cell.placesDelegate = self;
        return cell;
    }
    else if (self.pastDays.count > 0 && indexPath.section > 1) { //past day rows
        
        NSString *day = [self.pastDays objectAtIndex: indexPath.section - 2];
        NSArray *eventObjectArray = ((NSArray *)[self.dayToEventObjArray objectForKey: day]);
        
        Event *event = (Event *)[eventObjectArray objectAtIndex:[indexPath row]];
        if ([event containsHighlight]) {
            HighlightOldEventCell *cell = [tableView dequeueReusableCellWithIdentifier:kHighlightOldEventCel];
            cell.event = event;
            cell.placesDelegate = self;
            cell.oldEventLabel.text = [event name];
            NSString *contentURL = [[[event dictionary] objectForKey:@"highlight"] objectForKey:@"media"];
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
            __weak HighlightOldEventCell *weakCell = cell;
            [cell.highlightImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (image) {
                    weakCell.highlightImageView.image = [self convertImageToGrayScale:image];
                }
            }];
            return cell;
        }
      
    }
    
    return nil;
  
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    

    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if (view == self.goElsewhereView) {
        isLoaded = YES;
    }
}

- (BOOL) shouldShowHighlights {
    BOOL shownHighlights =  [[NSUserDefaults standardUserDefaults] boolForKey: @"shownHighlights"];
    return !shownHighlights && self.pastDays.count;
}


#pragma mark - Image helper

- (UIImage *)rotateImage:(UIImage *)image {
    
    int kMaxResolution = 320; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

- (UIImage *)convertImageToGrayScale:(UIImage *)image {
    
    image = [self rotateImage:image];//THIS IS WHERE REPAIR THE ROTATION PROBLEM
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, (int)kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    // Return the new grayscale image
    return newImage;
}

#pragma mark - PlacesDelegate

- (void)showHighlights {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shownHighlights"];
    [_placesTableView reloadData];
}

- (void)showUser:(User *)user {
    shouldReloadEvents = NO;
    
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: user];
    if (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        fancyProfileViewController.userState = OTHER_SCHOOL_USER;
    }
    self.visitedProfile = YES;
    [self.navigationController pushViewController: fancyProfileViewController animated: YES];

}

- (void)showConversationForEvent:(Event *)event {
    NSString *queryString = [NSString stringWithFormat:@"eventmessages/?event=%@&limit=100", [event eventID]];
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:queryString
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{                                            NSMutableArray *eventMessages = [NSMutableArray arrayWithArray:(NSArray *)[jsonResponse objectForKey:@"objects"]];
                                    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                    int eventIndex = [self indexOfEvent:event inArray:eventMessages];
                                    EventConversationViewController *conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
                                    conversationViewController.event = event;
                                    conversationViewController.index = @(eventIndex);
                                    conversationViewController.eventMessages = eventMessages;
                                    [self presentViewController:conversationViewController animated:YES completion:nil];
                                });
                            }];
}

- (int)indexOfEvent:(Event *)event inArray:(NSMutableArray *)eventMessages {
    NSDictionary *highlightEventMessage = [[event dictionary] objectForKey:@"highlight"];
    for (int i = 0; i < [eventMessages count]; i++) {
        NSDictionary *eventMessage = [eventMessages objectAtIndex:i];
        if ([[eventMessage objectForKey:@"id"] isEqualToNumber:[highlightEventMessage objectForKey:@"id"]]) {
            return i;
        }
    }
    return 0;
}

- (void)showStoryForEvent:(Event*)event {
    
    EventStoryViewController *eventStoryController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventStoryViewController"];
    eventStoryController.placesDelegate = self;
    eventStoryController.event = event;
    if (self.groupNumberID) eventStoryController.groupNumberID = self.groupNumberID;
    [self.navigationController pushViewController:eventStoryController animated:YES];
}

- (void)setGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName {
    self.eventOffsetDictionary = [NSMutableDictionary new];
    self.groupNumberID = groupID;
    self.groupName = groupName;
    [self updateTitleView];
    [self fetchEventsFirstPage];
}

- (int)createUniqueIndexFromUserIndex:(int)userIndex andEventIndex:(int)eventIndex {
    int numberOfEvents = (int)[_eventsParty count];
    return numberOfEvents * userIndex + eventIndex;
}

- (void)updateEvent:(Event *)newEvent {
    for (int i = 0 ; i < [_contentParty count]; i++) {
        Event *event = [[_contentParty getObjectArray] objectAtIndex:i];
        if ([[event eventID] isEqualToNumber:[newEvent eventID]]) {
            [_contentParty replaceObjectAtIndex:i withObject:newEvent];
            break;
        }
    }
}

- (NSDictionary *)getUserIndexAndEventIndexFromUniqueIndex:(int)uniqueIndex {
    int userIndex, eventIndex;
    int numberOfEvents = (int)[_eventsParty count];
    userIndex = uniqueIndex/numberOfEvents;
    eventIndex = uniqueIndex - userIndex * numberOfEvents;
    return @{@"userIndex": [NSNumber numberWithInt:userIndex], @"eventIndex":[NSNumber numberWithInt:eventIndex]};
}



#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != _placesTableView) {
        if (scrollView.contentOffset.x + self.view.frame.size.width >= scrollView.contentSize.width - sizeOfEachImage && !fetchingEventAttendees) {
            fetchingEventAttendees = YES;
            [self fetchEventAttendeesAsynchronousForEvent:(int)scrollView.tag];
        }
        
    }
    else if (scrollView == _placesTableView) {
        // convert label frame
        CGRect comparisonFrame = [scrollView convertRect: self.goElsewhereView.frame toView:self.view];
        // check if label is contained in self.view
        
        CGRect viewFrame = self.view.frame;
        BOOL isContainedInView = CGRectContainsRect(viewFrame, comparisonFrame);
        
        if (!self.goElsewhereView) {
            return;
        }
        if (![self shouldShowCreateButton]) {
            return;
        }
//
        if (isContainedInView && self.goingSomewhereButton.hidden == NO && isLoaded) {
            self.goingSomewhereButton.hidden = YES;
            self.goElsewhereView.plusButton.hidden = NO;
        }
        else if (isContainedInView == NO && self.goingSomewhereButton.hidden == YES) {
            self.goingSomewhereButton.alpha = 0;
            self.goingSomewhereButton.transform = CGAffineTransformMakeScale(0, 0);
            self.goingSomewhereButton.hidden = NO;
            self.goElsewhereView.plusButton.hidden = YES;

            [UIView animateWithDuration:0.2f delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
                self.goingSomewhereButton.alpha = 1;
                self.goingSomewhereButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
                
                
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.05f delay: 0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.goingSomewhereButton.transform = CGAffineTransformIdentity;
                    
                } completion:^(BOOL finished) {
                }];
            }];
        }
    }
}

#pragma mark - Network Asynchronous Functions

- (void) fetchEventsFirstPage {
    page = @1;
    [self fetchUserInfo];
    [self fetchEvents];
}

- (void) fetchEvents {
    
    if (!fetchingEventAttendees && [[Profile user] key]) {
        fetchingEventAttendees = YES;
        if (_spinnerAtCenter) [WiGoSpinnerView addDancingGToCenterView:self.view];
        NSString *queryString;
        if (self.groupNumberID) {
             queryString = [NSString stringWithFormat:@"events/?group=%@&page=%@&attendees_limit=10", [self.groupNumberID stringValue], [page stringValue]];
        }
        else {
            if (![page isEqualToNumber:@1] && [_eventsParty nextPageString]) {
                queryString = [_eventsParty nextPageString];
            }
            else {
                queryString = [NSString stringWithFormat:@"events/?page=%@&attendees_limit=10", [page stringValue]];
            }

        }
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            if ([page isEqualToNumber:@1]) {
                numberOfFetchedParties = 0;
                _eventsParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
                _oldEventsParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
                _contentParty = _eventsParty;
                _filteredContentParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
                
                self.pastDays = [[NSMutableArray alloc] init];
                self.dayToEventObjArray = [[NSMutableDictionary alloc] init];
            }
            NSArray *events = [jsonResponse objectForKey:@"objects"];
            NSDictionary *separatedEvents = [self separateEvents:events];
            NSArray *oldEvents = [separatedEvents objectForKey:@"oldEvents"];
            NSArray *newEvents = [separatedEvents objectForKey:@"newEvents"];
            [self getFirstIndexOfSuggestedEvent:events];
            [_eventsParty addObjectsFromArray:newEvents];
            
            //add old events to dictionary
            [_oldEventsParty addObjectsFromArray:oldEvents];
            
            Party *newOldEventsParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
            [newOldEventsParty addObjectsFromArray: oldEvents];
            
            for (Event *event in [newOldEventsParty getObjectArray]) {
                NSString *eventDate = [event expiresDate];
                if ([self.pastDays indexOfObject: eventDate] == NSNotFound) {
                    [self.pastDays addObject: eventDate];
                    [self.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                }
                
                [[self.dayToEventObjArray objectForKey: eventDate] addObject: event];
            }
            
            
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_eventsParty addMetaInfo:metaDictionary];
            [self fillEventAttendees];
            page = @([page intValue] + 1);
            [eventPageArray removeAllObjects];
            for (int i = 0; i < [_eventsParty count]; i++) {
                [eventPageArray addObject:@2];
            }
            [self fetchedOneParty];
            fetchingEventAttendees = NO;
        }];
    }
}

- (NSDictionary *)separateEvents:(NSArray *)events {
    
    NSMutableArray *mutableOldEvents = [NSMutableArray new];
    NSMutableArray *newEvents = [NSMutableArray new];
    NSIndexSet *indexSet = [events indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *eventDictionary = (NSDictionary *)obj;
        if ([[eventDictionary objectForKey:@"is_expired"] boolValue]) {
            return YES;
        }
        else return NO;
    }];
    for (int i = 0; i < [events count]; i++) {
        if ([indexSet containsIndex:(NSUInteger)i]) {
            [mutableOldEvents addObject:[events objectAtIndex:i]];
        }
        else {
            [newEvents addObject:[events objectAtIndex:i]];
        }
    }
    return @{@"oldEvents": [NSArray arrayWithArray:mutableOldEvents],
             @"newEvents": [NSArray arrayWithArray:newEvents]
             };
}

- (void)getFirstIndexOfSuggestedEvent:(NSArray *)events {
    NSArray *arrayOfIDs = [events valueForKey:@"id"];
    NSUInteger index = [arrayOfIDs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *eventID = (NSNumber *)obj;
        if ([eventID intValue] < 0) {
            return YES;
        }
        else return NO;
    }];
    
    if (index != NSNotFound) firstIndexOfNegativeEvent = -1;
    firstIndexOfNegativeEvent = (int)index;
}

- (void)fillEventAttendees {
    _partyUserArray =  [[NSMutableArray alloc] init];
    for (int i = 0; i < [_eventsParty count]; i++) {
        Event *event = [[_eventsParty getObjectArray] objectAtIndex:i];
        NSArray *eventAttendeesArray = [event getEventAttendees];
        Party *partyUser = [[Party alloc] init];
        for (int j = 0; j < [eventAttendeesArray count]; j++) {
            NSDictionary *eventAttendee = [eventAttendeesArray objectAtIndex:j];
            NSDictionary *userDictionary = [eventAttendee objectForKey:@"user"];
            User *user;
           
            if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                    user = [Profile user];
                }
                else {
                    user = [[User alloc] initWithDictionary:userDictionary];
                }
            }
            if ([[eventAttendee allKeys] containsObject:@"event_owner"]) {
                [user setIsEventOwner:[[eventAttendee objectForKey:@"event_owner"] boolValue]];
            }
            [partyUser addObject:user];
        }
        [_partyUserArray addObject:partyUser];
    }
}

- (void)fetchEventAttendeesAsynchronousForEvent:(int)eventNumber {
    Event *event = [[_eventsParty getObjectArray] objectAtIndex:eventNumber];
    NSNumber *eventId = [event eventID];
    if (eventNumber < [eventPageArray count]) {
        NSNumber *pageNumberForEvent = [eventPageArray objectAtIndex:eventNumber];
        if ([pageNumberForEvent intValue] > 0) {
            if (!pageNumberForEvent)  pageNumberForEvent = @2;
            NSString *queryString = [NSString stringWithFormat:@"eventattendees/?event=%@&limit=10&page=%@", [eventId stringValue], [pageNumberForEvent stringValue]];
            NSDictionary *inputDictionary = @{@"i": [NSNumber numberWithInt:eventNumber], @"page": pageNumberForEvent};
            [Network queryAsynchronousAPI:queryString
                      withInputDictionary:(NSDictionary *)inputDictionary
                              withHandler:^(NSDictionary *resultInputDictionary, NSDictionary *jsonResponse, NSError *error) {
                                  dispatch_async(dispatch_get_main_queue(), ^(void){
                                      NSNumber *pageNumberForEvent = [resultInputDictionary objectForKey:@"page"];
                                      NSArray *eventAttendeesArray = [jsonResponse objectForKey:@"objects"];
                                      Party *partyUser = [_partyUserArray objectAtIndex:eventNumber];
                                      for (int j = 0; j < [eventAttendeesArray count]; j++) {
                                          NSDictionary *eventAttendee = [eventAttendeesArray objectAtIndex:j];
                                          NSDictionary *userDictionary = [eventAttendee objectForKey:@"user"];
                                          User *user;
                                          if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                                              if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                                                  user = [Profile user];
                                              }
                                              else {
                                                  user = [[User alloc] initWithDictionary:userDictionary];
                                              }
                                          }
                                          if ([user isEqualToUser:[Profile user]]) {
                                              User *profileUser = [Profile user];
                                              [profileUser setIsGoingOut:YES];
                                              [[Profile user] setEventID:eventId];
                                          }
                                          [partyUser addObject:user];
                                      }
                                      
                                      if ([eventAttendeesArray count] > 0) {
                                          pageNumberForEvent = @([pageNumberForEvent intValue] + 1);
                                          [_placesTableView beginUpdates];
                                          [_placesTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:eventNumber inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                                          [_placesTableView endUpdates];
                                      }
                                      else {
                                          pageNumberForEvent = @-1;
                                      }
                                      [eventPageArray replaceObjectAtIndex:eventNumber withObject:pageNumberForEvent];
                                      fetchingEventAttendees = NO;
                                  });
                              }];
        }
        else  fetchingEventAttendees = NO;
    }
    else fetchingEventAttendees = NO;
}

- (void)fetchedOneParty {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        _spinnerAtCenter ? [WiGoSpinnerView removeDancingGFromCenterView:self.view] : [_placesTableView didFinishPullToRefresh];
         _spinnerAtCenter = NO;
        _contentParty = _eventsParty;
        _filteredContentParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
        [self dismissKeyboard];

    });
}

- (void) fetchUserInfo {
    if ([[Profile user] key]) {
        [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ([[jsonResponse allKeys] containsObject:@"status"]) {
                    if (![[jsonResponse objectForKey:@"status"] isEqualToString:@"error"]) {
                        User *user = [[User alloc] initWithDictionary:jsonResponse];
                        [Profile setUser:user];
                        [self initializeNavigationBar];
                    }
                }
                else {
                    User *user = [[User alloc] initWithDictionary:jsonResponse];
                    [Profile setUser:user];
                    [self initializeNavigationBar];
                }
            });
        }];
    }
}

- (void) fetchIsThereNewPerson {
    if (!self.fetchingIsThereNewPerson && [[Profile user] key]) {
        self.fetchingIsThereNewPerson = YES;
        [Network queryAsynchronousAPI:@"users/?limit=1" withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
            NSArray *objects = [jsonResponse objectForKey:@"objects"];
            if ([objects isKindOfClass:[NSArray class]]) {
                User *lastUserJoined = [[User alloc] initWithDictionary:[objects objectAtIndex:0]];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    User *profileUser = [Profile user];
                    if (profileUser) {
                        NSNumber *lastUserRead = [profileUser lastUserRead];
                        NSNumber *lastUserJoinedNumber = (NSNumber *)[lastUserJoined objectForKey:@"id"];
                        [Profile setLastUserJoined:lastUserJoinedNumber];
                        [self.rightButton.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 8, 22, 17)];
                        imageView.image = [UIImage imageNamed:@"followPlusWhite"];
                        [self.rightButton addSubview:imageView];
                        
                        if ([lastUserRead intValue] < [lastUserJoinedNumber intValue]) {
                            self.redDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 3, 10, 10)];
                            self.redDotLabel.backgroundColor = [FontProperties getOrangeColor];
                            self.redDotLabel.layer.borderColor = [UIColor clearColor].CGColor;
                            self.redDotLabel.clipsToBounds = YES;
                            self.redDotLabel.layer.borderWidth = 3;
                            self.redDotLabel.layer.cornerRadius = 5;
                            [self.rightButton addSubview:self.redDotLabel];
                        }
                        else {
                            if (self.redDotLabel) [self.redDotLabel removeFromSuperview];
                        }
                    }
                    self.fetchingIsThereNewPerson = NO;
                });
            }
        }];
    }
}


#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    [WiGoSpinnerView addDancingGToUIScrollView:_placesTableView withHandler:^{
        _spinnerAtCenter = NO;
        [self fetchEventsFirstPage];
    }];
}

#pragma mark - Growth Hack
- (BOOL)shouldPresentGrowthHack {
    int numberOfTimesWentOut = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"numberOfTimesWentOut"];
    if (numberOfTimesWentOut == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"numberOfTimesWentOut"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return NO;
    }
    else if (numberOfTimesWentOut == 1) {
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"numberOfTimesWentOut"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
    return NO;
}

- (void)presentGrowthHack {
//    [[Profile user] setGrowthHackPresented];
//    [[Profile user] saveKeyAsynchronously:@"properties"];
//    CATransition* transition = [CATransition animation];
//    transition.duration = 1;
//    transition.type = kCATransitionFade;
//    transition.subtype = kCATransitionFromBottom;
//    [self.view.window.layer addAnimation:transition forKey:kCATransition];
//    [self presentViewController:[WigoConfirmationViewController new] animated:NO completion:nil];
}

- (void)presentContactsView {
    if (!presentedMobileContacts) {
        presentedMobileContacts = YES;
        [self presentViewController:[MobileContactsViewController new] animated:YES completion:nil];
    }
}

- (void)createEventWithName:(NSString *)eventName {
    Event *event = [[Event alloc] initWithDictionary:@{@"id": @-1, @"name": eventName, @"num_attending": @1}];
    [_eventsParty addObjectsFromArray:@[[event dictionary]]];
    Party *partyUser = [[Party alloc] initWithObjectType:USER_TYPE];
    [partyUser addObject:[Profile user]];
    [_partyUserArray addObject:partyUser];
    [_eventsParty exchangeObjectAtIndex:([_eventsParty count] - 1) withObjectAtIndex:0];
    [_partyUserArray exchangeObjectAtIndex:([_partyUserArray count] - 1) withObjectAtIndex:0];
    [self removeUserFromAnyOtherEvent:[Profile user]];
}

- (void)addProfileUserToEventWithNumber:(int)eventID {
    NSArray *arrayOfEvents = [_eventsParty getObjectArray];
    int index;
    for (int i = 0; i < [arrayOfEvents count]; i++) {
        Event *newEvent = [arrayOfEvents objectAtIndex:i];
        if ([[newEvent eventID] intValue] == eventID) {
            index = i;
            [self addUser:[Profile user] toEventAtIndex:(int)index];
            Event *event = [[_eventsParty getObjectArray] objectAtIndex:index];
            [[Profile user] setIsAttending:YES];
            [[Profile user] setIsGoingOut:YES];
            [[Profile user] setEventID:[event eventID]];
            [[Profile user] setAttendingEventID:[event eventID]];
            [newEvent setNumberAttending:@([[newEvent numberAttending] intValue] + 1)];
            [_eventsParty replaceObjectAtIndex:index withObject:newEvent];

            break;
        }
        
    }
    [_eventsParty exchangeObjectAtIndex:index withObjectAtIndex:0];
}

- (void)addUser:(User *)user toEventAtIndex:(int)index {
    Party *partyUser = [_partyUserArray objectAtIndex:index];
    [self removeUserFromAnyOtherEvent:user];
    [partyUser insertObject:user inObjectArrayAtIndex:0];
    [_partyUserArray replaceObjectAtIndex:index withObject:partyUser];
    [_partyUserArray exchangeObjectAtIndex:index withObjectAtIndex:0];
}


- (void)removeUserFromAnyOtherEvent:(User *)user {
    NSArray *arrayOfEvents = [_eventsParty getObjectArray];
    for (int i = 0; i < [arrayOfEvents count]; i++) {
        Event *event = [arrayOfEvents objectAtIndex:i];
        Party *partyUser = [_partyUserArray objectAtIndex:i];
        for (int j = 0; j < [partyUser count]; j++) {
            User *newUser = [[partyUser getObjectArray] objectAtIndex:j];
            if ([user isEqualToUser:newUser]) {
                [partyUser removeUser:newUser];
                [event setNumberAttending:@([[event numberAttending] intValue] - 1)];
                [_partyUserArray replaceObjectAtIndex:i withObject:partyUser];
            }
        }
    }
}

@end

@implementation EventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, sizeOfEachCell);
    self.contentView.frame = self.frame;
    self.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width - 75, 64)];
    self.eventNameLabel.numberOfLines = 2;
    self.eventNameLabel.font = [FontProperties mediumFont: 18];
    self.eventNameLabel.textColor = RGB(100, 173, 215);
    [self.contentView addSubview:self.eventNameLabel];
    
    self.chatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 48, 15, 20, 20)];
    self.chatBubbleImageView.image = [UIImage imageNamed:@"cameraBubble"];
    self.chatBubbleImageView.center = CGPointMake(self.chatBubbleImageView.center.x, self.eventNameLabel.center.y);
    self.chatBubbleImageView.hidden = YES;
    [self.contentView addSubview:self.chatBubbleImageView];
    
    self.postStoryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 24, 13, 9, 14)];
    self.postStoryImageView.center = CGPointMake(self.postStoryImageView.center.x, self.eventNameLabel.center.y);
    self.postStoryImageView.image = [UIImage imageNamed:@"postStory"];
    [self.contentView addSubview:self.postStoryImageView];

    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    self.eventPeopleScrollView.frame = CGRectMake(0, 64, self.frame.size.width, [EventPeopleScrollView containerHeight]);
    self.eventPeopleScrollView.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.eventPeopleScrollView];
    
    UIButton *eventFeedButton = [[UIButton alloc] initWithFrame:CGRectMake(self.eventNameLabel.frame.origin.x, self.eventNameLabel.frame.origin.y, self.frame.size.width - self.eventNameLabel.frame.origin.x, self.eventNameLabel.frame.size.height)];
    eventFeedButton.backgroundColor = [UIColor clearColor];
    [eventFeedButton addTarget: self action: @selector(showEventConversation) forControlEvents: UIControlEventTouchUpInside];
    [self.contentView addSubview: eventFeedButton];
    
    UILabel *lineSeparator = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 0.5f, self.frame.size.width, 0.5)];
    lineSeparator.backgroundColor = [[FontProperties getBlueColor] colorWithAlphaComponent: 0.4f];

    [self.contentView addSubview:lineSeparator];
}

- (void)updateUI {
    self.eventNameLabel.text = [self.event name];
    if (![[[self.event dictionary] objectForKey:@"is_read"] boolValue] && [self.event.numberOfMessages intValue] > 0) {
        self.chatBubbleImageView.hidden = NO;
        self.chatBubbleImageView.image = [UIImage imageNamed:@"cameraBubble"];
        self.chatNumberLabel.text = [NSString stringWithFormat:@"%@", [self.event.numberOfMessages stringValue]];
    }
    else if ([self.event.numberOfMessages intValue] > 0) {
        self.chatBubbleImageView.hidden = NO;
        self.chatBubbleImageView.image = [UIImage imageNamed:@"blueCameraBubble"];
    }
    else {
     self.chatBubbleImageView.hidden = YES;
    }
    self.eventPeopleScrollView.event = self.event;
    [self.eventPeopleScrollView updateUI];
}

- (void)setOffset:(int)offset forIndexPath:(NSIndexPath *)indexPath {
    
}


- (void)showEventConversation {
    [self.placesDelegate showStoryForEvent:self.event];
}

@end

#pragma mark - Headers
@implementation TodayHeader

+ (instancetype) initWithDay: (NSDate *) date {
    TodayHeader *header = [[TodayHeader alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [TodayHeader height])];
    header.date = date;
    [header setup];
    
    return header;
}
- (void) setup {
    self.backgroundColor = [UIColor whiteColor];
    
//    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate: self.date];
//    int weekday = (int)[comps weekday];
//    NSString *dayName = [[[NSDateFormatter alloc] init] weekdaySymbols][weekday - 1];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.width, 30)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties scMediumFont: 18.0f];
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.text = @"today";
    titleLabel.center = self.center;
    [self addSubview: titleLabel];
    
    UIView *lineView = [[UIView alloc] initWithFrame: CGRectMake(self.center.x - 50, self.frame.size.height - 0.5f, 100, 0.5f)];
    lineView.backgroundColor = [[FontProperties getBlueColor] colorWithAlphaComponent: 0.4f];
    [self addSubview: lineView];
    
}

+ (CGFloat) height {
    return 50;
}
@end

@implementation GoOutNewPlaceHeader

+ (instancetype) init {
    GoOutNewPlaceHeader *header = [[GoOutNewPlaceHeader alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [GoOutNewPlaceHeader height])];
    [header setup];
    
    return header;
}

- (void)setupWithMoreThanOneEvent:(BOOL)moreThanOneEvent {
    if (moreThanOneEvent) self.goSomewhereLabel.text = @"Go somewhere else";
    else self.goSomewhereLabel.text = @"Get today started";
}

- (void) setup {
    self.backgroundColor = RGB(241, 241, 241);
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
    backgroundView.image = [UIImage imageNamed: @"create_bg"];
    [self addSubview: backgroundView];
    
    
    int sizeOfButton = 40;
    self.plusButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - sizeOfButton - 20, 0, sizeOfButton, sizeOfButton)];
    self.plusButton.center = CGPointMake(self.plusButton.center.x, self.center.y - 2);
    
    self.plusButton.backgroundColor = [FontProperties getBlueColor];
    self.plusButton.layer.borderWidth = 1.0f;
    self.plusButton.layer.borderColor = [UIColor clearColor].CGColor;
    self.plusButton.layer.cornerRadius = sizeOfButton/2;

    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(sizeOfButton/2 - 6, sizeOfButton/2 - 6, 12, 12)];
    sendOvalImageView.image = [UIImage imageNamed:@"plusStoryButton"];
    [self.plusButton addSubview: sendOvalImageView];
    [self addSubview: self.plusButton];
    
    self.goSomewhereLabel = [[UILabel alloc] initWithFrame: CGRectMake(10, 0, self.frame.size.width, self.frame.size.height)];
    self.goSomewhereLabel.backgroundColor = [UIColor clearColor];
    self.goSomewhereLabel.textAlignment = NSTextAlignmentLeft;
    self.goSomewhereLabel.font = [FontProperties mediumFont: 20.0f];
    self.goSomewhereLabel.textColor = [FontProperties getBlueColor];
    self.goSomewhereLabel.text = @"Go somewhere else";
    self.goSomewhereLabel.center = CGPointMake(self.goSomewhereLabel.center.x, self.center.y - 4);
    [self addSubview: self.goSomewhereLabel];
    
    self.addEventButton = [[UIButton alloc] initWithFrame: self.bounds];
    self.addEventButton.backgroundColor = [UIColor clearColor];
    [self addSubview: self.addEventButton];
}

+ (CGFloat) height {
    return 70;
}

@end

@implementation HighlightsHeader

+ (instancetype) init {
    HighlightsHeader *header = [[HighlightsHeader alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [HighlightsHeader height])];
    [header setup];
    return header;
}

- (void) setup {
    self.backgroundColor = RGB(241, 241, 241);

}

+ (CGFloat)height {
    return 60.0f;
}

@end

@implementation PastDayHeader

+ (instancetype) initWithDay: (NSString *) dayText isFirst: (BOOL) isFirst {
    PastDayHeader *header = [[PastDayHeader alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [PastDayHeader height: isFirst])];
    header.isFirst = isFirst;
    header.day = dayText;
    [header setup];
    
    return header;
}
- (void) setup {
    self.backgroundColor = RGB(241, 241, 241);
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSDate *date = [dateFormat dateFromString:self.day];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate: date];
    int weekday = (int)[comps weekday];
    weekday -= 2;
    if (weekday < 0) weekday += 7;
    NSString *dayName = [dateFormat weekdaySymbols][weekday];
    
    UIView *lineView = [[UIView alloc] initWithFrame: CGRectMake(self.center.x - 50, 20, 100, 0.5f)];
    lineView.backgroundColor = RGB(210, 210, 210);
    [self addSubview: lineView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 20.5, self.frame.size.width, self.frame.size.height - 23.5)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties scMediumFont: 18.0f];
    titleLabel.textColor = RGB(210, 210, 210);
    titleLabel.text = [dayName lowercaseString];
    titleLabel.center = CGPointMake(self.center.x, titleLabel.center.y);
    [self addSubview: titleLabel];
    
    if (self.isFirst) {
        UILabel *highlights = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.width, 20)];
        highlights.backgroundColor = [UIColor clearColor];
        highlights.textAlignment = NSTextAlignmentCenter;
        highlights.font = [FontProperties scMediumFont: 13.0f];
        highlights.textColor = RGB(210, 210, 210);
        highlights.text = @"Highlights From Past";
        [self addSubview: highlights];
        
        lineView.center = CGPointMake(lineView.center.x, lineView.center.y + 5);
    }
}

+ (CGFloat) height: (BOOL) isFirst  {
    if (isFirst) {
        return 75;
    }
    return 70;
}
@end

@implementation HighlightOldEventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [HighlightOldEventCell height]);
    self.backgroundColor = RGB(241, 241, 241);
    

    //image view
    self.highlightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 1)];
    self.highlightImageView.clipsToBounds = YES;
    self.highlightImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.highlightImageView];
    
    //gradient, label, arrow
    UIImageView *gradientBackground = [[UIImageView alloc] initWithFrame: self.highlightImageView.bounds];
    gradientBackground.image = [UIImage imageNamed:@"backgroundGradient"];
    [self.contentView addSubview:gradientBackground];
    
    self.oldEventLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.highlightImageView.bounds.size.height - 50, self.frame.size.width - 75, 50)];
    self.oldEventLabel.numberOfLines = 2;
    self.oldEventLabel.textAlignment = NSTextAlignmentLeft;
    self.oldEventLabel.font = [FontProperties mediumFont: 18.0f];
    self.oldEventLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.oldEventLabel];
    
    UIImageView *postStoryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 20, 0, 10, 15)];
    postStoryImageView.image = [UIImage imageNamed:@"whiteForwardButton"];
    postStoryImageView.contentMode = UIViewContentModeScaleAspectFit;
    postStoryImageView.center = CGPointMake(postStoryImageView.center.x, self.oldEventLabel.center.y);
    [self.contentView addSubview:postStoryImageView];
    
    UIButton *conversationButton = [[UIButton alloc] initWithFrame:self.frame];
    [conversationButton addTarget:self action:@selector(loadConversation) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:conversationButton];
    
}

- (void)loadConversation {
    [self.placesDelegate showConversationForEvent:self.event];
}

+ (CGFloat) height {
    return 215;
}

@end

@implementation OldEventShowHighlightsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [OldEventShowHighlightsCell height]);
    self.backgroundColor = RGB(241, 241, 241);
    
    self.showHighlightsButton = [[UIButton alloc] initWithFrame:CGRectMake(45, 0, self.frame.size.width - 90, 64)];
    self.showHighlightsButton.backgroundColor = RGB(248, 248, 248);
    [self.showHighlightsButton setTitle:@"Show Past Highglights" forState:UIControlStateNormal];
    [self.showHighlightsButton setTitleColor:RGB(160, 160, 160) forState:UIControlStateNormal];
    self.showHighlightsButton.titleLabel.font = [FontProperties scMediumFont: 18];
    [self.showHighlightsButton addTarget:self action:@selector(showHighlightsPressed) forControlEvents:UIControlEventTouchUpInside];
    self.showHighlightsButton.layer.borderColor = RGB(210, 210, 210).CGColor;
    self.showHighlightsButton.layer.borderWidth = 1;
    self.showHighlightsButton.layer.cornerRadius = 8;
    [self.contentView addSubview:self.showHighlightsButton];
}

- (void)showHighlightsPressed {
    [self.placesDelegate showHighlights];
}

+ (CGFloat) height {
    return 150;
}


@end

