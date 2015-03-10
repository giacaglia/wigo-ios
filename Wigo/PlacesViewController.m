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
#import "MobileContactsViewController.h"
#import "InviteViewController.h"
#import "SignNavigationViewController.h"
#import "PeekViewController.h"
#import "EventStoryViewController.h"
#import "ProfileViewController.h"
#import "FXBlurView.h"
#import "ChatViewController.h"
#import "BatteryViewController.h"
#import "UIView+ViewToImage.h"
#import "UIImage+ImageEffects.h"
#import "ReferalViewController.h"
#import "PrivateSwitchView.h"
#import "EventMessagesConstants.h"


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

// Events Summary

// Go OUT Button
@property UIButtonUngoOut *ungoOutButton;
@property BOOL spinnerAtCenter;

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

    self.view.backgroundColor = UIColor.whiteColor;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.fetchingUserInfo = NO;
    self.fetchingEventAttendees = NO;
    presentedMobileContacts = NO;
    self.shouldReloadEvents = YES;
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
    [self.placesTableView reloadData];

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
    if (![WGProfile currentUser].key && !self.presentingLockedView) {
        [self showFlashScreen];
        [self.signViewController reloadedUserInfo:NO andError:nil];
    }

    [self.view endEditing:YES];
    if (self.shouldReloadEvents) {
        [self fetchEventsFirstPage];
    } else {
        self.shouldReloadEvents = YES;
    }
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
        (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id])){
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
    if (![WGProfile currentUser].group.id) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    } else if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
        CGRect profileFrame = CGRectMake(3, 0, 30, 30);
        UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
        profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
        profileImageView.layer.borderWidth = 1.0f;
        profileImageView.layer.cornerRadius = profileFrame.size.height/2;
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        [profileImageView setSmallImageForUser:WGProfile.currentUser completed:nil];
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
        if (WGProfile.currentUser.numUnreadNotifications.intValue > 0 || WGProfile.currentUser.numUnreadConversations.intValue > 0) {
            self.leftRedDotLabel.hidden = NO;
        } else {
            self.leftRedDotLabel.hidden = YES;
        }
        UIBarButtonItem *profileBarButton = [[UIBarButtonItem alloc] initWithCustomView:profileButton];
        self.navigationItem.leftBarButtonItem = profileBarButton;
        
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
        self.navigationItem.rightBarButtonItem = rightBarButton;

    }
    else if (self.presentingLockedView) {
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }

    [self updateTitleView];
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
                                             selector:@selector(updateViewNotGoingOut)
                                                 name:@"updateViewNotGoingOut"
                                               object:nil];
    
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
}

- (void)goToChat:(NSNotification *)notification {
    ProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    [fancyProfileViewController setStateWithUser: [WGProfile currentUser]];
    fancyProfileViewController.events = self.events;
    [self.navigationController pushViewController: fancyProfileViewController animated: NO];
    
    ChatViewController *chatViewController = [ChatViewController new];
    chatViewController.view.backgroundColor = UIColor.whiteColor;
    [fancyProfileViewController.navigationController pushViewController:chatViewController animated:YES];
}

- (void)goToProfile {
    ProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
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
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
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
    [self.placesTableView setContentOffset:CGPointZero animated:YES];
}

- (void) updateViewNotGoingOut {
    [WGProfile currentUser].isGoingOut = @NO;
    [self fetchEventsFirstPage];
}

- (void) updateTitleView {
    if (!self.groupName) self.groupName = WGProfile.currentUser.group.name;
    self.schoolButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.schoolButton setTitle:self.groupName forState:UIControlStateNormal];
    [self.schoolButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.schoolButton addTarget:self action:@selector(showSchools) forControlEvents:UIControlEventTouchUpInside];
    self.schoolButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  
    CGFloat fontSize = 16.0f;
    CGSize size;
    while (fontSize > 0.0f)
    {
        size = [self.groupName sizeWithAttributes:
                @{NSFontAttributeName:[FontProperties mediumFont:fontSize]}];
        if (size.width <= 210) break;
        
        fontSize -= 2.0;
    }
    self.schoolButton.titleLabel.font = [FontProperties scMediumFont:fontSize];
    self.schoolButton.frame = CGRectMake(0, 0, size.width, size.height);
    UIImageView *triangleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(size.width + 10, size.height/2 - 3, 6, 5)];
    [self.schoolButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    triangleImageView.image = [UIImage imageNamed:@"whiteTriangle"];
    [self.schoolButton addSubview:triangleImageView];

    self.navigationItem.titleView = self.schoolButton;
    if (self.presentingLockedView) self.schoolButton.enabled = NO;
    else self.schoolButton.enabled = YES;
}

