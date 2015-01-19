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
#import "ChatViewController.h"

//#define sizeOfEachCell [[UIScreen mainScreen] bounds].size.width/1.6
#define sizeOfEachCell 64 + [EventPeopleScrollView containerHeight] + 10

#define kEventCellName @"EventCell"
#define kHighlightOldEventCel @"HighlightOldEventCell"
#define kOldEventCellName @"OldEventCell"

#define kOldEventShowHighlightsCellName @"OldEventShowHighlightsCellName"

@interface PlacesViewController () {
    UIView *_dimView;
    BOOL isLoaded;

}

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *loadingIndicator;
@property (nonatomic, strong) UIView *whereAreYouGoingView;
@property (nonatomic, strong) UITextField *whereAreYouGoingTextField;

@property (nonatomic, assign) int tagInteger;

//@property NSMutableArray *filteredContentList;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, strong) NSMutableArray *placeSubviewArray;
@property (nonatomic, strong) UIImageView *searchIconImageView;
@property (nonatomic, strong) UIView *searchBarBorderView;

@property (nonatomic, strong) UIImageView *whereImageView;
@property (nonatomic, strong) UILabel *whereLabel;
@property (nonatomic, assign) int yPositionOfWhereSubview;

@property (nonatomic, strong) UITableView *placesTableView;

//private pressed
@property UIScrollView *scrollViewSender;
@property CGPoint scrollViewPoint;

// Events Summary
@property WGCollection *allEvents;
@property WGCollection *events;
@property WGCollection *oldEvents;
@property WGCollection *filteredEvents;
@property WGCollectionArray *userArray;

// Go OUT Button
@property UIButtonUngoOut *ungoOutButton;
@property BOOL spinnerAtCenter;

// Events By Days
@property (nonatomic, strong) NSMutableArray *pastDays;
@property (nonatomic, strong) NSMutableDictionary *dayToEventObjArray;

//Go Elsewhere
@property (nonatomic, strong) GoOutNewPlaceHeader *goElsewhereView;

@property (nonatomic, strong) SignViewController *signViewController;
@end


BOOL fetchingUserInfo;
BOOL shouldAnimate;
BOOL presentedMobileContacts;
NSNumber *page;
NSMutableArray *eventPageArray;
int sizeOfEachImage;
BOOL shouldReloadEvents;
int firstIndexOfNegativeEvent;
BOOL firstTimeLoading;
BOOL secondTimeFetchingUserInfo;

@implementation PlacesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeNotificationObservers];

    self.view.backgroundColor = UIColor.whiteColor;
    self.automaticallyAdjustsScrollViewInsets = NO;
    eventPageArray = [[NSMutableArray alloc] init];
    fetchingUserInfo = NO;
    self.fetchingEventAttendees = NO;
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
    

    _spinnerAtCenter = YES;
    [self initializeWhereView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *isPeeking = ([self isPeeking]) ? @"Yes" : @"No";

    [WGAnalytics tagEvent:@"Where View" withDetails: @{ @"isPeeking": isPeeking }];

    self.navigationController.navigationBar.barTintColor = RGB(100, 173, 215);
    [self.navigationController.navigationBar setBackgroundImage:[self imageWithColor:RGB(100, 173, 215)] forBarMetrics:UIBarMetricsDefault];

    [self initializeNavigationBar];
    [_placesTableView reloadData];

    if ([WGProfile currentUser].key) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"presentPush" object:nil];
    }
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    [self.navigationController.navigationBar setBackgroundImage:[self imageWithColor:UIColor.whiteColor] forBarMetrics:UIBarMetricsDefault];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initializeFlashScreen];

    [self.view endEditing:YES];
    if (shouldReloadEvents) {
        [self fetchEventsFirstPage];
    } else {
        shouldReloadEvents = YES;
    }
    [self fetchUserInfo];
    [self shouldShowCreateButton];
    [self showOnlyOnePlusButton];
}

- (BOOL) shouldShowCreateButton {
    if ([self isPeeking]) {
        self.goElsewhereView.hidden = YES;
        self.goElsewhereView.plusButton.enabled = NO;
        self.goingSomewhereButton.hidden = YES;
        self.goingSomewhereButton.enabled = NO;
        return NO;
    } else {
        self.goElsewhereView.hidden = NO;
        self.goElsewhereView.plusButton.enabled = YES;
        self.goingSomewhereButton.enabled = YES;
        return YES;
    }
}

