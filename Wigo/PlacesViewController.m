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
#import "InviteViewController.h"
#import "SignNavigationViewController.h"
#import "PeekViewController.h"
#import "ProfileViewController.h"
#import "FXBlurView.h"
#import "ChatViewController.h"
#import "BatteryViewController.h"
#import "UIView+ViewToImage.h"
#import "UIImage+ImageEffects.h"
#import "ReferalViewController.h"
#import "PrivateSwitchView.h"
#import "EventMessagesConstants.h"
#import "OverlayViewController.h"
#import "EventConversationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WGNavigateParser.h"

#define kEventCellName @"EventCell"
#define kHighlightOldEventCell @"HighlightOldEventCell"
#define kOldEventCellName @"OldEventCell"

#define kOldEventShowHighlightsCellName @"OldEventShowHighlightsCellName"

@interface PlacesViewController () {
    BOOL isLoaded;
}

@property (nonatomic, strong) UIView *whereAreYouGoingView;
@property (nonatomic, assign) int tagInteger;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, strong) NSMutableArray *placeSubviewArray;
@property (nonatomic, strong) UIImageView *searchIconImageView;
@property (nonatomic, strong) UIView *searchBarBorderView;

@property (nonatomic, strong) UIImageView *whereImageView;
@property (nonatomic, strong) UILabel *whereLabel;


//private pressed
@property UIScrollView *scrollViewSender;
@property CGPoint scrollViewPoint;


// Events By Days
@property (nonatomic, strong) NSMutableArray *pastDays;

@property (nonatomic, strong) UIView *blackViewOnTop;
@property (nonatomic ,strong) UIView *eventDetails;
@property (nonatomic, strong) PrivateSwitchView *privateSwitchView;
@end

BOOL presentedMobileContacts;
BOOL firstTimeLoading;

@implementation PlacesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeNotificationObservers];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavigationBarBackground"]
                       forBarPosition:UIBarPositionAny
                           barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.fetchingUserInfo = NO;
    self.fetchingEventAttendees = NO;
    presentedMobileContacts = NO;
    self.shouldReloadEvents = YES;
    self.eventOffsetDictionary = [NSMutableDictionary new];
    
    UITabBarController *tab= self.tabBarController;
    ProfileViewController *profileVc = (ProfileViewController *)[tab.viewControllers objectAtIndex:3];
    profileVc.user = [WGUser new];

    self.spinnerAtCenter = YES;
    [self initializeWhereView];
    [NetworkFetcher.defaultGetter fetchMessages];
    [NetworkFetcher.defaultGetter fetchSuggestions];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.selectedImageTintColor = [FontProperties getBlueColor];
    if ([self isPeeking] && self.groupNumberID && self.groupName) {
        [WGAnalytics tagView:@"where" withTargetGroup:[[WGGroup alloc] initWithJSON:@{@"name": self.groupName, @"id": self.groupNumberID}]];
    }
    else {
        [WGAnalytics tagView:@"where"];
    }

    self.navigationController.navigationBar.barTintColor = [FontProperties getBlueColor];
    [self.navigationController.navigationBar setBackgroundImage:[self imageWithColor: [FontProperties getBlueColor]] forBarMetrics:UIBarMetricsDefault];

    [self updateNavigationBar];
    [self.placesTableView reloadData];
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
    self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x, 20, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height);
    [self updateBarButtonItems:1.0f];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initializeFlashScreen];
    if (!WGProfile.currentUser.key && !self.presentingLockedView) {
        [self showFlashScreen];
        [self.signViewController reloadedUserInfo:NO andError:nil];
    }

    [self.view endEditing:YES];
    if (self.shouldReloadEvents) {
        [self fetchEventsFirstPage];
    } else {
        self.shouldReloadEvents = YES;
    }
    [self updateNavigationBar];
    [self fetchUserInfo];
}

- (void)showReferral {
    if (WGProfile.currentUser.findReferrer) {
        [self presentViewController:[ReferalViewController new] animated:YES completion:nil];
        WGProfile.currentUser.findReferrer = NO;
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {}];
    }
}


- (BOOL) isPeeking {
    if (WGProfile.currentUser.group.id &&
        (!self.groupNumberID || [self.groupNumberID isEqualToNumber:WGProfile.currentUser.group.id])){
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

- (void) updateNavigationBar {
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:WGProfile.currentUser.group.id]) {
        self.rightButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 10, 30, 30) andType:@3];
        UIImageView *plusCreateImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 16, 16)];
        plusCreateImageView.image = [UIImage imageNamed:@"plusCreate"];
        [self.rightButton addSubview:plusCreateImageView];
        self.rightButton.titleLabel.font = [FontProperties lightFont:25];
        [self.rightButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self.rightButton addTarget:self action:@selector(goingSomewhereElsePressed)
                   forControlEvents:UIControlEventTouchUpInside];
        [self.rightButton setShowsTouchWhenHighlighted:YES];
        UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.rightButton];
        self.tabBarController.navigationItem.rightBarButtonItem = rightBarButton;
    }

    UIImageView *topImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 78, 34)];
    topImageView.image = [UIImage imageNamed:@"topWigoLogo"];
    self.tabBarController.navigationItem.titleView = topImageView;
}

-(void) initializeFlashScreen {
    if (!firstTimeLoading) {
        firstTimeLoading = YES;
        self.signViewController = [SignViewController new];
        self.signViewController.placesDelegate = self;
    }
}

-(void) showFlashScreen {
    SignNavigationViewController *signNavigationViewController = [[SignNavigationViewController alloc] initWithRootViewController:self.signViewController];
    [self presentViewController:signNavigationViewController animated:NO completion:nil];
}


- (void)initializeNotificationObservers {

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollUp)
                                                 name:@"scrollUp"
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
                                             selector:@selector(goToChat:)
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navigate:)
                                                 name:@"navigate"
                                               object:nil];}

- (void)goToChat:(NSNotification *)notification {
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = WGProfile.currentUser;
    profileViewController.events = self.events;
    [self.navigationController pushViewController: profileViewController animated: NO];
    
    ChatViewController *chatViewController = [ChatViewController new];
    chatViewController.view.backgroundColor = UIColor.whiteColor;
    [profileViewController.navigationController pushViewController:chatViewController animated:YES];
}

- (void)goToProfile {
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = WGProfile.currentUser;
    profileViewController.events = self.events;
    [self.navigationController pushViewController: profileViewController animated: NO];
}

- (void)goToEvent:(NSNotification *)notification {
    NSDictionary *eventInfo = notification.userInfo;
    WGEvent *newEvent = [[WGEvent alloc] initWithJSON:eventInfo];
    if ([self.events containsObject:newEvent]) {
        NSInteger integer = [self.events indexOfObject:newEvent];
        [self.placesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:integer inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)navigate:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSDictionary *objects = [WGNavigateParser objectsFromUserInfo:userInfo];
    NSString *nameOfObject = [WGNavigateParser nameOfObjectFromUserInfo:userInfo];
    if ([nameOfObject isEqual:@"eventmessage"]) {
        
    }
    else if ([nameOfObject isEqual:@"event"]) {
        
    }
}

- (void)scrollUp {
    [self.placesTableView setContentOffset:CGPointZero animated:YES];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.2 animations:^{
        self.placesTableView.transform = CGAffineTransformMakeTranslation(0, 0);
        _whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0,-50);
        _whereAreYouGoingView.alpha = 0;
    } completion:^(BOOL finished) {
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
    self.placesTableView = [[UITableView alloc] initWithFrame: CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 20) style: UITableViewStyleGrouped];
    self.placesTableView.sectionHeaderHeight = 0;
    self.placesTableView.sectionFooterHeight = 0;
    [self.view addSubview:self.placesTableView];
    self.placesTableView.dataSource = self;
    self.placesTableView.delegate = self;
    self.placesTableView.showsVerticalScrollIndicator = NO;
    [self.placesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.placesTableView registerClass:[EventCell class] forCellReuseIdentifier:kEventCellName];
    [self.placesTableView registerClass:[HighlightOldEventCell class] forCellReuseIdentifier:kHighlightOldEventCell];
    [self.placesTableView registerClass:[OldEventShowHighlightsCell class] forCellReuseIdentifier:kOldEventShowHighlightsCellName];
    self.placesTableView.backgroundColor = RGB(237, 237, 237);
    self.placesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addRefreshToScrollView];
    
    self.labelSwitch = [[LabelSwitch alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [LabelSwitch height])];
    [self.view bringSubviewToFront:self.labelSwitch];
    [self.view addSubview:self.labelSwitch];
    
    self.blueBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    self.blueBannerView.backgroundColor = [FontProperties getBlueColor];
    self.blueBannerView.hidden = YES;
    [self.view addSubview:self.blueBannerView];
}