- (void)showSchools {
    if (_blackViewOnTop) _blackViewOnTop.alpha = 0.0f;
    PeekViewController *peekViewController = [PeekViewController new];
    peekViewController.placesDelegate = self;
    [self presentViewController:peekViewController animated:YES completion:nil];
}

- (void)dismissKeyboard {
    _ungoOutButton.enabled = YES;
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
    self.placesTableView = [[UITableView alloc] initWithFrame: CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64) style: UITableViewStyleGrouped];
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
}


- (void)followPressed {
    if ([WGProfile currentUser].key) {
        if (_blackViewOnTop) _blackViewOnTop.alpha = 0.0f;
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
    self.whereAreYouGoingTextField.text = @"";
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    [self.placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self goOutToEventAtRow:(int)buttonSender.tag];
}

- (void)goOutToEventAtRow:(int)row {
    __weak typeof(self) weakSelf = self;
    
    WGEvent *event = [self getEventAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    if (event == nil) return;
    [WGProfile.currentUser goingToEvent:event withHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
        WGProfile.currentUser.isGoingOut = @YES;
        [strongSelf fetchEventsFirstPage];
        [strongSelf scrollUp];
    }];
}

- (void) goingSomewhereElsePressed {
    [WGAnalytics tagEvent:@"Go Somewhere Else Tapped"];

    [self scrollUp];
    [self showWhereAreYouGoingView];

    
    [UIView animateWithDuration: 0.2 animations:^{
        self.navigationItem.titleView.alpha = 0.0f;
        self.navigationItem.leftBarButtonItem.customView.alpha = 0.0f;
        self.navigationItem.rightBarButtonItem.customView.alpha = 0.0f;
        
        [self.whereAreYouGoingTextField becomeFirstResponder];
        _whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0, 50);
        _whereAreYouGoingView.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        
        [self.navigationItem setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Cancel" style: UIBarButtonItemStylePlain target: self action: @selector(cancelledAddEventTapped)] animated: NO];
        
        [self.navigationItem setRightBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: @"Create" style: UIBarButtonItemStylePlain target: self action: @selector(createPressed)] animated: NO];
        
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

        //[self dismissKeyboard];
        _ungoOutButton.enabled = NO;
        self.placesTableView.userInteractionEnabled = NO;
        [self textFieldDidChange:self.whereAreYouGoingTextField];
    }];
}

- (void) cancelledAddEventTapped {
    [self initializeNavigationBar];
    [self dismissKeyboard];
}