- (BOOL) isPeeking {
    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
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
    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
        CGRect profileFrame = CGRectMake(3, 0, 30, 30);
        UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        [profileImageView setImageWithURL:WGProfile.currentUser.coverImageURL imageArea:WGProfile.currentUser.coverImageArea];
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
        if ([[WGProfile currentUser].numUnreadNotifications intValue] > 0) {
            self.leftRedDotLabel.hidden = NO;
        } else {
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
        
        [self.rightButton.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        UIImageView *followPlusWhiteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 8, 22, 17)];
        followPlusWhiteImageView.image = [UIImage imageNamed:@"followPlusWhite"];
        [self.rightButton addSubview:followPlusWhiteImageView];

        if ([[WGProfile currentUser].numUnreadUsers intValue] > 0) {
            self.redDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 3, 10, 10)];
            self.redDotLabel.backgroundColor = [FontProperties getOrangeColor];
            self.redDotLabel.layer.borderColor = [UIColor clearColor].CGColor;
            self.redDotLabel.clipsToBounds = YES;
            self.redDotLabel.layer.borderWidth = 3;
            self.redDotLabel.layer.cornerRadius = 5;
            [self.rightButton addSubview:self.redDotLabel];
        } else {
            if (self.redDotLabel) [self.redDotLabel removeFromSuperview];
        }

        
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }

    [self updateTitleView];
}

- (void)initializeFlashScreen {
    if (!firstTimeLoading) {
        firstTimeLoading = YES;
        _signViewController = [SignViewController new];
        SignNavigationViewController *signNavigationViewController = [[SignNavigationViewController alloc] initWithRootViewController:_signViewController];
        [self presentViewController:signNavigationViewController animated:NO completion:nil];
    }
   
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goToChat)
                                                 name:@"goToChat"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goToProfile)
                                                 name:@"goToProfile"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goToEvent:)
                                                 name:@"goToEvent"
                                               object:nil];
}

- (void)loadViewAfterSigningUser {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canFetchAppStartup"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchAppStart" object:nil];
}


- (void)goToChat {
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: [WGProfile currentUser]];
    fancyProfileViewController.events = self.events;
    [self.navigationController pushViewController: fancyProfileViewController animated: NO];

    ChatViewController *chatViewController = [ChatViewController new];
    chatViewController.view.backgroundColor = UIColor.whiteColor;
    [fancyProfileViewController.navigationController pushViewController:chatViewController animated:YES];
}

- (void)goToProfile {
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: [WGProfile currentUser]];
    fancyProfileViewController.events = self.events;
    [self.navigationController pushViewController: fancyProfileViewController animated: NO];
}

- (void)goToEvent:(NSNotification *)notification {
    NSDictionary *eventInfo = notification.userInfo;
    WGEvent *newEvent = [[WGEvent alloc] initWithJSON:eventInfo];
    if ([self.events containsObject:newEvent]) {
        WGEvent *presentEvent = (WGEvent *)[self.events objectAtIndex:[self.events indexOfObject:newEvent]];
        EventStoryViewController *eventStoryViewController = [EventStoryViewController new];
        eventStoryViewController.event = presentEvent;
        eventStoryViewController.view.backgroundColor = UIColor.whiteColor;
        [self.navigationController pushViewController: eventStoryViewController animated:YES];
    }
    else {
        [newEvent refresh:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                return;
            }
            EventStoryViewController *eventStoryViewController = [EventStoryViewController new];
            eventStoryViewController.event = newEvent;
            eventStoryViewController.view.backgroundColor = UIColor.whiteColor;
            [self.navigationController pushViewController: eventStoryViewController animated:YES];
        }];
    }
}

- (void)scrollUp {
    [_placesTableView setContentOffset:CGPointZero animated:YES];
}

- (void) updateViewNotGoingOut {
    [WGProfile currentUser].isGoingOut = @NO;
    [self updateTitleView];
    [self fetchEventsFirstPage];
}