- (void)showEvent:(WGEvent *)event {
    if (!self.events) return;
    
    NSInteger index = [self.events indexOfObject:event];
    if ([self.placesTableView numberOfRowsInSection:kTodaySection] > index) {
        [self.placesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:kTodaySection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}


- (void)followPressed {
    if (!WGProfile.currentUser.key) return;
    
    if (_blackViewOnTop) _blackViewOnTop.alpha = 0.0f;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:WGProfile.currentUser] animated:YES];
}

- (void)invitePressed {
    if (!WGProfile.currentUser.eventAttending.id) return;
    
    [self presentViewController:[[InviteViewController alloc] initWithEvent:WGProfile.currentUser.eventAttending] animated:YES completion:nil];
}

- (void)showOverlayForInvite:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    OverlayViewController *overlayViewController = [OverlayViewController new];
    [self presentViewController:overlayViewController animated:NO completion:nil];
    overlayViewController.event = [self getEventAtIndexPath:[NSIndexPath indexPathForItem:buttonSender.tag inSection:0]];
}


- (void) goHerePressed:(id)sender withHandler:(BoolResultBlock)handler {
    WGProfile.tapAll = NO;

    [WGAnalytics tagAction:@"go_here" atView:@"where"];
    self.whereAreYouGoingTextField.text = @"";
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    
    __weak typeof(self) weakSelf = self;
    WGEvent *event = [self getEventAtIndexPath:[NSIndexPath indexPathForItem:buttonSender.tag inSection:0]];
    if (event == nil) return;
    [WGProfile.currentUser goingToEvent:event withHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            handler(success, error);
            return;
        }
        WGProfile.currentUser.isGoingOut = @YES;
        if (!strongSelf.doNotReloadOffsets) {
            for (NSString *key in [strongSelf.eventOffsetDictionary allKeys]) {
                [strongSelf.eventOffsetDictionary setValue:@0 forKey:key];
            }
            strongSelf.doNotReloadOffsets = NO;
        }
        strongSelf.aggregateEvent = nil;
        strongSelf.allEvents = nil;
        [strongSelf fetchEventsWithHandler:handler];
    }];
}


- (void) goingSomewhereElsePressed {
    [WGAnalytics tagAction:@"create_event" atView:@"where"];
    [self scrollUp];
    [self showWhereAreYouGoingView];

    
    [UIView animateWithDuration: 0.2 animations:^{
        self.tabBarController.navigationItem.titleView.alpha = 0.0f;
        self.tabBarController.navigationItem.leftBarButtonItem.customView.alpha = 0.0f;
        self.tabBarController.navigationItem.rightBarButtonItem.customView.alpha = 0.0f;
        
        [self.whereAreYouGoingTextField becomeFirstResponder];
        _whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0, 50);
        _whereAreYouGoingView.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        
        [self.tabBarController.navigationItem setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Cancel" style: UIBarButtonItemStylePlain target: self action: @selector(cancelledAddEventTapped)] animated: NO];
        
        [self.tabBarController.navigationItem setRightBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Create" style: UIBarButtonItemStylePlain target: self action: @selector(createPressed)] animated: NO];
        
        [self.tabBarController.navigationItem.leftBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
        [self.tabBarController.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

        self.placesTableView.userInteractionEnabled = NO;
    }];
}

- (void) cancelledAddEventTapped {
    [self updateNavigationBar];
    [self dismissKeyboard];
}

- (void)profileSegue {
    if (_blackViewOnTop) _blackViewOnTop.alpha = 0.0f;
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = WGProfile.currentUser;
    profileViewController.placesDelegate = self;
    profileViewController.events = self.events;

    [self.navigationController pushViewController: profileViewController animated: YES];
}

- (void) gotItPressed {
    _scrollViewSender.contentOffset = _scrollViewPoint;
    _scrollViewSender.scrollEnabled = YES;
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void){}];
}

#pragma mark - Where Are You Going? View and Delegate

- (void)showWhereAreYouGoingView {
    if (!_whereAreYouGoingView) {
        _whereAreYouGoingView = [[UIView alloc] initWithFrame:CGRectMake(0, 14, self.view.frame.size.width, self.view.frame.size.height)];
        _whereAreYouGoingView.backgroundColor = UIColor.whiteColor;
        _whereAreYouGoingView.alpha = 0;
        [self.view addSubview:_whereAreYouGoingView];
        
        UILabel *eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 45, 10, 90, 30)];
        eventNameLabel.text = @"Event Name";
        eventNameLabel.textColor = [FontProperties getBlueColor];
        eventNameLabel.textAlignment = NSTextAlignmentCenter;
        eventNameLabel.font = [FontProperties scMediumFont:15.0f];
        [_whereAreYouGoingView addSubview:eventNameLabel];
        
        UIView *lineUnderEventName = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 45, 40, 90, 1)];
        lineUnderEventName.backgroundColor = [FontProperties getBlueColor];
        [_whereAreYouGoingView addSubview:lineUnderEventName];
        
        self.whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 40, _whereAreYouGoingView.frame.size.width, 50)];
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
        [_whereAreYouGoingView addSubview:self.whereAreYouGoingTextField];
        
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, _whereAreYouGoingView.frame.size.height - 1, _whereAreYouGoingView.frame.size.width, 1.0f);
        bottomBorder.backgroundColor = [[FontProperties getBlueColor] colorWithAlphaComponent: 0.5f].CGColor;
        [_whereAreYouGoingView.layer addSublayer:bottomBorder];
        
        _eventDetails = [[UIView alloc] initWithFrame:CGRectMake(0, 110, self.view.frame.size.width, self.view.frame.size.height)];
        [_whereAreYouGoingView addSubview:_eventDetails];
        
        UILabel *eventTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
        eventTypeLabel.text = @"Event Type";
        eventTypeLabel.textAlignment = NSTextAlignmentCenter;
        eventTypeLabel.textColor = [FontProperties getBlueColor];
        eventTypeLabel.font = [FontProperties scMediumFont:15.0f];
        [_eventDetails addSubview:eventTypeLabel];
        
        UIView *lineUnderEventType = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 45, 30, 90, 1)];
        lineUnderEventType.backgroundColor = [FontProperties getBlueColor];
        [_eventDetails addSubview:lineUnderEventType];
        
        _privateSwitchView = [[PrivateSwitchView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 120, 40, 240, 40)];
        [_eventDetails addSubview:_privateSwitchView];
        _privateSwitchView.privateString = @"Only you can invite people and only\nthose invited can see the event.";
        _privateSwitchView.publicString =  @"The whole school can see and attend your event.";
        _privateSwitchView.privateDelegate = self;
        [_privateSwitchView.closeLockImageView stopAnimating];
        [_privateSwitchView.openLockImageView stopAnimating];
        
        self.invitePeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 82, self.view.frame.size.width, 30)];
        self.invitePeopleLabel.text = _privateSwitchView.explanationString;
        self.invitePeopleLabel.textAlignment = NSTextAlignmentCenter;
        self.invitePeopleLabel.numberOfLines = 2;
        self.invitePeopleLabel.font = [FontProperties openSansRegular:12.0f];
        self.invitePeopleLabel.textColor = [FontProperties getBlueColor];
        [_eventDetails addSubview:self.invitePeopleLabel];
        
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            _eventDetails.frame = CGRectMake(0, 77, self.view.frame.size.width, 30);
        }
    }
    [_privateSwitchView.closeLockImageView stopAnimating];
    [_privateSwitchView.openLockImageView stopAnimating];
    if (![WGProfile.currentUser.privateEvents boolValue]) {
        _eventDetails.hidden = YES;
    }
    else {
        _eventDetails.hidden = NO;
    }
}