- (void)profileSegue {
    if (_blackViewOnTop) _blackViewOnTop.alpha = 0.0f;
    ProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    [fancyProfileViewController setStateWithUser: [WGProfile currentUser]];
    fancyProfileViewController.events = self.events;
    
    [self.navigationController pushViewController: fancyProfileViewController animated: YES];
    
//    UIView * fromView = self.view;
//    UIView * toView = fancyProfileViewController.view;
//    
//    CGRect viewSize = fromView.frame;
//    [fromView.superview addSubview:toView];
//    toView.frame = CGRectMake( -320 , viewSize.origin.y, 320, viewSize.size.height);
//    
//    [UIView animateWithDuration:0.4 animations:
//     ^{
//         toView.frame =CGRectMake(0, viewSize.origin.y, 320, viewSize.size.height);
//     }
//                     completion:^(BOOL finished)
//     {
//         if (finished)
//         {
//        }
//     }];
    
   
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
    if (!_whereAreYouGoingView) {
        _whereAreYouGoingView = [[UIView alloc] initWithFrame:CGRectMake(0, 14, self.view.frame.size.width, self.view.frame.size.height)];
        _whereAreYouGoingView.backgroundColor = UIColor.whiteColor;
        _whereAreYouGoingView.alpha = 0;
        [self.view addSubview:_whereAreYouGoingView];
        
        UILabel *eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 45, 10, 90, 30)];
        eventNameLabel.text = @"Event Name";
        eventNameLabel.textColor = [FontProperties getBlueColor];
        eventNameLabel.textAlignment = NSTextAlignmentCenter;
        eventNameLabel.font = [FontProperties mediumFont:13.0f];
        [_whereAreYouGoingView addSubview:eventNameLabel];
        
        UIView *lineUnderEventName = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 45, 40, 90, 1)];
        lineUnderEventName.backgroundColor = [FontProperties getBlueColor];
        [_whereAreYouGoingView addSubview:lineUnderEventName];
        
        self.whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 40, _whereAreYouGoingView.frame.size.width, 50)];
        self.whereAreYouGoingTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Where are you going?" attributes:@{NSForegroundColorAttributeName:RGBAlpha(122, 193, 226, 0.5)}];
        self.whereAreYouGoingTextField.font = [FontProperties openSansRegular:18.0f];
        self.whereAreYouGoingTextField.textAlignment = NSTextAlignmentCenter;
        self.whereAreYouGoingTextField.textColor = [FontProperties getBlueColor];
        [[UITextField appearance] setTintColor:[FontProperties getBlueColor]];
        self.whereAreYouGoingTextField.delegate = self;
        [self.whereAreYouGoingTextField addTarget:self
                                           action:@selector(textFieldDidChange:)
                                 forControlEvents:UIControlEventEditingChanged];
        self.whereAreYouGoingTextField.returnKeyType = UIReturnKeyDone;
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
        
        _privateSwitchView = [[PrivateSwitchView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 120, 50, 240, 40)];
        [_eventDetails addSubview:_privateSwitchView];
        _privateSwitchView.privateString = @"Only you can invite people and only\nthose invited can see the event.";
        _privateSwitchView.publicString =  @"The whole school can see and attend your event.";
        _privateSwitchView.privateDelegate = self;
        [_privateSwitchView.closeLockImageView stopAnimating];
        [_privateSwitchView.openLockImageView stopAnimating];
        
        self.invitePeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 92, self.view.frame.size.width, 30)];
        self.invitePeopleLabel.text = _privateSwitchView.explanationString;
        self.invitePeopleLabel.textAlignment = NSTextAlignmentCenter;
        self.invitePeopleLabel.numberOfLines = 2;
        self.invitePeopleLabel.font = [FontProperties openSansRegular:12.0f];
        self.invitePeopleLabel.textColor = [FontProperties getBlueColor];
        [_eventDetails addSubview:self.invitePeopleLabel];
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
    [self textFieldDidChange:self.whereAreYouGoingTextField];
}


- (void)createPressed {
    if ([self.whereAreYouGoingTextField.text length] != 0) {
        WGProfile.currentUser.youAreInCharge = NO;
        self.whereAreYouGoingTextField.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
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
                
                strongSelf.whereAreYouGoingTextField.enabled = YES;
                strongSelf.navigationItem.rightBarButtonItem.enabled = YES;
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
                    
                    [strongOfStrong.placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    
                    [strongOfStrong dismissKeyboard];
                    
                    [WGProfile currentUser].isGoingOut = @YES;
                    [WGProfile currentUser].eventAttending = object;
                    
                    WGEventAttendee *attendee = [[WGEventAttendee alloc] initWithJSON:@{ @"user" : [WGProfile currentUser] }];
                    
                    if ([strongOfStrong.allEvents containsObject:object]) {
                        WGEvent *joinedEvent = (WGEvent *)[strongOfStrong.allEvents objectWithID:object.id];
                        [joinedEvent.attendees insertObject:attendee atIndex:0];
//                        [strongOfStrong showStoryForEvent:joinedEvent];
                    } else {
                        if (object.attendees) {
                            [object.attendees insertObject:attendee atIndex:0];
                        } else {
                            WGCollection *eventAttendees = [WGCollection serializeArray:@[ [attendee deserialize] ] andClass:[WGEventAttendee class]];
                            object.attendees = eventAttendees;
                        }
//                        [strongOfStrong showStoryForEvent:object];
                    }
                }];
            }];
        }];
    }
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
    [self.filteredEvents removeAllObjects];
    
    if([textField.text length] != 0) {
        _isSearching = YES;
        [self searchTableList: textField.text];
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 1.0f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];
        
    } else {
        _isSearching = NO;
        
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes: @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent: 0.5f], NSFontAttributeName: [FontProperties mediumFont: 18.0f]} forState: UIControlStateNormal];

    }

    [self.placesTableView reloadData];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self createPressed];
    return YES;
}