- (void) updateTitleView {
    if (!self.groupName) self.groupName = [WGProfile currentUser].group.name;
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
    _placesTableView.backgroundColor = RGB(241, 241, 241);
    _placesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _yPositionOfWhereSubview = 280;
    
    CGRect frame = _placesTableView.bounds;
    frame.origin.y = -frame.size.height;
    UIView* whiteView = [[UIView alloc] initWithFrame:frame];
    whiteView.backgroundColor = UIColor.whiteColor;
    [_placesTableView addSubview:whiteView];
    
    [self addRefreshToScrollView];
    [self initializeGoingSomewhereElseButton];
    
}

- (void)chooseEvent:(NSNotification *)notification {
    if ([WGProfile currentUser].key) {
        NSNumber *eventID = [[notification userInfo] valueForKey:@"eventID"];
        [self goOutToEventNumber:eventID];
    }
}

- (void)followPressed {
    if ([WGProfile currentUser].key) {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
        [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:[WGProfile currentUser]] animated:YES];
    }
}

- (void)invitePressed {
    if ([WGProfile currentUser].eventAttending.id) {
        [self presentViewController:[[InviteViewController alloc] initWithEvent:[WGProfile currentUser].eventAttending] animated:YES completion:nil];
    }

}

- (void) goHerePressed:(id)sender {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Places", @"Go Here Source", nil];
    [WGAnalytics tagEvent:@"Go Here" withDetails:options];
    shouldAnimate = YES;
    _whereAreYouGoingTextField.text = @"";
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    [self addProfileUserToEventWithNumber:(int)buttonSender.tag];
    [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self goOutToEventNumber:[NSNumber numberWithInt:(int) buttonSender.tag]];
}

- (void)goOutToEventNumber:(NSNumber*)eventID {
    [[WGProfile currentUser] goingToEvent:[WGEvent serialize:@{ @"id" : eventID }] withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            return;
        }
        [WGProfile currentUser].isGoingOut = @YES;
        [self updateTitleView];
        [self fetchEventsFirstPage];
    }];
}

- (void)initializeGoingSomewhereElseButton {
    int sizeOfButton = [[UIScreen mainScreen] bounds].size.width/6.4;
    self.goingSomewhereButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - sizeOfButton - 10, self.view.frame.size.height - sizeOfButton - 10, sizeOfButton, sizeOfButton)];
    [self.goingSomewhereButton addTarget:self action:@selector(goingSomewhereElsePressed) forControlEvents:UIControlEventTouchUpInside];
    self.goingSomewhereButton.backgroundColor = [FontProperties getBlueColor];
    self.goingSomewhereButton.layer.borderWidth = 1.0f;
    self.goingSomewhereButton.layer.borderColor = [UIColor clearColor].CGColor;
    self.goingSomewhereButton.layer.cornerRadius = sizeOfButton/2;
    self.goingSomewhereButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.goingSomewhereButton.layer.shadowOpacity = 0.4f;
    self.goingSomewhereButton.layer.shadowRadius = 5.0f;
    self.goingSomewhereButton.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    
    [self.view addSubview:self.goingSomewhereButton];
    [self.view bringSubviewToFront:self.goingSomewhereButton];
    
    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(sizeOfButton/2 - 7, sizeOfButton/2 - 7, 15, 15)];
    sendOvalImageView.image = [UIImage imageNamed:@"plusStoryButton"];
    [self.goingSomewhereButton addSubview:sendOvalImageView];
}