- (void)updateUnderliningText {
    self.invitePeopleLabel.text = _privateSwitchView.explanationString;
}

- (void)clearTextField {
    self.placesTableView.userInteractionEnabled = YES;
    self.whereAreYouGoingTextField.text = @"";
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
            
            [strongSelf updateNavigationBar];
            strongSelf.whereAreYouGoingTextField.enabled = YES;
            strongSelf.tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
            if (error) {
                return;
            }
            __weak typeof(strongSelf) weakOfStrong = strongSelf;
            [WGProfile.currentUser goingToEvent:object withHandler:^(BOOL success, NSError *error) {
                __strong typeof(weakOfStrong) strongOfStrong = weakOfStrong;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionSave];
                    return;
                }
                
                [strongOfStrong removeProfileUserFromAnyOtherEvent];
                [strongOfStrong dismissKeyboard];
                
                WGProfile.currentUser.isGoingOut = @YES;
                WGProfile.currentUser.eventAttending = object;
                
                WGEventAttendee *attendee = [[WGEventAttendee alloc] initWithJSON:@{ @"user" : WGProfile.currentUser }];
                
                if ([strongOfStrong.allEvents containsObject:object]) {
                    WGEvent *joinedEvent = (WGEvent *)[strongOfStrong.allEvents objectWithID:object.id];
                    [joinedEvent.attendees insertObject:attendee atIndex:0];
                } else {
                    if (object.attendees) {
                        [object.attendees insertObject:attendee atIndex:0];
                    } else {
                        WGCollection *eventAttendees = [WGCollection serializeArray:@[ [attendee deserialize] ] andClass:[WGEventAttendee class]];
                        object.attendees = eventAttendees;
                    }
                }
                [strongOfStrong fetchEventsFirstPage];
            }];
        }];
    }];
    
}

- (void)addLoadingIndicator {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(10, 5, _whereAreYouGoingView.frame.size.width - 20, 5)];
    self.loadingView.layer.borderColor = [FontProperties getBlueColor].CGColor;
    self.loadingView.layer.borderWidth = 1.0f;
    self.loadingView.layer.cornerRadius = 3.0f;
    
    self.loadingIndicator = [[UIView alloc ] initWithFrame:CGRectMake(0, 0, 0, self.loadingView.frame.size.height)];
    self.loadingIndicator.backgroundColor = [FontProperties getBlueColor];
    [self.loadingView addSubview:self.loadingIndicator];
    [UIView animateWithDuration:0.8f animations:^{
        self.loadingIndicator.frame = CGRectMake(0, 0, self.loadingView.frame.size.width*0.7, self.loadingView.frame.size.height);
    }];
    [_whereAreYouGoingView addSubview:self.loadingView];
}


-(void)updateEvent:(WGEvent *)newEvent {
    [self.events replaceObjectAtIndex:[self.events indexOfObject:newEvent] withObject:newEvent];
}


- (void)textFieldDidChange:(UITextField *)textField {
    if(textField.text.length != 0) {
        [self.tabBarController.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
    } else {
        [self.tabBarController.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
    }
    
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self createPressed];
    return YES;
}


#pragma mark - Tablew View Data Source

- (int)shouldShowAggregatePrivateEvents {
    BOOL areEventsOfTodayDone = self.oldEvents.count > 0 || ![self.allEvents.hasNextPage boolValue];
    return (self.aggregateEvent &&
            self.aggregateEvent.attendees &&
            self.aggregateEvent.attendees.metaNumResults.intValue > 0 &&
            areEventsOfTodayDone) ? 1 : 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self shouldShowHighlights]) {
        //[Today section]  [Button show highlights]
        return 1 + 1 + 1;
    }
    else if (self.pastDays.count > 0) {
        //[Today section] [Highlighs section] (really just space for a header) + pastDays sections
        return 1 + 1;
//        return 1 + 1 + self.pastDays.count;
    }
    //[Today section]
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kTodaySection) {
        int hasNextPage = ([self.allEvents.hasNextPage boolValue] ? 1 : 0);
        return self.events.count + hasNextPage + [self shouldShowAggregatePrivateEvents];
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
        return 40;
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
        return [TodayHeader new];
    }
    else if (section == kHighlightsEmptySection) {
        return [HighlightsHeader init];
    }
    else if ([self shouldShowHighlights] && section > 1) {
        return nil;
    }
    else if (self.pastDays.count > 0 && section > 1) { //past day headers
        return [PastDayHeader initWithDay: [self.pastDays objectAtIndex: section - 2] isFirst: (section - 2) == 0];
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kTodaySection) {
        WGEvent *event = [self getEventAtIndexPath:indexPath];
        if (indexPath.row == self.events.count &&
            [self shouldShowAggregatePrivateEvents] == 1) {
            return [EventCell height];
        }
        if (indexPath.row == self.events.count + 1 &&
            [self.allEvents.hasNextPage boolValue] &&
            [self shouldShowAggregatePrivateEvents] == 1) {
            return 0.3;
        }
        if (indexPath.row == self.events.count &&
            [self.allEvents.hasNextPage boolValue] &&
            [self shouldShowAggregatePrivateEvents] == 1) {
           return 0.3;
        }
        if (event == nil) return 0.3;
        return [EventCell height];
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
            return [HighlightOldEventCell height];
        }
    }
    
    return 0;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.pastDays.count > 0 && indexPath.section > 1) {
        NSString *day = [self.pastDays objectAtIndex: indexPath.section - 2];
        NSArray *eventObjectArray = (NSArray *)[self.dayToEventObjArray objectForKey:day];
        WGEvent *event = [eventObjectArray objectAtIndex:[indexPath row]];
        [self showConversationForEvent:event];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kTodaySection) {
        EventCell *cell = [tableView dequeueReusableCellWithIdentifier:kEventCellName forIndexPath:indexPath];
        //Cleanup
        cell.highlightsCollectionView.event = nil;
        cell.highlightsCollectionView.eventMessages = nil;
        [cell.highlightsCollectionView reloadData];
        cell.placesDelegate = self;
        if (cell.loadingView.isAnimating) [cell.loadingView stopAnimating];
        cell.loadingView.hidden = YES;
        cell.placesDelegate = self;
        cell.eventPeopleScrollView.rowOfEvent = indexPath.row;
        cell.eventPeopleScrollView.isPeeking = [self isPeeking];
        cell.eventPeopleScrollView.hidden = NO;
        cell.privacyLockButton.tag = indexPath.row;
        [cell.privacyLockButton addTarget:self action:@selector(privacyPressed:) forControlEvents:UIControlEventTouchUpInside];
        if (indexPath.row == self.events.count &&
            [self shouldShowAggregatePrivateEvents] == 1) {
            cell.event = self.aggregateEvent;
            cell.eventPeopleScrollView.groupID = self.groupNumberID;
            cell.eventPeopleScrollView.placesDelegate = self;
            cell.placesDelegate = self;
            if (![self.eventOffsetDictionary objectForKey:[self.aggregateEvent.id stringValue]]) {
                cell.eventPeopleScrollView.contentOffset = CGPointMake(0, 0);
            }
            return cell;
        }
        if (indexPath.row == self.events.count && [self shouldShowAggregatePrivateEvents] == 0) {
            [self fetchEventsWithHandler:^(BOOL success, NSError *error) {}];
            cell.loadingView.hidden = NO;
            [cell.loadingView startAnimating];
            cell.eventNameLabel.text = nil;
            cell.numberOfPeopleGoingLabel.text = nil;
            cell.privacyLockImageView.hidden = YES;
            cell.eventPeopleScrollView.hidden = YES;
            cell.highlightsCollectionView.placesDelegate = self;
            cell.highlightsCollectionView.isPeeking = [self isPeeking];
            return cell;
        }
        
        WGEvent *event = [self getEventAtIndexPath:indexPath];
        if (event == nil) return cell;

        cell.event = event;
        cell.eventPeopleScrollView.groupID = self.groupNumberID;
        cell.eventPeopleScrollView.placesDelegate = self;
        if (![self.eventOffsetDictionary objectForKey:[event.id stringValue]]) {
            cell.eventPeopleScrollView.contentOffset = CGPointMake(0, 0);
        }
        cell.highlightsCollectionView.placesDelegate = self;
        cell.highlightsCollectionView.isPeeking = [self isPeeking];
        return cell;
    } else if (indexPath.section == kHighlightsEmptySection) {
        return nil;
    } else if ([self shouldShowHighlights] && indexPath.section > 1) {
        OldEventShowHighlightsCell *cell = [tableView dequeueReusableCellWithIdentifier:kOldEventShowHighlightsCellName forIndexPath:indexPath];
        cell.placesDelegate = self;
        return cell;
    } else if (self.pastDays.count > 0 && indexPath.section > 1) {
        // past day rows
        NSString *day = [self.pastDays objectAtIndex: indexPath.section - 2];
        NSArray *eventObjectArray = (NSArray *)[self.dayToEventObjArray objectForKey:day];
        if (indexPath.row == eventObjectArray.count - 1 &&
            self.allEvents.hasNextPage.boolValue) {
            [self fetchEventsWithHandler:^(BOOL success, NSError *error) {}];
        }
        WGEvent *event = [eventObjectArray objectAtIndex:indexPath.row];
        HighlightOldEventCell *cell = [tableView dequeueReusableCellWithIdentifier:kHighlightOldEventCell forIndexPath:indexPath];
        cell.event = event;
//        cell.placesDelegate = self;
//        cell.oldEventLabel.text = event.name;
//        if (cell.event.isPrivate) {
//            cell.oldEventLabel.transform = CGAffineTransformMakeTranslation(20, 0);
//            cell.privateIconImageView.hidden = NO;
//        }
//        else {
//            cell.oldEventLabel.transform = CGAffineTransformMakeTranslation(0, 0);
//            cell.privateIconImageView.hidden = YES;
//        }
//        NSString *contentURL;
//        if ([event.highlight.mediaMimeType isEqual:kImageEventType]) {
//            contentURL = event.highlight.media;
//        }
//        else {
//            contentURL = event.highlight.thumbnail;
//        }
//        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile.currentUser cdnPrefix], contentURL]];
//        [cell.highlightImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        }];

        return cell;
    }
    return nil;
}