- (void)searchTableList:(NSString *)searchString {
    int index = 0;
    for (WGEvent *event in self.events) {
        NSComparisonResult comparisonResult = [event.name compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
        
        if (comparisonResult == NSOrderedSame && ![self.filteredEvents containsObject:event]) {
            [self.filteredEvents addObject: event];
        }
        
        index += 1;
    }
}

#pragma mark - Tablew View Data Source
#define kTodaySection 0
#define kHighlightsEmptySection 1

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
        return 1 + 1 + self.pastDays.count;
    }
    //[Today section]
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kTodaySection) {
        if (_isSearching) {
            int hasNextPage = ([self.filteredEvents.hasNextPage boolValue] ? 1 : 0);
            return self.filteredEvents.count + hasNextPage;
        } else {
            int hasNextPage = ([self.allEvents.hasNextPage boolValue] ? 1 : 0);
            return self.events.count + hasNextPage + [self shouldShowAggregatePrivateEvents];
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
            return [EventCell heightIsFullCell:NO];
        }
        if (indexPath.row == self.events.count + 1 &&
            [self.allEvents.hasNextPage boolValue] &&
            [self shouldShowAggregatePrivateEvents] == 1) {
            return 1;
        }
        if (indexPath.row == self.events.count &&
            [self.allEvents.hasNextPage boolValue] &&
            [self shouldShowAggregatePrivateEvents] == 1) {
           return 1;
        }
        if (event == nil) return 1;
        return [EventCell heightIsFullCell:NO];
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
        if (indexPath.row == self.events.count &&
            [self shouldShowAggregatePrivateEvents] == 1) {
            cell.event = self.aggregateEvent;
            cell.eventPeopleScrollView.groupID = self.groupNumberID;
            cell.eventPeopleScrollView.placesDelegate = self;
            cell.placesDelegate = self;
            if (![self.eventOffsetDictionary objectForKey:[self.aggregateEvent.id stringValue]]) {
                cell.eventPeopleScrollView.contentOffset = CGPointMake(0, 0);
            }
            [cell updateUI];
            return cell;
        }
        if (_isSearching) {
            if (indexPath.row == self.filteredEvents.count) {
                return cell;
            }
        } else if (indexPath.row == self.events.count && [self shouldShowAggregatePrivateEvents] == 0) {
            [self fetchEvents];
            cell.loadingView.hidden = NO;
            [cell.loadingView startAnimating];
            cell.eventNameLabel.text = nil;
            cell.numberOfPeopleGoingLabel.text = nil;
            cell.privacyLockImageView.hidden = YES;
            [cell.eventPeopleScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            return cell;
        }
        
        WGEvent *event = [self getEventAtIndexPath:indexPath];
        if (event == nil) return cell;

        cell.event = event;
        cell.eventPeopleScrollView.groupID = self.groupNumberID;
        cell.eventPeopleScrollView.placesDelegate = self;
        cell.highlightsCollectionView.placesDelegate = self;
        if (![self.eventOffsetDictionary objectForKey:[event.id stringValue]]) {
            cell.eventPeopleScrollView.contentOffset = CGPointMake(0, 0);
        }
        [cell updateUI];
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
        
        WGEvent *event = [eventObjectArray objectAtIndex:[indexPath row]];
        HighlightOldEventCell *cell = [tableView dequeueReusableCellWithIdentifier:kHighlightOldEventCell
                                       forIndexPath:indexPath];
        cell.event = event;
        cell.placesDelegate = self;
        cell.oldEventLabel.text = event.name;
        if (cell.event.isPrivate) {
            cell.oldEventLabel.transform = CGAffineTransformMakeTranslation(20, 0);
            cell.privateIconImageView.hidden = NO;
        }
        else {
            cell.oldEventLabel.transform = CGAffineTransformMakeTranslation(0, 0);
            cell.privateIconImageView.hidden = YES;
        }
        NSString *contentURL;
        if ([event.highlight.mediaMimeType isEqual:kImageEventType]) {
            contentURL = event.highlight.media;
        }
        else {
            contentURL = event.highlight.thumbnail;
        }
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [[WGProfile currentUser] cdnPrefix], contentURL]];
        [cell.highlightImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];

        return cell;
    }
    return nil;
}