- (void) goingSomewhereElsePressed {
    [WGAnalytics tagEvent:@"Go Somewhere Else Tapped"];

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
    [fancyProfileViewController setStateWithUser: [WGProfile currentUser]];
    fancyProfileViewController.events = self.events;
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


- (void)createPressed {
    if ([_whereAreYouGoingTextField.text length] != 0) {
        _whereAreYouGoingTextField.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self addLoadingIndicator];
        [WGEvent createEventWithName:_whereAreYouGoingTextField.text andHandler:^(WGEvent *object, NSError *error) {
            [UIView animateWithDuration:0.2f animations:^{
                _loadingIndicator.frame = CGRectMake(0, 0, _loadingView.frame.size.width, _loadingView.frame.size.height);
            } completion:^(BOOL finished) {
                if (finished) [_loadingView removeFromSuperview];
                
                _whereAreYouGoingTextField.enabled = YES;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                if (error) {
                    return;
                }
                
                [[WGProfile currentUser] goingToEvent:[WGEvent serialize:@{ @"id" : object.id }] withHandler:^(BOOL success, NSError *error) {
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                        return;
                    }
                    
                    [self removeProfileUserFromAnyOtherEvent];
                    
                    [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    
                    [self dismissKeyboard];
                    [self fetchEventsFirstPage];
                    [self updateTitleView];
                    
                    [WGProfile currentUser].isGoingOut = @YES;
                    [WGProfile currentUser].eventAttending = object;
                    [WGProfile currentUser].isGoingOut = @YES;
                    
                    WGEventAttendee *attendee = [[WGEventAttendee alloc] initWithJSON:@{ @"user" : [WGProfile currentUser] }];
                    WGCollection *eventAttendees = [WGCollection serializeArray:@[ [attendee deserialize] ] andClass:[WGEventAttendee class]];
                    object.attendees = eventAttendees;
                    
                    [self showStoryForEvent:object];
                }];
            }];
        }];
    }
}

- (void)addLoadingIndicator {
    _loadingView = [[UIView alloc] initWithFrame:CGRectMake(10, _whereAreYouGoingView.frame.size.height - 10, _whereAreYouGoingView.frame.size.width - 20, 5)];
    _loadingView.layer.borderColor = [FontProperties getBlueColor].CGColor;
    _loadingView.layer.borderWidth = 1.0f;
    _loadingView.layer.cornerRadius = 3.0f;
    
    _loadingIndicator = [[UIView alloc ] initWithFrame:CGRectMake(0, 0, 0, _loadingView.frame.size.height)];
    _loadingIndicator.backgroundColor = [FontProperties getBlueColor];
    [_loadingView addSubview:_loadingIndicator];
    [UIView animateWithDuration:0.8f animations:^{
        _loadingIndicator.frame = CGRectMake(0, 0, _loadingView.frame.size.width*0.7, _loadingView.frame.size.height);
    }];
    [_whereAreYouGoingView addSubview:_loadingView];
}


-(void)updateEvent:(WGEvent *)newEvent {
    [_events replaceObjectAtIndex:[_events indexOfObject:newEvent] withObject:newEvent];
}

- (void)textFieldDidChange:(UITextField *)textField {
    [_filteredEvents removeAllObjects];
    
    if([textField.text length] != 0) {
        _isSearching = YES;
        [self searchTableList: textField.text];
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
    } else {
        _isSearching = NO;
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

    }

    [_placesTableView reloadData];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self createPressed];
    return YES;
}