- (void)privacyPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    WGEvent *event = [self getEventAtIndexPath:[NSIndexPath indexPathForItem:buttonSender.tag inSection:0]];
    OverlayViewController *overlayViewController = [OverlayViewController new];
    [self presentViewController:overlayViewController animated:YES completion:nil];
    overlayViewController.event = event;
}

- (BOOL)isFullCellForEvent:(WGEvent *)event {
    return [self isPeeking] || (event.id && [WGProfile.currentUser.eventAttending.id isEqual:event.id]);
}

- (WGEvent *)getEventAtIndexPath:(NSIndexPath *)indexPath {
    WGEvent *event;
    int sizeOfArray = (int)self.events.count;
    if (sizeOfArray == 0 || sizeOfArray <= indexPath.row) return nil;
    event = (WGEvent *)[self.events objectAtIndex:indexPath.row];
    return event;
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

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kTodaySection) {
        WGEvent *event = [self getEventAtIndexPath:indexPath];
        if (event == nil) return;
        EventCell *eventCell = (EventCell *)cell;
        if ([[self.eventOffsetDictionary objectForKey:[event.id stringValue]] isEqualToNumber:@0]) {
            eventCell.eventPeopleScrollView.contentOffset = CGPointMake(0, 0);
        }
        [eventCell.eventPeopleScrollView saveScrollPosition];
    }
}

- (BOOL) shouldShowHighlights {
    BOOL shownHighlights =  [[NSUserDefaults standardUserDefaults] boolForKey: @"shownHighlights"];
    return !shownHighlights && self.pastDays.count;
}

#pragma mark - UITableView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.navigationController.navigationBar.frame;
    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + self.labelSwitch.frame.size.height);
    CGFloat size = frame.size.height - 20;
    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat scrollDiff = scrollOffset - self.previousScrollViewYOffset;
    CGFloat scrollHeight = scrollView.frame.size.height;
    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;
    
    if (scrollOffset <= -scrollView.contentInset.top) {
        frame.origin.y = 20;
    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
        frame.origin.y = -size;
    } else {
        // HACK to prevent the app to go up and down.
        if (frame.origin.y == 20 && scrollOffset == - 60) {
            frame.origin.y = 20;
        }
        else {
            frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
        }
    }
   
    self.navigationController.navigationBar.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - self.labelSwitch.frame.size.height);
    
    self.labelSwitch.frame = CGRectMake(frame.origin.x, frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.labelSwitch.frame.size.width, self.labelSwitch.frame.size.height);
    self.labelSwitch.transparency  = 1 - framePercentageHidden;
    
    if (self.navigationController.navigationBar.frame.origin.y +
        self.navigationController.navigationBar.frame.size.height <= 20) {
        self.blueBannerView.hidden = NO;
    }
    else {
        self.blueBannerView.hidden = YES;
    }
    
    [self updateBarButtonItems:(1 - framePercentageHidden)];
    self.previousScrollViewYOffset = scrollOffset;
    if (scrollView.contentOffset.x != 0) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
    }
}


- (void)stoppedScrolling
{
    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < 20) {
        [self animateNavBarTo:-(frame.size.height - 21)];
    }
}

- (void)updateBarButtonItems:(CGFloat)alpha
{
//    [self.tabBarController.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
//        item.customView.alpha = alpha;
//    }];
    [self.tabBarController.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.tabBarController.navigationItem.titleView.alpha = alpha;
//    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}

- (void)animateNavBarTo:(CGFloat)y
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.navigationController.navigationBar setFrame:frame];
        [self updateBarButtonItems:alpha];
    }];
}


#pragma mark - ToolTip 

- (void)showToolTip {
    NSArray *arrayTooltip = WGProfile.currentUser.arrayTooltipTracked;
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] ;
    NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
    int weekday = (int)comps.weekday;
    NSString *weekdayString = [NSString stringWithFormat:@"%d", weekday];
    BOOL didShowToday = (arrayTooltip.count > 0) && [arrayTooltip containsObject:weekdayString];
    if ((weekday == 5 || weekday == 6 || weekday == 7) &&  !didShowToday && !_blackViewOnTop) {
        _blackViewOnTop = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
        _blackViewOnTop.backgroundColor = RGBAlpha(0, 0, 0, 0.9f);
        [self.view addSubview:_blackViewOnTop];
        
        UIImageView *tooltipImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 110, 0, 220, 80)];
        tooltipImageView.image = [UIImage imageNamed:@"tooltipRectangle"];
        [_blackViewOnTop addSubview:tooltipImageView];
        
        UILabel *tooltipLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, tooltipImageView.frame.size.width - 15, tooltipImageView.frame.size.height - 10)];
        tooltipLabel.numberOfLines = 0;
        tooltipLabel.textAlignment = NSTextAlignmentCenter;
        NSMutableAttributedString *mutAttributedString = [[NSMutableAttributedString alloc] initWithString:@"Peek at trending\nWigo schools"];
        [mutAttributedString addAttribute:NSForegroundColorAttributeName
                                    value:[FontProperties getBlueColor]
                                    range:NSMakeRange(0, 4)];
        [mutAttributedString addAttribute:NSForegroundColorAttributeName
                                    value:RGB(162, 162, 162)
                                    range:NSMakeRange(4, mutAttributedString.string.length - 4)];
        tooltipLabel.attributedText = mutAttributedString;
        [tooltipImageView addSubview:tooltipLabel];
        

        UIButton *gotItButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 65, 150, 130, 40)];
        [gotItButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [gotItButton setTitle:@"GOT IT" forState:UIControlStateNormal];
        gotItButton.layer.borderColor = UIColor.whiteColor.CGColor;
        gotItButton.layer.borderWidth = 1.0f;
        gotItButton.layer.cornerRadius = 5.0f;
        [gotItButton addTarget:self action:@selector(dismissToolTip) forControlEvents:UIControlEventTouchUpInside];
        [_blackViewOnTop addSubview:gotItButton];
        [WGProfile.currentUser addTootltipTracked:weekdayString];
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                return;
            }
            
        }];
    }
}