- (BOOL)isFullCellForEvent:(WGEvent *)event {
    return [self isPeeking] || (event.id && [WGProfile.currentUser.eventAttending.id isEqual:event.id]);
}

- (WGEvent *)getEventAtIndexPath:(NSIndexPath *)indexPath {
    WGEvent *event;
    if (_isSearching) {
        int sizeOfArray = (int)self.filteredEvents.count;
        if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return nil;
        event = (WGEvent *)[self.filteredEvents objectAtIndex:[indexPath row]];
    } else {
        int sizeOfArray = (int)self.events.count;
        if (sizeOfArray == 0 || sizeOfArray <= indexPath.row) return nil;
        event = (WGEvent *)[self.events objectAtIndex:indexPath.row];
    }
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
        tooltipLabel.textAlignment = NSTextAlignmentLeft;
        NSMutableAttributedString *mutAttributedString = [[NSMutableAttributedString alloc] initWithString:@"Peek at trending\nWigo schools"];
        [mutAttributedString addAttribute:NSForegroundColorAttributeName
                                    value:[FontProperties getBlueColor]
                                    range:NSMakeRange(0, 4)];
        [mutAttributedString addAttribute:NSForegroundColorAttributeName
                                    value:RGB(162, 162, 162)
                                    range:NSMakeRange(4, mutAttributedString.string.length - 4)];
        tooltipLabel.attributedText = mutAttributedString;
        [tooltipImageView addSubview:tooltipLabel];
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(tooltipImageView.frame.size.width - 23 - 10, tooltipImageView.frame.size.height/2 - 15, 10, 30)];
        [closeButton setTitle:@"x" forState:UIControlStateNormal];
        [closeButton setTitleColor:RGB(162, 162, 162) forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(dismissToolTip) forControlEvents:UIControlEventTouchUpInside];
        [tooltipImageView addSubview:closeButton];
        
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
    
    ProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    [fancyProfileViewController setStateWithUser: user];
    if ([self isPeeking]) fancyProfileViewController.userState = OTHER_SCHOOL_USER_STATE;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController pushViewController: fancyProfileViewController animated: YES];
}

- (void)showModalAttendees:(UIViewController *)modal {
    self.shouldReloadEvents = NO;
    [self.navigationController presentViewController:modal animated:YES completion:nil];
}

- (void)showConversationForEvent:(WGEvent *)event
               withEventMessages:(WGCollection *)eventMessages
                         atIndex:(int)index {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EventConversationViewController *conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationViewController.event = event;
    conversationViewController.index = [NSNumber numberWithInt:index];
//    if ([event.id isEqual:WGProfile.currentUser.eventAttending.id]) {
        eventMessages = [self eventMessagesWithCamera:eventMessages];
//    }
    conversationViewController.eventMessages = eventMessages;
    conversationViewController.isPeeking = [self isPeeking];
    [self presentViewController:conversationViewController animated:YES completion:nil];
}