- (void)searchTableList:(NSString *)searchString {
    int index = 0;
    for (WGEvent *event in _events) {
        NSComparisonResult comparisonResult = [event.name compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
        
        if (comparisonResult == NSOrderedSame && ![_filteredEvents containsObject:event]) {
            [_filteredEvents addObject: event];
        }
        
        index += 1;
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
            return [_filteredEvents count];
        } else {
            int hasNextPage = ([_events.hasNextPage boolValue] ? 1 : 0);
            return [_events count] + hasNextPage;
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
        if ([_events count] > 0) [self.goElsewhereView setupWithMoreThanOneEvent:YES];
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

        WGEvent *event = [eventObjectArray objectAtIndex:[indexPath row]];
        if (event.highlight) {
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
            if (indexPath.row == [_filteredEvents count]) {
                return cell;
            }
        } else {
            if (indexPath.row == [_events count]) {
                [self fetchEvents];
                return cell;
            }
        }
        
        WGEvent *event;
        if (_isSearching) {
            int sizeOfArray = (int)[_filteredEvents  count];
            if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
            event = (WGEvent *)[_filteredEvents objectAtIndex:[indexPath row]];
        } else {
            int sizeOfArray = (int)[_events count];
            if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
            event = (WGEvent *)[_events objectAtIndex:[indexPath row]];
        }
        cell.event = event;
        if (self.groupNumberID) {
            cell.eventPeopleScrollView.groupID = self.groupNumberID;
        } else {
            cell.eventPeopleScrollView.groupID = nil;
        }
        cell.eventPeopleScrollView.placesDelegate = self;
        /* if ([self.eventOffsetDictionary objectForKey:[event.id stringValue]]) {
            cell.eventPeopleScrollView.contentOffset = CGPointMake([[self.eventOffsetDictionary objectForKey:[event.id stringValue]] intValue], 0);
        } */
        [cell updateUI];
        
        if (![event.isRead boolValue] &&
            [event.numMessages intValue] > 0) {
            cell.chatBubbleImageView.hidden = NO;
            cell.chatBubbleImageView.image = [UIImage  imageNamed:@"cameraBubble"];
            cell.postStoryImageView.image = [UIImage imageNamed:@"orangePostStory"];
        }
        else if ( [event.numMessages intValue] > 0) {
            cell.chatBubbleImageView.hidden = NO;
            cell.chatBubbleImageView.image = [UIImage  imageNamed:@"blueCameraBubble"];
            cell.postStoryImageView.image = [UIImage imageNamed:@"postStory"];
        } else {
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
    else if (self.pastDays.count > 0 && indexPath.section > 1) { // past day rows
        
        NSString *day = [self.pastDays objectAtIndex: indexPath.section - 2];
        NSArray *eventObjectArray = (NSArray *)[self.dayToEventObjArray objectForKey:day];
        
        WGEvent *event = [eventObjectArray objectAtIndex:[indexPath row]];
        HighlightOldEventCell *cell = [tableView dequeueReusableCellWithIdentifier:kHighlightOldEventCel];
        cell.event = event;
        cell.placesDelegate = self;
        cell.oldEventLabel.text = [event name];
        NSString *contentURL = event.highlight.media;
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [[WGProfile currentUser] cdnPrefix], contentURL]];
        __weak HighlightOldEventCell *weakCell = cell;
        [cell.highlightImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            if (image) {
                weakCell.highlightImageView.image = [self convertImageToGrayScale:image];
            }
        }];
        return cell;
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    

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
        } else {
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
    } else {
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

- (void)showUser:(WGUser *)user {
    shouldReloadEvents = NO;
    
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: user];
    if (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
        fancyProfileViewController.userState = OTHER_SCHOOL_USER_STATE;
    }
    [self.navigationController pushViewController: fancyProfileViewController animated: YES];

}

- (void)showConversationForEvent:(WGEvent *)event {
    
    [event getMessages:^(WGCollection *collection, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            return;
        }
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        int eventIndex = [self indexOfEvent:event inCollection:collection];
        
        EventConversationViewController *conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
        conversationViewController.event = event;
        conversationViewController.index = @(eventIndex);
        conversationViewController.eventMessages = collection;
        
        [self presentViewController:conversationViewController animated:YES completion:nil];
    }];
}

-(int) indexOfEvent:(WGEvent *)event inCollection:(WGCollection *)eventMessages {
    int index = 0;
    for (WGEventMessage *eventMessage in eventMessages) {
        if ([eventMessage isEqual:event.highlight]) {
            return index;
        }
        index += 1;
    }
    return 0;
}

- (void)showStoryForEvent:(WGEvent*)event {
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
    _spinnerAtCenter = YES;
    [self updateTitleView];
    [self fetchEventsFirstPage];
}

- (int)createUniqueIndexFromUserIndex:(int)userIndex andEventIndex:(int)eventIndex {
    int numberOfEvents = (int)[_events count];
    return numberOfEvents * userIndex + eventIndex;
}

- (NSDictionary *)getUserIndexAndEventIndexFromUniqueIndex:(int)uniqueIndex {
    int userIndex, eventIndex;
    int numberOfEvents = (int)[_events count];
    userIndex = uniqueIndex / numberOfEvents;
    eventIndex = uniqueIndex - userIndex * numberOfEvents;
    return @{ @"userIndex": [NSNumber numberWithInt:userIndex], @"eventIndex" : [NSNumber numberWithInt:eventIndex] };
}



#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if (scrollView == _placesTableView) {
        
        if (!self.goElsewhereView) {
            return;
        }
        if (![self shouldShowCreateButton]) {
            return;
        }
        [self showOnlyOnePlusButton];
    }
}