- (void)dismissToolTip {
    [UIView animateWithDuration:0.5f animations:^{
        _blackViewOnTop.alpha = 0.0f;
    }];
}

#pragma mark - PlacesDelegate

- (void)showHighlights {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shownHighlights"];
    [self.placesTableView reloadData];
}

- (void)showUser:(WGUser *)user {
    self.shouldReloadEvents = NO;
    
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = user;
     profileViewController.userState = OTHER_SCHOOL_USER_STATE;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController pushViewController: profileViewController animated: YES];
}

- (void)presentUserAferModalView:(WGUser *)user forEvent:(WGEvent *)event {
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = user;
    if ([self isPeeking]) profileViewController.userState = OTHER_SCHOOL_USER_STATE;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController pushViewController: profileViewController animated: YES];

}

- (void)presentConversationForUser:(WGUser *)user {
    [self.navigationController pushViewController:[[ConversationViewController alloc] initWithUser:user] animated:YES];
}


- (void)showModalAttendees:(UIViewController *)modal {
    self.shouldReloadEvents = NO;
    [self.navigationController presentViewController:modal animated:YES completion:nil];
}

- (void)showViewController:(UIViewController *)vc {
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
    vc.view.alpha = 0.0f;
    [vc didMoveToParentViewController:self];

    [UIView animateWithDuration:0.3 animations:^{
        vc.view.alpha = 1.0f;
    }];
}

- (void)showConversationForEvent:(WGEvent *)event
               withEventMessages:(WGCollection *)eventMessages
                         atIndex:(int)index {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EventConversationViewController *conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationViewController.event = event;
    if ([self isPeeking] || (!WGProfile.currentUser.crossEventPhotosEnabled && ![event isEqual:WGProfile.currentUser.eventAttending])) {
    }
    else {
        eventMessages = [self eventMessagesWithCamera:eventMessages];
    }
    conversationViewController.index = [NSNumber numberWithInt:index];
    conversationViewController.eventMessages = eventMessages;
    conversationViewController.isPeeking = [self isPeeking];
    [self presentViewController:conversationViewController animated:YES completion:nil];
}

- (WGCollection *)eventMessagesWithCamera:(WGCollection *)eventMessages {
    WGCollection *newEventMessages =  [[WGCollection alloc] initWithType:[WGEventMessage class]];
    [newEventMessages addObjectsFromCollection:eventMessages];
    WGEventMessage *eventMessage = [WGEventMessage serialize:@{
                                                               @"user": WGProfile.currentUser,
                                                               @"created": [NSDate nowStringUTC],
                                                               @"media_mime_type": kCameraType,
                                                               @"media": @""
                                                               }];
    
    [newEventMessages insertObject:eventMessage atIndex:0];
    
    return newEventMessages;
}

- (void)showConversationForEvent:(WGEvent *)event {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.shouldReloadEvents = NO;
    
    WGCollection *temporaryEventMessages = [[WGCollection alloc] initWithType:[WGEventMessage class]];
    [temporaryEventMessages addObject:event.highlight];

    EventConversationViewController *conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationViewController.event = event;
    conversationViewController.eventMessages = temporaryEventMessages;
    conversationViewController.isPeeking = [self isPeeking];
    
    [self presentViewController:conversationViewController animated:YES completion:nil];
    __weak typeof(conversationViewController) weakConversationViewController =
    conversationViewController;
    __weak typeof(event) weakEvent = event;
    [event getMessagesForHighlights:event.highlight
                        withHandler:^(WGCollection *collection, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        weakConversationViewController.eventMessages = collection;
        weakConversationViewController.mediaScrollView.eventMessages = collection;
        NSInteger messageIndex = [collection indexOfObject:weakEvent.highlight];
        [weakConversationViewController.facesCollectionView reloadData];
        [weakConversationViewController.mediaScrollView reloadData];
        weakConversationViewController.index = @(messageIndex);
        [weakConversationViewController highlightCellAtPage:messageIndex animated:NO];
//        if (messageIndex == NSNotFound) {
//            [weakSelf addNextPageForEventConversationUntilFound:weakConversationViewController
//                                                       forEvent:weakEvent];
//        }
//        else {
//            [weakConversationViewController.facesCollectionView reloadData];
//            [weakConversationViewController.mediaScrollView reloadData];
//            weakConversationViewController.index = @(messageIndex);
//            [weakConversationViewController highlightCellAtPage:messageIndex animated:NO];
//        }
        
    }];
}

- (void)addNextPageForEventConversationUntilFound:(EventConversationViewController *)eventConversationViewController forEvent:(WGEvent *)event {
    
    __weak typeof(eventConversationViewController) weakEventConversation = eventConversationViewController;
    __weak typeof(self) weakSelf = self;
    __weak  typeof(event) weakEvent = event;
    [eventConversationViewController.eventMessages addNextPage:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        weakEventConversation.mediaScrollView.eventMessages = weakEventConversation.eventMessages;
        NSInteger messageIndex = [weakEventConversation.eventMessages indexOfObject:weakEvent.highlight];
        if (messageIndex == NSNotFound) {
            [weakSelf addNextPageForEventConversationUntilFound:weakEventConversation
                                                       forEvent:weakEvent];
        }
        else {
            [weakEventConversation.facesCollectionView reloadData];
            [weakEventConversation.mediaScrollView reloadData];
            weakEventConversation.index = @(messageIndex);
            [weakEventConversation highlightCellAtPage:messageIndex animated:NO];
        }
    }];

    
}


- (void)setGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName {
    if (![WGProfile.currentUser.group.id isEqual:groupID]) {
        [WGProfile setPeekingGroupID:groupID];
    }
    else {
        [WGProfile setPeekingGroupID:nil];
    }
    self.eventOffsetDictionary = [NSMutableDictionary new];
    self.groupNumberID = groupID;
    self.groupName = groupName;
    self.pastDays = [[NSMutableArray alloc] init];
    self.events = [[WGCollection alloc] initWithType:[WGEvent class]];
    self.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
    self.allEvents = nil;
    [self.placesTableView reloadData];
    self.spinnerAtCenter = YES;
    [self fetchEventsFirstPage];
}

- (void)presentViewWithGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName {
    self.presentingLockedView = YES;
    UIButtonAligned *leftButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 10, 30, 30) andType:@2];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 8, 8, 14)];
    imageView.image = [UIImage imageNamed:@"backToBattery"];
    [leftButton addTarget:self action:@selector(backPressed)
         forControlEvents:UIControlEventTouchUpInside];
    [leftButton addSubview:imageView];
    [leftButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.tabBarController.navigationItem.leftBarButtonItem = leftBarButton;
}