- (WGCollection *)eventMessagesWithCamera:(WGCollection *)eventMessages {
    WGCollection *newEventMessages =  [[WGCollection alloc] initWithType:[WGEventMessage class]];
    [newEventMessages addObjectsFromCollection:eventMessages];
    WGEventMessage *eventMessage = [WGEventMessage serialize:@{
                                                               @"user": [WGProfile currentUser],
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
    [event getMessages:^(WGCollection *collection, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        NSInteger messageIndex = [collection indexOfObject:event.highlight];
        weakConversationViewController.index = @(messageIndex);
        
        weakConversationViewController.eventMessages = collection;
        weakConversationViewController.mediaScrollView.eventMessages = collection;
        [weakConversationViewController.facesCollectionView reloadData];
        [weakConversationViewController.mediaScrollView reloadData];
        [weakConversationViewController highlightCellAtPage:messageIndex animated:NO];
    }];
}

- (void)showStoryForEvent:(WGEvent*)event {
    EventStoryViewController *eventStoryController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventStoryViewController"];
    eventStoryController.placesDelegate = self;
    eventStoryController.event = event;
    
    if (self.groupNumberID) eventStoryController.groupNumberID = self.groupNumberID;
    [self.navigationController pushViewController:eventStoryController animated:YES];
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
    _spinnerAtCenter = YES;
    [self updateTitleView];
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
    self.navigationItem.leftBarButtonItem = leftBarButton;
    self.schoolButton.enabled = NO;
}

- (void)backPressed {
    self.presentingLockedView = NO;
    self.schoolButton.enabled = YES;
    
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

#pragma mark - Network Asynchronous Functions

- (void) fetchEventsFirstPage {
    if (!self.doNotReloadOffsets) {
        for (NSString *key in [self.eventOffsetDictionary allKeys]) {
            [self.eventOffsetDictionary setValue:@0 forKey:key];
        }
        self.doNotReloadOffsets = NO;
    }
    self.aggregateEvent = nil;
    self.allEvents = nil;
    [self fetchEvents];
}

- (void) fetchEvents {
    if (!self.fetchingEventAttendees && [WGProfile currentUser].key) {
        self.fetchingEventAttendees = YES;
        if (_spinnerAtCenter) [WGSpinnerView addDancingGToCenterView:self.view];
        __weak typeof(self) weakSelf = self;
        if (self.allEvents) {
            if ([self.allEvents.hasNextPage boolValue]) {
                [self.allEvents addNextPage:^(BOOL success, NSError *error) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
                    if (error) {
                        strongSelf.fetchingEventAttendees = NO;
                        strongSelf.shouldReloadEvents = YES;
                        return;
                    }
                    
                    strongSelf.pastDays = [[NSMutableArray alloc] init];
                    strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
                    strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
                    
                    strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                    strongSelf.filteredEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
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
                    
                    [strongSelf fetchedOneParty];
                    strongSelf.fetchingEventAttendees = NO;
                    strongSelf.shouldReloadEvents = YES;
                    [strongSelf.placesTableView reloadData];
                }];
            }
        } else if (self.groupNumberID) {
            [WGEvent getWithGroupNumber:self.groupNumberID andHandler:^(WGCollection *collection, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];

                if (error) {
                    strongSelf.fetchingEventAttendees = NO;
                    strongSelf.shouldReloadEvents = YES;
                    return;
                }
                
                strongSelf.allEvents = collection;
                strongSelf.pastDays = [[NSMutableArray alloc] init];
                strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
                strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
                strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                strongSelf.filteredEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                
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
                
                [strongSelf fetchedOneParty];
                strongSelf.fetchingEventAttendees = NO;
                [strongSelf.placesTableView reloadData];
            }];
        } else {
            [WGEvent get:^(WGCollection *collection, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
                if (error) {
                    strongSelf.fetchingEventAttendees = NO;
                    return;
                }
                strongSelf.allEvents = collection;
                strongSelf.pastDays = [[NSMutableArray alloc] init];
                strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
                strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
                strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
                strongSelf.filteredEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
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

                [strongSelf fetchedOneParty];
                strongSelf.fetchingEventAttendees = NO;
                [strongSelf.placesTableView reloadData];
            }];
        }
    }
}

- (void)fetchedOneParty {
    _spinnerAtCenter ? [WGSpinnerView removeDancingGFromCenterView:self.view] : [self.placesTableView didFinishPullToRefresh];
     _spinnerAtCenter = NO;
    self.filteredEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
    [self dismissKeyboard];
}

- (void) fetchUserInfo {
    __weak typeof(self) weakSelf = self;
    if (!self.fetchingUserInfo && WGProfile.currentUser.key) {
        self.fetchingUserInfo = YES;
        [WGProfile reload:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf.secondTimeFetchingUserInfo) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"presentPush" object:nil];
                strongSelf.secondTimeFetchingUserInfo = YES;
                if (
                    (error || ![[WGProfile currentUser].emailValidated boolValue] ||
                    [[WGProfile currentUser].group.locked boolValue])
                    
                    &&
                    
                    !strongSelf.presentingLockedView )
                {
                    strongSelf.fetchingUserInfo = NO;
                    [strongSelf showFlashScreen];
                    [strongSelf.signViewController reloadedUserInfo:success andError:error];
                    return;
                }
            }
            if (error) {
                strongSelf.fetchingUserInfo = NO;
                // Second time fetching user info... already logged in
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:^(BOOL didRetry) {
                    if (didRetry) {
                        [strongSelf fetchUserInfo];
                        [strongSelf fetchEvents];
                    }
                }];
                return;
            }
            if (!strongSelf.presentingLockedView) {
                [strongSelf showReferral];
                [strongSelf showToolTip];
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canFetchAppStartup"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchAppStart" object:nil];
            [strongSelf initializeNavigationBar];
            [strongSelf.placesTableView reloadData];
            strongSelf.fetchingUserInfo = NO;
        }];
    }
}