- (void)showOnlyOnePlusButton {
    // convert label frame
    CGRect comparisonFrame = [_placesTableView convertRect: self.goElsewhereView.frame toView:self.view];
    // check if label is contained in self.view
    
    CGRect viewFrame = self.view.frame;
    BOOL isContainedInView = CGRectContainsRect(viewFrame, comparisonFrame);
    if ([self isPeeking] || (isContainedInView && self.goingSomewhereButton.hidden == NO && isLoaded)) {
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
#pragma mark - Network Asynchronous Functions

- (void) fetchEventsFirstPage {
    _allEvents = nil;
    [self fetchEvents];
}

- (void) fetchEvents {
    if (!self.fetchingEventAttendees && [WGProfile currentUser].key) {
        self.fetchingEventAttendees = YES;
        if (_spinnerAtCenter) [WiGoSpinnerView addDancingGToCenterView:self.view];
        __weak typeof(self) weakSelf = self;
        if (_allEvents) {
            if ([_allEvents.hasNextPage boolValue]) {
                [_allEvents addNextPage:^(BOOL success, NSError *error) {
                    [WiGoSpinnerView removeDancingGFromCenterView:weakSelf.view];
                    
                    if (error) {
                        weakSelf.fetchingEventAttendees = NO;
                        shouldReloadEvents = YES;
                        return;
                    }
                    
                    weakSelf.pastDays = [[NSMutableArray alloc] init];
                    weakSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
                    weakSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
                    weakSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                    weakSelf.filteredEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                    
                    for (WGEvent *event in weakSelf.allEvents) {
                        if ([event.isExpired boolValue]) {
                            [weakSelf.oldEvents addObject:event];
                        } else {
                            [weakSelf.events addObject:event];
                        }
                    }
                    
                    for (WGEvent *event in weakSelf.oldEvents) {
                        if (![event highlight]) {
                            continue;
                        }
                        NSString *eventDate = [[event expires] deserialize];
                        if ([weakSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                            [weakSelf.pastDays addObject: eventDate];
                            [weakSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                        }
                        [[weakSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
                    }
                    
                    [eventPageArray removeAllObjects];
                    [weakSelf fetchedOneParty];
                    weakSelf.fetchingEventAttendees = NO;
                    shouldReloadEvents = YES; 
                    [weakSelf.placesTableView reloadData];
                }];
            }
        } else if (self.groupNumberID) {
            [WGEvent getWithGroupNumber:self.groupNumberID andHandler:^(WGCollection *collection, NSError *error) {

                [WiGoSpinnerView removeDancingGFromCenterView:weakSelf.view];

                if (error) {
                    weakSelf.fetchingEventAttendees = NO;
                    shouldReloadEvents = YES;
                    return;
                }
                weakSelf.allEvents = collection;
                weakSelf.pastDays = [[NSMutableArray alloc] init];
                weakSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
                weakSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
                weakSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                weakSelf.filteredEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                
                for (WGEvent *event in weakSelf.allEvents) {
                    if ([event.isExpired boolValue]) {
                        [weakSelf.oldEvents addObject:event];
                    } else {
                        [weakSelf.events addObject:event];
                    }
                }
                
                for (WGEvent *event in weakSelf.oldEvents) {
                    if (![event highlight]) {
                        continue;
                    }
                    NSString *eventDate = [[event expires] deserialize];
                    if ([weakSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                        [weakSelf.pastDays addObject: eventDate];
                        [weakSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                    }
                    [[weakSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
                }
                
                [eventPageArray removeAllObjects];
                [weakSelf fetchedOneParty];
                weakSelf.fetchingEventAttendees = NO;
                [weakSelf.placesTableView reloadData];
            }];
        } else {
            [WGEvent get:^(WGCollection *collection, NSError *error) {
                [WiGoSpinnerView removeDancingGFromCenterView:weakSelf.view];
                if (error) {
                    // [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    weakSelf.fetchingEventAttendees = NO;
                    return;
                }
                weakSelf.allEvents = collection;
                weakSelf.pastDays = [[NSMutableArray alloc] init];
                weakSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
                weakSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
                weakSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                weakSelf.filteredEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                
                for (WGEvent *event in weakSelf.allEvents) {
                    if ([event.isExpired boolValue]) {
                        [weakSelf.oldEvents addObject:event];
                    } else {
                        [weakSelf.events addObject:event];
                    }
                }
                
                for (WGEvent *event in weakSelf.oldEvents) {
                    if (![event highlight]) {
                        continue;
                    }
                    NSString *eventDate = [[event expires] deserialize];
                    if ([weakSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                        [weakSelf.pastDays addObject: eventDate];
                        [weakSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                    }
                    [[weakSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
                }
                
                [eventPageArray removeAllObjects];
                [weakSelf fetchedOneParty];
                weakSelf.fetchingEventAttendees = NO;
                [weakSelf.placesTableView reloadData];
            }];
        }
    }
}

- (void)fetchedOneParty {
    _spinnerAtCenter ? [WiGoSpinnerView removeDancingGFromCenterView:self.view] : [_placesTableView didFinishPullToRefresh];
     _spinnerAtCenter = NO;
    _filteredEvents = [WGCollection serializeArray:@[] andClass:[WGEvent class]];
    [self dismissKeyboard];
}

- (void) fetchUserInfo {
    if (!fetchingUserInfo && [WGProfile currentUser].key) {
        fetchingUserInfo = YES;
        [WGProfile reload:^(BOOL success, NSError *error) {
            if (!secondTimeFetchingUserInfo) {
                secondTimeFetchingUserInfo = YES;
                [_signViewController reloadedUserInfo:success andError:error];
            }
            if (error) {
                fetchingUserInfo = NO;
                return;
            }
            [self initializeNavigationBar];
            fetchingUserInfo = NO;
        }];
    }
}

#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    [WiGoSpinnerView addDancingGToUIScrollView:_placesTableView
                                   withHandler:^{
        _spinnerAtCenter = NO;
        [self fetchEventsFirstPage];
        [self fetchUserInfo];
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

- (void)presentContactsView {
    if (!presentedMobileContacts) {
        presentedMobileContacts = YES;
        [self presentViewController:[MobileContactsViewController new] animated:YES completion:nil];
    }
}

- (void)createEventWithName:(NSString *)eventName {
    [WGEvent createEventWithName:eventName andHandler:^(WGEvent *object, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                return;
            }
            [_events addObject:object];
            [_events exchangeObjectAtIndex:([_events count] - 1) withObjectAtIndex:0];
            [self removeProfileUserFromAnyOtherEvent];
        });
    }];
}

- (void)addProfileUserToEventWithNumber:(int)eventID {
    WGEvent *event = (WGEvent *)[_events objectWithID:[NSNumber numberWithInt:eventID]];
    [self removeProfileUserFromAnyOtherEvent];
    [event.attendees insertObject:[WGProfile currentUser] atIndex:0];
    event.numAttending = @([event.numAttending intValue] + 1);
    [_events exchangeObjectAtIndex:[_events indexOfObject:event] withObjectAtIndex:0];
}

-(void) removeProfileUserFromAnyOtherEvent {
    for (WGEvent* event in _events) {
        if ([event.attendees containsObject:[WGProfile currentUser]]) {
            [event.attendees removeObject:[WGProfile currentUser]];
            event.numAttending = @([event.numAttending intValue] - 1);
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

-(void) updateUI {
    self.eventNameLabel.text = [self.event name];
    if (![self.event.isRead boolValue] && [self.event.numMessages intValue] > 0) {
        self.chatBubbleImageView.hidden = NO;
        self.chatBubbleImageView.image = [UIImage imageNamed:@"cameraBubble"];
        self.chatNumberLabel.text = [NSString stringWithFormat:@"%@", [self.event.numMessages stringValue]];
    }
    else if ([self.event.numMessages intValue] > 0) {
        self.chatBubbleImageView.hidden = NO;
        self.chatBubbleImageView.image = [UIImage imageNamed:@"blueCameraBubble"];
    } else {
     self.chatBubbleImageView.hidden = YES;
    }
    self.eventPeopleScrollView.event = self.event;
    [self.eventPeopleScrollView updateUI];
}

- (void)setOffset:(int)offset forIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)showEventConversation {
    [self.eventPeopleScrollView saveScrollPosition];
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
    [self.showHighlightsButton setTitle:@"Show Past Highlights" forState:UIControlStateNormal];
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