- (void)backPressed {
    self.presentingLockedView = NO;
    
    BatteryViewController *batteryViewController = [BatteryViewController new];
    
    UIImage* imageOfUnderlyingView = [[UIApplication sharedApplication].keyWindow convertViewToImage];
    imageOfUnderlyingView = [imageOfUnderlyingView applyBlurWithRadius:10
                                                             tintColor:RGBAlpha(0, 0, 0, 0.75)
                                                 saturationDeltaFactor:1.3
                                                             maskImage:nil];
    batteryViewController.blurredBackgroundImage = imageOfUnderlyingView;
    batteryViewController.placesDelegate = self;
    [self presentViewController:batteryViewController animated:YES completion:nil];
}


- (int)createUniqueIndexFromUserIndex:(int)userIndex andEventIndex:(int)eventIndex {
    int numberOfEvents = (int)self.events.count;
    return numberOfEvents * userIndex + eventIndex;
}

- (NSDictionary *)getUserIndexAndEventIndexFromUniqueIndex:(int)uniqueIndex {
    int userIndex, eventIndex;
    int numberOfEvents = (int)self.events.count;
    userIndex = uniqueIndex / numberOfEvents;
    eventIndex = uniqueIndex - userIndex * numberOfEvents;
    return @{ @"userIndex": [NSNumber numberWithInt:userIndex], @"eventIndex" : [NSNumber numberWithInt:eventIndex] };
}

- (void)reloadTable {
    [self.placesTableView reloadData];
}

#pragma mark - EventPeopleScrollView Delegate

- (void) startAnimatingAtTop:(id)sender
      finishAnimationHandler:(CollectionViewResultBlock)handler
              postingHandler:(BoolResultBlock)postHandler
{
    if (self.fetchingEventAttendees) return;
    
    // First start doing the network request
    WGProfile.tapAll = NO;
    [WGAnalytics tagAction:@"go_here" atView:@"where"];
    self.whereAreYouGoingTextField.text = @"";
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    
    __weak typeof(self) weakSelf = self;
    WGEvent *event = [self getEventAtIndexPath:[NSIndexPath indexPathForItem:buttonSender.tag inSection:0]];
    if (event == nil) return;
    [WGProfile.currentUser goingToEvent:event withHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            postHandler(success, error);
            return;
        }
        WGProfile.currentUser.isGoingOut = @YES;
        if (!strongSelf.doNotReloadOffsets) {
            for (NSString *key in [strongSelf.eventOffsetDictionary allKeys]) {
                [strongSelf.eventOffsetDictionary setValue:@0 forKey:key];
            }
            strongSelf.doNotReloadOffsets = NO;
        }
        strongSelf.aggregateEvent = nil;
        strongSelf.allEvents = nil;
        [strongSelf fetchEventsWithoutReloadingWithHandler:postHandler];
    }];
    
    
    // Then start the animations
    WGEvent *oldEvent = (WGEvent *)[self.events objectAtIndex:0];
    [self.events replaceObjectAtIndex:0 withObject:[self.events objectAtIndex:buttonSender.tag]];
    [self.events replaceObjectAtIndex:buttonSender.tag withObject:oldEvent];
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        // animation has finished
        [self.placesTableView reloadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            EventCell *cell = (EventCell *)[self.placesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            UICollectionView *eventPeopleScrollView = cell.eventPeopleScrollView;
            UICollectionViewCell *scrollCell = [eventPeopleScrollView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            handler(scrollCell);
        });
       
    }];
    
    [self.placesTableView beginUpdates];
    [self.placesTableView moveRowAtIndexPath:[NSIndexPath indexPathForItem:buttonSender.tag inSection:0] toIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    [self.placesTableView endUpdates];
    [self scrollUp];

    [CATransaction commit];
}