#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    [WGSpinnerView addDancingGToUIScrollView:self.placesTableView
                         withBackgroundColor:RGB(237, 237, 237)
                                 withHandler:^{
        _spinnerAtCenter = NO;
        [self fetchEventsFirstPage];
        [self fetchUserInfo];
    }];
}

- (void)addProfileUserToEventWithNumber:(int)eventID {
    WGEvent *event = (WGEvent *)[self.events objectWithID:[NSNumber numberWithInt:eventID]];
    [self removeProfileUserFromAnyOtherEvent];
    [event.attendees insertObject:[WGProfile currentUser] atIndex:0];
    event.numAttending = @([event.numAttending intValue] + 1);
    [self.events exchangeObjectAtIndex:[self.events indexOfObject:event] withObjectAtIndex:0];
}

-(void) removeProfileUserFromAnyOtherEvent {
    for (WGEvent* event in self.events) {
        if ([event.attendees containsObject:[WGProfile currentUser]]) {
            [event.attendees removeObject:[WGProfile currentUser]];
            event.numAttending = @([event.numAttending intValue] - 1);
        }
    }
}

@end

@implementation EventCell

+ (CGFloat)heightIsFullCell:(BOOL)isFullCell {
    return 20 + 64 + [EventPeopleScrollView containerHeight] + [HighlightCell height] + 50 + 20;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [EventCell heightIsFullCell:NO]);
    self.contentView.frame = self.frame;
    self.backgroundColor = UIColor.whiteColor;
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.center.x - 20, self.center.y - 20, 40, 40)];
    self.loadingView.hidden = YES;
    [self.contentView addSubview:self.loadingView];
    
    self.privacyLockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 12 - 10, 32 - 8, 12, 16)];
    self.privacyLockImageView.image = [UIImage imageNamed:@"veryBlueLockClosed"];
    self.privacyLockImageView.hidden = YES;
    [self.contentView addSubview:self.privacyLockImageView];
    
    self.eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 17, self.frame.size.width - 15, 30)];
    self.eventNameLabel.textAlignment = NSTextAlignmentLeft;
    self.eventNameLabel.numberOfLines = 2;
    self.eventNameLabel.backgroundColor = UIColor.whiteColor;
    self.eventNameLabel.font = [FontProperties mediumFont:18.0f];
    self.eventNameLabel.textColor = [FontProperties getBlueColor];
    [self.contentView addSubview:self.eventNameLabel];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, 53, 85, 0.5)];
    lineView.backgroundColor = RGB(196, 196, 196);
    [self.contentView addSubview:lineView];
    
    self.numberOfPeopleGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40 + 20, self.frame.size.width, 20)];
    self.numberOfPeopleGoingLabel.textColor = RGB(196, 196, 196);
    self.numberOfPeopleGoingLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfPeopleGoingLabel.font = [FontProperties lightFont:15.0f];
    [self.contentView addSubview:self.numberOfPeopleGoingLabel];

    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    self.eventPeopleScrollView.widthOfEachCell = (float)[[UIScreen mainScreen] bounds].size.width/(float)6.4;
    self.eventPeopleScrollView.frame = CGRectMake(0, 20 + 60 + 9, self.frame.size.width, self.eventPeopleScrollView.widthOfEachCell + 20);
    self.eventPeopleScrollView.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.eventPeopleScrollView];
    
    self.numberOfHighlightsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 15, self.frame.size.width, 20)];
    self.numberOfHighlightsLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfHighlightsLabel.textColor = RGB(196, 196, 196);
    self.numberOfHighlightsLabel.font = [FontProperties lightFont:15.0f];
    self.numberOfHighlightsLabel.alpha = 1.0f;
    self.numberOfHighlightsLabel.text = @"The Buzz";
    [self.contentView addSubview:self.numberOfHighlightsLabel];
    
    self.highlightsCollectionView = [[HighlightsCollectionView alloc]
                                     initWithFrame:CGRectMake(0, self.numberOfHighlightsLabel.frame.origin.y + self.numberOfHighlightsLabel.frame.size.height + 5, self.frame.size.width, [HighlightCell height])
                                     collectionViewLayout:[HighlightsFlowLayout new]];
    [self.contentView addSubview:self.highlightsCollectionView];
    CAGradientLayer *shadow = [CAGradientLayer layer];
    shadow.frame = CGRectMake(-10, 0, 10, self.highlightsCollectionView.frame.size.height);
    shadow.startPoint = CGPointMake(1.0, 0.5);
    shadow.endPoint = CGPointMake(0, 0.5);
    shadow.colors = [NSArray arrayWithObjects:(id)UIColor.redColor.CGColor, UIColor.grayColor.CGColor, nil];
    [self.highlightsCollectionView.layer addSublayer:shadow];
    