- (void)fetchEventsWithoutReloadingWithHandler:(BoolResultBlock)handler {
    if (self.fetchingEventAttendees) handler(NO, nil);
    if (!WGProfile.currentUser.key)  handler(NO, nil);
    
    self.fetchingEventAttendees = YES;
    __weak typeof(self) weakSelf = self;
    [WGEvent get:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        strongSelf.fetchingEventAttendees = NO;
        if (error) {
            handler(NO, error);
            return;
        }
        strongSelf.allEvents = collection;
        strongSelf.pastDays = [[NSMutableArray alloc] init];
        strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
        strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
        strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
        if (strongSelf.allEvents.count > 0) {
            WGEvent *aggregateEvent = (WGEvent *)[strongSelf.allEvents objectAtIndex:0];
            if (aggregateEvent.isAggregate) {
                strongSelf.aggregateEvent = aggregateEvent;
                [strongSelf.allEvents removeObjectAtIndex:0];
            }
            else strongSelf.aggregateEvent = nil;
        }
        for (WGEvent *event in strongSelf.allEvents) {
            if ([event.isExpired boolValue]) {
                [strongSelf.oldEvents addObject:event];
            } else {
                [strongSelf.events addObject:event];
            }
        }
        
        for (WGEvent *event in strongSelf.oldEvents) {
            if (![event highlight]) {
                continue;
            }
            NSString *eventDate = [[event expires] deserialize];
            if ([strongSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                [strongSelf.pastDays addObject: eventDate];
                [strongSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
            }
            [[strongSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
        }
        
        handler(YES, error);
    }];
}

#pragma mark - Network Asynchronous Functions

- (void) fetchEventsFirstPage {
    if (!self.doNotReloadOffsets) {
        for (NSString *key in [self.eventOffsetDictionary allKeys]) {
            [self.eventOffsetDictionary setValue:@0 forKey:key];
        }
        self.doNotReloadOffsets = NO;
    }
    if (!self.shouldReloadEvents) return;
    else self.shouldReloadEvents = YES;
    self.aggregateEvent = nil;
    self.allEvents = nil;
    [self fetchEventsWithHandler:^(BOOL success, NSError *error) {}];
}

- (void) fetchEventsWithHandler:(BoolResultBlock)handler {
    if (self.fetchingEventAttendees) handler(NO, nil);
    if (!WGProfile.currentUser.key) handler(NO, nil);
   
    self.fetchingEventAttendees = YES;
    if (self.spinnerAtCenter && ![WGSpinnerView isDancingGInCenterView:self.view]) {
        [WGSpinnerView addDancingGToCenterView:self.view];
    }
    __weak typeof(self) weakSelf = self;
    if (self.allEvents) {
        if (!self.allEvents.hasNextPage.boolValue) handler(NO, nil);
       
        [self.allEvents addNextPage:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf removeDancingG];
            strongSelf.fetchingEventAttendees = NO;
            if (error) {
                strongSelf.shouldReloadEvents = YES;
                handler(success, error);
                return;
            }
            
            strongSelf.pastDays = [[NSMutableArray alloc] init];
            strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
            strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
            
            strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
            for (WGEvent *event in strongSelf.allEvents) {
                
                if (event) {
                    if ([event.isExpired boolValue]) {
                        [strongSelf.oldEvents addObject:event];
                    } else {
                        [strongSelf.events addObject:event];
                    }
                }
            }
            
            for (WGEvent *event in strongSelf.oldEvents) {
                if (![event highlight]) {
                    continue;
                }
                NSString *eventDate = [[event expires] deserialize];
                if (eventDate) {
                    if ([strongSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                        [strongSelf.pastDays addObject: eventDate];
                        [strongSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                    }
                    [[strongSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
                }
            }
            
            strongSelf.shouldReloadEvents = YES;
            [strongSelf.placesTableView reloadData];
            handler(success, error);
        }];
        
    } else if (self.groupNumberID) {
        [WGEvent getWithGroupNumber:self.groupNumberID andHandler:^(WGCollection *collection, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.fetchingEventAttendees = NO;
            [strongSelf removeDancingG];
            if (error) {
                strongSelf.shouldReloadEvents = YES;
                handler(NO, error);
                return;
            }
            
            strongSelf.allEvents = collection;
            strongSelf.pastDays = [[NSMutableArray alloc] init];
            strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
            strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
            strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
            
            if (strongSelf.allEvents.count > 0) {
                WGEvent *aggregateEvent = (WGEvent *)[strongSelf.allEvents objectAtIndex:0];
                if (aggregateEvent.isAggregate) {
                    strongSelf.aggregateEvent = aggregateEvent;
                    [strongSelf.allEvents removeObjectAtIndex:0];
                    
                }
                else strongSelf.aggregateEvent = nil;
            }
            
            for (WGEvent *event in strongSelf.allEvents) {
                if (event) {
                    if ([event.isExpired boolValue]) {
                        [strongSelf.oldEvents addObject:event];
                    } else {
                        [strongSelf.events addObject:event];
                    }
                }
            }
            
            for (WGEvent *event in strongSelf.oldEvents) {
                if (![event highlight]) {
                    continue;
                }
                NSString *eventDate = [[event expires] deserialize];
                if (eventDate) {
                    if ([strongSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                        [strongSelf.pastDays addObject: eventDate];
                        [strongSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                    }
                    [[strongSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
                }
            }
            
            strongSelf.fetchingEventAttendees = NO;
            [strongSelf.placesTableView reloadData];
            handler(YES, error);
        }];
    } else {
        [WGEvent get:^(WGCollection *collection, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.fetchingEventAttendees = NO;
            [strongSelf removeDancingG];
            if (error) {
                handler(NO, error);
                return;
            }
            strongSelf.allEvents = collection;
            strongSelf.pastDays = [[NSMutableArray alloc] init];
            strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
            strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
            strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
            if (strongSelf.allEvents.count > 0) {
                WGEvent *aggregateEvent = (WGEvent *)[strongSelf.allEvents objectAtIndex:0];
                if (aggregateEvent.isAggregate) {
                    strongSelf.aggregateEvent = aggregateEvent;
                    [strongSelf.allEvents removeObjectAtIndex:0];
                }
                else strongSelf.aggregateEvent = nil;
            }
            for (WGEvent *event in strongSelf.allEvents) {
                if ([event.isExpired boolValue]) {
                    [strongSelf.oldEvents addObject:event];
                } else {
                    [strongSelf.events addObject:event];
                }
            }
            
            for (WGEvent *event in strongSelf.oldEvents) {
                if (![event highlight]) {
                    continue;
                }
                NSString *eventDate = [[event expires] deserialize];
                if ([strongSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                    [strongSelf.pastDays addObject: eventDate];
                    [strongSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                }
                [[strongSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
            }

            [strongSelf.placesTableView reloadData];
            handler(YES, error);
        }];
    }
}


- (void)setAggregateEvent:(WGEvent *)aggregateEvent {
    _aggregateEvent = aggregateEvent;
    if (aggregateEvent == nil) return;
    __weak typeof(self) weakSelf = self;
    [WGEvent getAggregateStatsWithHandler:^(NSNumber *numMessages, NSNumber *numAttending, NSError *error) {
        weakSelf.aggregateEvent.numAttending = numAttending;
    }];
}

- (void)removeDancingG {
    self.spinnerAtCenter ? [WGSpinnerView removeDancingGFromCenterView:self.view] : [self.placesTableView didFinishPullToRefresh];
     self.spinnerAtCenter = NO;
}

- (void) fetchUserInfo {
    __weak typeof(self) weakSelf = self;
    if (self.fetchingUserInfo) return;
    if (!WGProfile.currentUser.key) return;
    
    self.fetchingUserInfo = YES;
    [WGProfile reload:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.fetchingUserInfo = NO;
        
        if (!strongSelf.secondTimeFetchingUserInfo) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"presentPush" object:nil];
            strongSelf.secondTimeFetchingUserInfo = YES;
            if (
                (error || ![WGProfile.currentUser.emailValidated boolValue] ||
                [WGProfile.currentUser.group.locked boolValue])
                
                &&
                
                !strongSelf.presentingLockedView )
            {
                [strongSelf showFlashScreen];
                [strongSelf.signViewController reloadedUserInfo:success andError:error];
                return;
            }
        }
        
        // Second time fetching user info... already logged in
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        if (!strongSelf.presentingLockedView) {
            [strongSelf showReferral];
            [strongSelf showToolTip];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canFetchAppStartup"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchAppStart" object:nil];
        [strongSelf.placesTableView reloadData];
        UITabBarController *tab= self.tabBarController;
        ProfileViewController *profileVc = (ProfileViewController *)[tab.viewControllers objectAtIndex:3];
        profileVc.user = WGProfile.currentUser;
    }];
   
}


#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    CGFloat contentInset = 44 + [LabelSwitch height];
    self.placesTableView.contentInset = UIEdgeInsetsMake(contentInset, 0, 0, 0);
    [WGSpinnerView addDancingGToUIScrollView:self.placesTableView
                         withBackgroundColor:RGB(237, 237, 237)
                            withContentInset:contentInset
                                 withHandler:^{
        self.spinnerAtCenter = NO;
        [self fetchEventsFirstPage];
        [self fetchUserInfo];
    }];
}

- (void)addProfileUserToEventWithNumber:(int)eventID {
    WGEvent *event = (WGEvent *)[self.events objectWithID:[NSNumber numberWithInt:eventID]];
    [self removeProfileUserFromAnyOtherEvent];
    [event.attendees insertObject:WGProfile.currentUser atIndex:0];
    event.numAttending = @([event.numAttending intValue] + 1);
    [self.events exchangeObjectAtIndex:[self.events indexOfObject:event] withObjectAtIndex:0];
}

-(void) removeProfileUserFromAnyOtherEvent {
    for (WGEvent* event in self.events) {
        if ([event.attendees containsObject:WGProfile.currentUser]) {
            [event.attendees removeObject:WGProfile.currentUser];
            event.numAttending = @(event.numAttending.intValue - 1);
        }
    }
}

@end

#pragma mark - Cells

@implementation EventCell

+ (CGFloat)height {
    return 20 + 64 + [EventPeopleScrollView containerHeight] + [HighlightCell height] + 50 + 10;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [EventCell height]);
    self.contentView.frame = self.frame;
    self.backgroundColor = RGB(237, 237, 237);
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 20)];
    backgroundView.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:backgroundView];
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.center.x - 20, self.center.y - 20, 40, 40)];
    self.loadingView.hidden = YES;
    [backgroundView addSubview:self.loadingView];
    
    self.privacyLockButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 0, 30, 53)];
    [backgroundView addSubview:self.privacyLockButton];
    
    self.privacyLockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 26.5 - 8., 12, 16)];
    self.privacyLockImageView.image = [UIImage imageNamed:@"veryBlueLockClosed"];
    self.privacyLockImageView.hidden = YES;
    [self.privacyLockButton addSubview:self.privacyLockImageView];
    
    self.eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 16.5, self.frame.size.width - 40, 20)];
    self.eventNameLabel.textAlignment = NSTextAlignmentLeft;
    self.eventNameLabel.numberOfLines = 2;
    self.eventNameLabel.font = [FontProperties semiboldFont:18.0f];
    self.eventNameLabel.textColor = [FontProperties getBlueColor];
    [backgroundView addSubview:self.eventNameLabel];
    
    self.verifiedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 16.5, 20, 20)];
    self.verifiedImageView.image = [UIImage imageNamed:@"dancingG-0"];
    self.verifiedImageView.hidden = YES;
    [self.contentView addSubview:self.verifiedImageView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, 53, 85, 0.5)];
    lineView.backgroundColor = RGB(215, 215, 215);
    [backgroundView addSubview:lineView];
    
    self.numberOfPeopleGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40 + 20, self.frame.size.width, 20)];
    self.numberOfPeopleGoingLabel.textColor = RGB(119, 119, 119);
    self.numberOfPeopleGoingLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfPeopleGoingLabel.font = [FontProperties lightFont:15.0f];
    [backgroundView addSubview:self.numberOfPeopleGoingLabel];

    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    self.eventPeopleScrollView.widthOfEachCell = 0.9*(float)[[UIScreen mainScreen] bounds].size.width/(float)5.5;
    self.eventPeopleScrollView.frame = CGRectMake(0, 20 + 60 + 9, self.frame.size.width, self.eventPeopleScrollView.widthOfEachCell + 20);
    self.eventPeopleScrollView.backgroundColor = UIColor.clearColor;
    [backgroundView addSubview:self.eventPeopleScrollView];
    
    self.numberOfHighlightsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 15, self.frame.size.width, 20)];
    self.numberOfHighlightsLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfHighlightsLabel.textColor = RGB(119, 119, 119);
    self.numberOfHighlightsLabel.font = [FontProperties lightFont:15.0f];
    self.numberOfHighlightsLabel.alpha = 1.0f;
    self.numberOfHighlightsLabel.text = @"The Buzz";
    [backgroundView addSubview:self.numberOfHighlightsLabel];
    
    self.highlightsCollectionView = [[HighlightsCollectionView alloc]
                                     initWithFrame:CGRectMake(0, self.numberOfHighlightsLabel.frame.origin.y + self.numberOfHighlightsLabel.frame.size.height + 5, self.frame.size.width, [HighlightCell height])
                                     collectionViewLayout:[HighlightsFlowLayout new]];
    [backgroundView addSubview:self.highlightsCollectionView];
}

- (void)setEvent:(WGEvent *)event {
    _event = event;
    self.highlightsCollectionView.event = _event;
    self.eventNameLabel.text = _event.name;
    if (_event.numAttending.intValue > 0) {
        self.numberOfPeopleGoingLabel.text = [NSString stringWithFormat:@"%@ going", _event.numAttending];
    }
    else {
        self.numberOfPeopleGoingLabel.text = @"Going";
    }

    CGSize size = [_event.name sizeWithAttributes:
                @{NSFontAttributeName:[FontProperties semiboldFont:18.0f]}];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (size.width > self.eventNameLabel.frame.size.width) {
            self.eventNameLabel.frame = CGRectMake(10, 3, self.frame.size.width - 40, 50);
        }
        else {
            self.eventNameLabel.frame = CGRectMake(10, 16.5, self.frame.size.width - 40, 20);
        }
    });
    
    self.privacyLockImageView.hidden = !_event.isPrivate;
    self.privacyLockButton.enabled = _event.isPrivate;
    self.eventPeopleScrollView.event = _event;
    if (_event.isVerified) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.verifiedImageView.hidden = NO;
            self.eventNameLabel.frame = CGRectMake(self.eventNameLabel.frame.origin.x + 23, self.eventNameLabel.frame.origin.y, self.eventNameLabel.frame.size.width, self.eventNameLabel.frame.size.height);
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.verifiedImageView.hidden = YES;
        });
    }
}

@end

@implementation TodayHeader

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

+ (instancetype) initWithDay: (NSDate *) date {
    TodayHeader *header = [[TodayHeader alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [TodayHeader height])];
    header.date = date;
    [header setup];
    
    return header;
}

- (void) setup {

}

+ (CGFloat) height {
    return 0.5f;
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
    self.backgroundColor = RGB(237, 237, 237);

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
    self.backgroundColor = RGB(237, 237, 237);
    
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
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.text = [dayName lowercaseString];
    titleLabel.center = CGPointMake(self.center.x, titleLabel.center.y);
    [self addSubview: titleLabel];
    
    if (self.isFirst) {
        UILabel *highlights = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.width, 20)];
        highlights.backgroundColor = [UIColor clearColor];
        highlights.textAlignment = NSTextAlignmentCenter;
        highlights.font = [FontProperties scMediumFont: 13.0f];
        highlights.textColor = RGB(180, 180, 180);
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

+ (CGFloat) height {
    return 20 + 64 + [EventPeopleScrollView containerHeight] + [HighlightCell height] + 50 + 10;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [EventCell height]);
    self.contentView.frame = self.frame;
    self.backgroundColor = RGB(210, 210, 210);
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 20)];
    backgroundView.backgroundColor = RGB(230, 230, 230);
    backgroundView.layer.shadowColor = RGBAlpha(0, 0, 0, 0.1f).CGColor;
    backgroundView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    backgroundView.layer.shadowRadius = 4.0f;
    backgroundView.layer.shadowOpacity = 1.0f;
    [self.contentView addSubview:backgroundView];
    
    self.privacyLockButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 0, 30, 53)];
    [backgroundView addSubview:self.privacyLockButton];
    
    self.privacyLockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 26.5 - 8., 12, 16)];
    self.privacyLockImageView.image = [UIImage imageNamed:@"veryBlueLockClosed"];
    self.privacyLockImageView.hidden = YES;
    [self.privacyLockButton addSubview:self.privacyLockImageView];
    
    self.eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 16.5, self.frame.size.width - 40, 20)];
    self.eventNameLabel.textAlignment = NSTextAlignmentLeft;
    self.eventNameLabel.numberOfLines = 2;
    self.eventNameLabel.font = [FontProperties semiboldFont:18.0f];
    self.eventNameLabel.textColor = UIColor.blackColor;
    [backgroundView addSubview:self.eventNameLabel];
    
    self.verifiedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 16.5, 20, 20)];
    self.verifiedImageView.image = [UIImage imageNamed:@"dancingG-0"];
    self.verifiedImageView.hidden = YES;
    [self.contentView addSubview:self.verifiedImageView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, 53, 85, 0.5)];
    lineView.backgroundColor = RGB(215, 215, 215);
    [backgroundView addSubview:lineView];
    
    self.numberOfPeopleGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40 + 20, self.frame.size.width, 20)];
    self.numberOfPeopleGoingLabel.textColor = RGB(119, 119, 119);
    self.numberOfPeopleGoingLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfPeopleGoingLabel.font = [FontProperties lightFont:15.0f];
    [backgroundView addSubview:self.numberOfPeopleGoingLabel];
    
    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    self.eventPeopleScrollView.widthOfEachCell = 0.9*(float)[[UIScreen mainScreen] bounds].size.width/(float)5.5;
    self.eventPeopleScrollView.frame = CGRectMake(0, 20 + 60 + 9, self.frame.size.width, self.eventPeopleScrollView.widthOfEachCell + 20);
    self.eventPeopleScrollView.backgroundColor = UIColor.clearColor;
    [backgroundView addSubview:self.eventPeopleScrollView];
    
    self.numberOfHighlightsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 15, self.frame.size.width, 20)];
    self.numberOfHighlightsLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfHighlightsLabel.textColor = RGB(119, 119, 119);
    self.numberOfHighlightsLabel.font = [FontProperties lightFont:15.0f];
    self.numberOfHighlightsLabel.alpha = 1.0f;
    self.numberOfHighlightsLabel.text = @"The Buzz";
    [backgroundView addSubview:self.numberOfHighlightsLabel];
    
    self.highlightsCollectionView = [[HighlightsCollectionView alloc]
                                     initWithFrame:CGRectMake(0, self.numberOfHighlightsLabel.frame.origin.y + self.numberOfHighlightsLabel.frame.size.height + 5, self.frame.size.width, [HighlightCell height])
                                     collectionViewLayout:[HighlightsFlowLayout new]];
    [backgroundView addSubview:self.highlightsCollectionView];
    
}

- (void)loadConversation {
    [self.placesDelegate showConversationForEvent:self.event];
}

- (void)setEvent:(WGEvent *)event {
    _event = event;
    self.highlightsCollectionView.event = _event;
    self.eventNameLabel.text = _event.name;
    if (_event.numAttending.intValue > 0) {
        self.numberOfPeopleGoingLabel.text = [NSString stringWithFormat:@"%@ going", _event.numAttending];
    }
    else {
        self.numberOfPeopleGoingLabel.text = @"Going";
    }
    CGSize size = [_event.name sizeWithAttributes:
                   @{NSFontAttributeName:[FontProperties semiboldFont:18.0f]}];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (size.width > self.eventNameLabel.frame.size.width) {
            self.eventNameLabel.frame = CGRectMake(10, 3, self.frame.size.width - 40, 50);
        }
        else {
            self.eventNameLabel.frame = CGRectMake(10, 16.5, self.frame.size.width - 40, 20);
        }
    });
    
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