//    self.goingHereButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.highlightsCollectionView.frame.origin.y + self.highlightsCollectionView.frame.size.height + 10, self.frame.size.width, [UIScreen mainScreen].bounds.size.width/5.3)];
//    self.goingHereButton.backgroundColor = [FontProperties getBlueColor];
//    [self.goingHereButton setTitle:@"Go Here" forState:UIControlStateNormal];
//    [self.goingHereButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
//    self.goingHereButton.titleLabel.font = [FontProperties openSansSemibold:14.0f];
//    [self.contentView addSubview:self.goingHereButton];
    
    self.grayView = [[UIView alloc] initWithFrame:CGRectMake(0, self.highlightsCollectionView.frame.origin.y + self.highlightsCollectionView.frame.size.height + 12, self.frame.size.width, 40)];
    self.grayView.backgroundColor = RGB(237, 237, 237);
    [self.contentView addSubview:self.grayView];
}

-(void) updateUI {
    self.highlightsCollectionView.event = self.event;
    self.eventNameLabel.text = self.event.name;
    self.numberOfPeopleGoingLabel.text = [NSString stringWithFormat:@"Going (%@)", self.event.numAttending];
    self.privacyLockImageView.hidden = !self.event.isPrivate;
    self.eventPeopleScrollView.event = self.event;
    [self.eventPeopleScrollView updateUI];
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
    self.backgroundColor = RGB(237, 237, 237);
    
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
    return 0.5;
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
    
    self.privateIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, self.highlightImageView.bounds.size.height - 33, 12, 15)];
    self.privateIconImageView.image = [UIImage imageNamed:@"privateIcon"];
    self.privateIconImageView.hidden = YES;
    [self.contentView addSubview:self.privateIconImageView];
    
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
}

- (void)loadConversation {
    [self.placesDelegate showConversationForEvent:self.event];
}

+ (CGFloat) height {
    return [UIScreen mainScreen].bounds.size.height * 0.43;
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
