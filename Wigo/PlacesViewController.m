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
#import "UIView+ViewToImage.h"
#import "UIImage+ImageEffects.h"
#import "ReferalViewController.h"
#import "EventMessagesConstants.h"
#import "OverlayViewController.h"
#import "EventConversationViewController.h"
#import "WGNavigateParser.h"
#import "WhereAreYouViewController.h"
#import "LocationPrimer.h"
#import "ReferalView.h"

#define kEventCellName @"EventCell"
#define kMoreThan2PhotosOldEventCell @"MoreThan2PhotosOldEventCell"
#define kLessThan2PhotosOldEventCell @"LessThan2PhotosOldEventCell"
#define kOldEventCellName @"OldEventCell"

#define kOldEventShowHighlightsCellName @"OldEventShowHighlightsCellName"

@interface PlacesViewController ()
// Events By Days
@property (nonatomic, strong) NSMutableArray *pastDays;
@property (nonatomic, strong) UIView *blackViewOnTop;
@end
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
    self.shouldReloadEvents = YES;
    self.eventOffsetDictionary = [NSMutableDictionary new];
    
    UITabBarController *tab = self.tabBarController;
    ProfileViewController *profileVc = (ProfileViewController *)[tab.viewControllers objectAtIndex:4];
    profileVc.user = [WGUser new];
    
    self.spinnerAtCenter = YES;
    [self initializeWhereView];
    [TabBarAuxiliar startTabBarItems];
    [self addCenterButton];
    [NetworkFetcher.defaultGetter fetchMeta];
    [NetworkFetcher.defaultGetter fetchFriendsIds];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self isPeeking] && self.groupNumberID && self.groupName) {
        [WGAnalytics tagView:@"where" withTargetGroup:[[WGGroup alloc] initWithJSON:@{@"name": self.groupName, @"id": self.groupNumberID}]];
    }
    else {
        [WGAnalytics tagView:@"where"];
    }
    
    self.isLocal = YES;
    [self updateNavigationBar];
    [self.placesTableView reloadData];
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
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
//    ReferalView *referalView = [[ReferalView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//    [self.view addSubview:referalView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
    self.tabBarController.navigationItem.titleView = nil;
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

- (void)addCenterButton {
    UIImage *buttonImage = [UIImage imageNamed:@"newEvent"];
    UIImage *highlightImage = nil;
    self.createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.createButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    self.createButton.frame = CGRectMake(0.0, 0.0, 55.0f, 49.0f);
    [self.createButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.createButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.createButton addTarget:self action:@selector(goingSomewhereElsePressed) forControlEvents:UIControlEventTouchUpInside];
    self.createButton.center = self.tabBarController.tabBar.center;
    [self.tabBarController.view addSubview:self.createButton];
}

- (void) updateNavigationBar {
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:UIColor.whiteColor, NSFontAttributeName:[FontProperties getTitleFont]};
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor}];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:UIColor.whiteColor forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;

    UIView *toggleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
    toggleView.layer.borderColor = UIColor.whiteColor.CGColor;
    toggleView.layer.borderWidth = 1.0f;
    toggleView.layer.cornerRadius = 7.0F;
    toggleView.clipsToBounds = YES;
    self.bostonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, 30)];
    self.bostonLabel.text = @"Local";
    self.bostonLabel.textColor = UIColor.whiteColor;
    self.bostonLabel.font = [FontProperties mediumFont:12.0f];
    self.bostonLabel.textAlignment = NSTextAlignmentCenter;
    UITapGestureRecognizer *tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(localPressed)];
    tapGest.numberOfTapsRequired = 1;
    self.bostonLabel.userInteractionEnabled = YES;
    [self.bostonLabel addGestureRecognizer:tapGest];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    [self.bostonLabel addGestureRecognizer:longPress];
    [toggleView addSubview:self.bostonLabel];
    
    self.friendsButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 0, 70, 30)];
    [self.friendsButton addTarget:self action:@selector(friendsPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.friendsButton setTitle:@"Friends" forState:UIControlStateNormal];
    self.friendsButton.titleLabel.font = [FontProperties mediumFont:12.0f];
    [toggleView addSubview:self.friendsButton];
    self.tabBarController.navigationItem.titleView = toggleView;
    self.isLocal = self.isLocal;
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.isLocal = YES;
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (_blackViewOnTop) _blackViewOnTop.alpha = 0.0f;
        PeekViewController *peekViewController = [PeekViewController new];
        peekViewController.placesDelegate = self;
        [self presentViewController:peekViewController animated:YES completion:nil];
    }
}

- (void)localPressed {
    self.isLocal = YES;
}

- (void)friendsPressed {
    self.isLocal = NO;
}

- (void)setIsLocal:(BOOL)isLocal {
    WGProfile.isLocal = isLocal;
    _isLocal = isLocal;
    if (isLocal) {
        self.bostonLabel.textColor = [FontProperties getBlueColor];
        self.bostonLabel.backgroundColor = UIColor.whiteColor;
        [self.friendsButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.friendsButton.backgroundColor = [FontProperties getBlueColor];
    }
    else {
        [self.friendsButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
        self.friendsButton.backgroundColor = UIColor.whiteColor;
        self.bostonLabel.textColor = UIColor.whiteColor;
        self.bostonLabel.backgroundColor = [FontProperties getBlueColor];
    }
    [self fetchEventsFirstPage];
}

-(void) initializeFlashScreen {
    if (firstTimeLoading) return;

    firstTimeLoading = YES;
    self.signViewController = [SignViewController new];
    self.signViewController.placesDelegate = self;
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
                                               object:nil];
}

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
    } completion:^(BOOL finished) {
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (void)initializeWhereView {
    self.placesTableView = [[UITableView alloc] initWithFrame: CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 20 - 49) style: UITableViewStyleGrouped];
    self.placesTableView.sectionHeaderHeight = 0;
    self.placesTableView.sectionFooterHeight = 0;
    [self.view addSubview:self.placesTableView];
    self.placesTableView.dataSource = self;
    self.placesTableView.delegate = self;
    self.placesTableView.showsVerticalScrollIndicator = NO;
    self.placesTableView.showsHorizontalScrollIndicator = NO;
    [self.placesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.placesTableView registerClass:[EventCell class] forCellReuseIdentifier:kEventCellName];
    [self.placesTableView registerClass:[MoreThan2PhotosOldEventCell class] forCellReuseIdentifier:kMoreThan2PhotosOldEventCell];
    [self.placesTableView registerClass:[LessThan2PhotosOldEventCell class] forCellReuseIdentifier:kLessThan2PhotosOldEventCell];
    [self.placesTableView registerClass:[OldEventShowHighlightsCell class] forCellReuseIdentifier:kOldEventShowHighlightsCellName];
    self.placesTableView.backgroundColor = UIColor.whiteColor;
    self.placesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addRefreshToScrollView];
    
//    self.labelSwitch = [[LabelSwitch alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [LabelSwitch height])];
//    [self.view bringSubviewToFront:self.labelSwitch];
//    [self.view addSubview:self.labelSwitch];
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

- (void)invitePressed:(WGEvent *)event {
    [self presentViewController:[[InviteViewController alloc] initWithEvent:event] animated:YES completion:nil];
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
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    
    __weak typeof(self) weakSelf = self;
    WGEvent *event = [self getEventAtIndexPath:[NSIndexPath indexPathForItem:buttonSender.tag inSection:0]];
    if (event == nil) return;
    [WGProfile.currentUser goingToEvent:event withHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
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
    [self.navigationController pushViewController:[WhereAreYouViewController new] animated:YES];
}

- (void)profileSegue {
    if (_blackViewOnTop) _blackViewOnTop.alpha = 0.0f;
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = WGProfile.currentUser;
    profileViewController.placesDelegate = self;
    profileViewController.events = self.events;

    [self.navigationController pushViewController: profileViewController animated: YES];
}

#pragma mark - Where Are You Going? View and Delegate

-(void)updateEvent:(WGEvent *)newEvent {
    [self.events replaceObjectAtIndex:[self.events indexOfObject:newEvent] withObject:newEvent];
}


#pragma mark - Tablew View Data Source

- (int)shouldShowAggregatePrivateEvents {
    BOOL areEventsOfTodayDone = self.oldEvents.count > 0 || ![self.allEvents.hasNextPage boolValue];
    return (self.aggregateEvent &&
            self.aggregateEvent.attendees &&
            self.aggregateEvent.attendees.total.intValue > 0 &&
            areEventsOfTodayDone) ? 1 : 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self shouldShowHighlights]) {
        //[Today section]  [Button show highlights]
        return 1 + 1 + 1;
    }
    else if (self.pastDays.count > 0) {
        //[Today section] [Highlighs section] (really just space for a header) + pastDays sections
//        return 1 + 1;
        return 1 + 1 + self.pastDays.count;
    }
    //[Today section]
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kTodaySection) {
        return self.events.count + self.allEvents.hasNextPage.intValue + [self shouldShowAggregatePrivateEvents];
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
        return 0;
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
        return nil;
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
        return [EventCell height];
    }
    else if (self.pastDays.count > 0 && indexPath.section > 1) { //past day rows
        NSString *day = [self.pastDays objectAtIndex: indexPath.section - 2];
        NSArray *eventObjectArray = (NSArray *)[self.dayToEventObjArray objectForKey:day];
        WGEvent *event = [eventObjectArray objectAtIndex:indexPath.row];
        if (event.messages.count > 3) {
            return [MoreThan2PhotosOldEventCell height];
        }
        return [LessThan2PhotosOldEventCell height];
    }
    
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kTodaySection) {
        EventCell *cell = [tableView dequeueReusableCellWithIdentifier:kEventCellName forIndexPath:indexPath];
        cell.highlightsCollectionView.event = nil;
        cell.highlightsCollectionView.eventMessages = nil;
        [cell.highlightsCollectionView reloadData];
        cell.placesDelegate = self;
        if (cell.loadingView.isAnimating) [cell.loadingView stopAnimating];
        cell.loadingView.hidden = YES;
        cell.placesDelegate = self;
        cell.eventPeopleScrollView.rowOfEvent = (int)indexPath.row;
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
        if (indexPath.row == eventObjectArray.count - 1) {
            [self fetchEventsWithHandler:^(BOOL success, NSError *error) {}];
        }
        WGEvent *event = [eventObjectArray objectAtIndex:indexPath.row];
        if (event.messages.count > 3) {
           MoreThan2PhotosOldEventCell *cell = (MoreThan2PhotosOldEventCell *)[tableView dequeueReusableCellWithIdentifier:kMoreThan2PhotosOldEventCell forIndexPath:indexPath];
            cell.event = event;
            cell.placesDelegate = self;
            cell.eventPeopleScrollView.isOld = YES;
            cell.eventPeopleScrollView.groupID = self.groupNumberID;
            cell.eventPeopleScrollView.placesDelegate = self;
            if (![self.eventOffsetDictionary objectForKey:[event.id stringValue]]) {
                cell.eventPeopleScrollView.contentOffset = CGPointMake(0, 0);
            }
            return cell;
        }
        else {
            LessThan2PhotosOldEventCell *cell = (LessThan2PhotosOldEventCell *)[tableView dequeueReusableCellWithIdentifier:kLessThan2PhotosOldEventCell forIndexPath:indexPath];
            cell.event = event;
            cell.placesDelegate = self;
            cell.eventPeopleScrollView.isOld = YES;
            cell.eventPeopleScrollView.groupID = self.groupNumberID;
            cell.eventPeopleScrollView.placesDelegate = self;
            if (![self.eventOffsetDictionary objectForKey:[event.id stringValue]]) {
                cell.eventPeopleScrollView.contentOffset = CGPointMake(0, 0);
            }
            return cell;
        }
        
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
    return [self isPeeking] || (event.id && [event isEqual:WGProfile.currentUser.eventAttending]);
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
    if ([self isPeeking] ||
        (!WGProfile.currentUser.crossEventPhotosEnabled && ![[event.attendees objectAtIndex:0] isEqual:WGProfile.currentUser]) ||
        event.isExpired.boolValue) {
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
                                                               @"user" : WGProfile.currentUser,
                                                               @"created" : [NSDate nowStringUTC],
                                                               kMediaMimeTypeKey : kCameraType,
                                                               @"media" : @""
                                                               }];
    
    [newEventMessages insertObject:eventMessage atIndex:0];
    
    return newEventMessages;
}

- (void)showHighlightForEvent:(WGEvent *)event
              andEventMessage:(WGEventMessage *)eventMessage
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.shouldReloadEvents = NO;
    
    WGCollection *temporaryEventMessages = [[WGCollection alloc] initWithType:[WGEventMessage class]];
    [temporaryEventMessages addObject:eventMessage];

    EventConversationViewController *conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationViewController.event = event;
    conversationViewController.eventMessages = temporaryEventMessages;
    conversationViewController.isPeeking = [self isPeeking];
    
    [self presentViewController:conversationViewController animated:YES completion:nil];
    __weak typeof(conversationViewController) weakConversationViewController =
    conversationViewController;
    __weak typeof(event) weakEvent = event;
    [event getMessagesForHighlights:eventMessage
                        withHandler:^(WGCollection *collection, NSError *error) {
        if (error) {
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
    
//    BatteryViewController *batteryViewController = [BatteryViewController new];
//    
//    UIImage* imageOfUnderlyingView = [[UIApplication sharedApplication].keyWindow convertViewToImage];
//    imageOfUnderlyingView = [imageOfUnderlyingView applyBlurWithRadius:10
//                                                             tintColor:RGBAlpha(0, 0, 0, 0.75)
//                                                 saturationDeltaFactor:1.3
//                                                             maskImage:nil];
//    batteryViewController.blurredBackgroundImage = imageOfUnderlyingView;
//    batteryViewController.placesDelegate = self;
//    [self presentViewController:batteryViewController animated:YES completion:nil];
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
    if (self.fetchingEventAttendees || !WGProfile.currentUser.key) {
        handler(NO, nil);
        return;
    }
    
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
            if (event.isExpired.boolValue) {
                [strongSelf.oldEvents addObject:event];
            } else {
                [strongSelf.events addObject:event];
            }
        }
        
        for (WGEvent *event in strongSelf.oldEvents) {
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
    if (self.fetchingEventAttendees || !WGProfile.currentUser.key) {
        handler(NO, nil);
        return;
    }
    self.fetchingEventAttendees = YES;
    if (self.spinnerAtCenter) [WGSpinnerView addDancingGToCenterView:self.view];
    __weak typeof(self) weakSelf = self;
    if (self.allEvents) {
        if (!self.allEvents.nextPage) {
            self.fetchingEventAttendees = NO;
            handler(NO, nil);
            return;
        }
        [self.allEvents addNextPage:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.fetchingEventAttendees = NO;
            if (error) {
                strongSelf.shouldReloadEvents = YES;
                [strongSelf removeDancingG];
                handler(success, error);
                return;
            }
            
            strongSelf.pastDays = [[NSMutableArray alloc] init];
            strongSelf.dayToEventObjArray = [[NSMutableDictionary alloc] init];
            strongSelf.events = [[WGCollection alloc] initWithType:[WGEvent class]];
            strongSelf.oldEvents = [[WGCollection alloc] initWithType:[WGEvent class]];
            for (WGEvent *event in strongSelf.allEvents) {
                if (event) {
                    if (event.isExpired.boolValue) {
                        [strongSelf.oldEvents addObject:event];
                    } else {
                        [strongSelf.events addObject:event];
                    }
                }
            }
            
            for (WGEvent *event in strongSelf.oldEvents) {
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
            [strongSelf removeDancingG];
            [strongSelf.placesTableView reloadData];
            handler(success, error);
        }];
        
    } else if (self.groupNumberID) {
        [WGEvent getWithGroupNumber:self.groupNumberID andHandler:^(WGCollection *collection, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.fetchingEventAttendees = NO;
            if (error) {
                strongSelf.shouldReloadEvents = YES;
                [strongSelf removeDancingG];
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
                    if (event.isExpired.boolValue) {
                        [strongSelf.oldEvents addObject:event];
                    } else {
                        [strongSelf.events addObject:event];
                    }
                }
            }
            
            for (WGEvent *event in strongSelf.oldEvents) {
                NSString *eventDate = [[event expires] deserialize];
                if (eventDate) {
                    if ([strongSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                        [strongSelf.pastDays addObject: eventDate];
                        [strongSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                    }
                    [[strongSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
                }
            }
            
            [strongSelf removeDancingG];
            [strongSelf.placesTableView reloadData];
            handler(YES, error);
        }];
    } else {
        [WGEvent get:^(WGCollection *collection, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.fetchingEventAttendees = NO;
            if (error) {
                [strongSelf removeDancingG];
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
                if (event.isExpired.boolValue) {
                    [strongSelf.oldEvents addObject:event];
                } else {
                    [strongSelf.events addObject:event];
                }
            }
            
            for (WGEvent *event in strongSelf.oldEvents) {
                NSString *eventDate = [[event expires] deserialize];
                if ([strongSelf.pastDays indexOfObject: eventDate] == NSNotFound) {
                    if (!eventDate) return;
                    [strongSelf.pastDays addObject: eventDate];
                    [strongSelf.dayToEventObjArray setObject: [[NSMutableArray alloc] init] forKey: eventDate];
                }
                [[strongSelf.dayToEventObjArray objectForKey: eventDate] addObject: event];
            }

            [strongSelf removeDancingG];
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
    [WGSpinnerView removeDancingGFromCenterView:self.view];
    self.placesTableView.backgroundColor = RGB(232, 232, 232);
    [self.placesTableView didFinishPullToRefresh];
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
            strongSelf.secondTimeFetchingUserInfo = YES;
//            if (
//                (error || ![WGProfile.currentUser.emailValidated boolValue] ||
//                [WGProfile.currentUser.group.locked boolValue])
//                
//                &&
//                
//                !strongSelf.presentingLockedView )
//            {
//                [strongSelf showFlashScreen];
//                [strongSelf.signViewController reloadedUserInfo:success andError:error];
//                return;
//            }
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
        UITabBarController *tab = self.tabBarController;
        ProfileViewController *profileVc = (ProfileViewController *)[tab.viewControllers objectAtIndex:4];
        profileVc.user = WGProfile.currentUser;
    }];
   
}


#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    CGFloat contentInset = 44.0f;
    self.placesTableView.contentInset = UIEdgeInsetsMake(contentInset, 0, 0, 0);
    [WGSpinnerView addDancingGToUIScrollView:self.placesTableView
                         withBackgroundColor:RGB(232, 232, 232)
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
    return 20 + 64 + [EventPeopleScrollView containerHeight] + [HighlightCell height] + 50;
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
    self.backgroundColor = RGB(232, 232, 232);
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *shadowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-5, [EventCell height] - 20 - 4, self.frame.size.width + 10, 12)];
    shadowImageView.image = [UIImage imageNamed:@"shadow"];
    [self.contentView addSubview:shadowImageView];
    
    self.whiteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [EventCell height] - 20)];
    self.whiteView.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:self.whiteView];
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.center.x - 20, self.center.y - 20, 40, 40)];
    self.loadingView.hidden = YES;
    [self.whiteView addSubview:self.loadingView];
    
    self.privacyLockButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 0, 30, 53)];
    [self.whiteView addSubview:self.privacyLockButton];
    
    self.privacyLockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 26.5 - 8., 12, 16)];
    self.privacyLockImageView.image = [UIImage imageNamed:@"veryBlueLockClosed"];
    self.privacyLockImageView.hidden = YES;
    [self.privacyLockButton addSubview:self.privacyLockImageView];
    
    self.eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 16.5, self.frame.size.width - 40, 20)];
    self.eventNameLabel.textAlignment = NSTextAlignmentLeft;
    self.eventNameLabel.numberOfLines = 2;
    self.eventNameLabel.font = [FontProperties semiboldFont:18.0f];
    self.eventNameLabel.textColor = [FontProperties getBlueColor];
    [self.whiteView addSubview:self.eventNameLabel];
    
    self.verifiedView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 40, 20, 10)];
    self.verifiedView.hidden = YES;
    UIImageView *verifiedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    verifiedImageView.image = [UIImage imageNamed:@"verifiedImage"];
    [self.verifiedView addSubview:verifiedImageView];
    UILabel *verifiedLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 100, 10)];
    verifiedLabel.text = @"Wigo Verified";
    verifiedLabel.textAlignment = NSTextAlignmentLeft;
    verifiedLabel.textColor = RGB(165, 165, 165);
    verifiedLabel.font = [FontProperties mediumFont:10.0f];
    [self.verifiedView addSubview:verifiedLabel];
    [self.contentView addSubview:self.verifiedView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, 53, 85, 0.5)];
    lineView.backgroundColor = RGB(215, 215, 215);
    [self.whiteView addSubview:lineView];
    
    self.numberOfPeopleGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40 + 20, self.frame.size.width, 20)];
    self.numberOfPeopleGoingLabel.textColor = RGB(119, 119, 119);
    self.numberOfPeopleGoingLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfPeopleGoingLabel.font = [FontProperties lightFont:15.0f];
    [self.whiteView addSubview:self.numberOfPeopleGoingLabel];

    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    self.eventPeopleScrollView.widthOfEachCell = 0.9*(float)[[UIScreen mainScreen] bounds].size.width/(float)5.5;
    self.eventPeopleScrollView.frame = CGRectMake(0, 20 + 60 + 9, self.frame.size.width, self.eventPeopleScrollView.widthOfEachCell + 20);
    self.eventPeopleScrollView.backgroundColor = UIColor.clearColor;
    [self.whiteView addSubview:self.eventPeopleScrollView];
    
    self.highlightsCollectionView = [[HighlightsCollectionView alloc]
                                     initWithFrame:CGRectMake(0, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 20 + 5, self.frame.size.width, [HighlightCell height])
                                     collectionViewLayout:[HighlightsFlowLayout new]];
    [self.whiteView addSubview:self.highlightsCollectionView];
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
            self.verifiedView.hidden = NO;
            self.eventNameLabel.frame = CGRectMake(self.eventNameLabel.frame.origin.x, self.eventNameLabel.frame.origin.y - 30, self.eventNameLabel.frame.size.width, self.eventNameLabel.frame.size.height);
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.verifiedView.hidden = YES;
        });
    }
}

- (void)setIsOldEvent:(BOOL)isOldEvent {
    if (isOldEvent) {
        self.whiteView.backgroundColor = RGB(221, 221, 221);
        self.eventNameLabel.textColor = RGB(121, 121, 121);
        self.numberOfPeopleGoingLabel.textColor = RGB(148, 148, 148);
    }
    else {
        self.whiteView.backgroundColor = UIColor.whiteColor;
        self.eventNameLabel.textColor = [FontProperties getBlueColor];
        self.numberOfPeopleGoingLabel.textColor = RGB(119, 119, 119);
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

@implementation PastDayHeader


+ (CGFloat) height: (BOOL) isFirst  {
    if (isFirst) {
        return 75;
    }
    return 70;
}

+ (instancetype) initWithDay: (NSString *) dayText isFirst: (BOOL) isFirst {
    PastDayHeader *header = [[PastDayHeader alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [PastDayHeader height: isFirst])];
    header.isFirst = isFirst;
    header.day = dayText;
    [header setup];
    
    return header;
}
- (void) setup {
    self.backgroundColor = RGB(232, 232, 232);
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSDate *date = [dateFormat dateFromString:self.day];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate: date];
    int weekday = (int)[comps weekday];
    weekday -= 2;
    if (weekday < 0) weekday += 7;
    NSString *dayName = [dateFormat weekdaySymbols][weekday];
    
    UIView *leftLineView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.width/2 - 70.0f, 1.0f)];
    leftLineView.center = CGPointMake(leftLineView.center.x, self.center.y - 10);
    leftLineView.backgroundColor = RGB(210, 210, 210);
    [self addSubview: leftLineView];
    
    UIView *rightLineView = [[UIView alloc] initWithFrame: CGRectMake(self.frame.size.width/2 + 70.0f, 0, self.frame.size.width/2 - 70.0f, 1.0f)];
    rightLineView.center = CGPointMake(rightLineView.center.x, self.center.y - 10);
    rightLineView.backgroundColor = RGB(210, 210, 210);
    [self addSubview: rightLineView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(self.frame.size.width/2 - 70.0f, 0, 140, self.frame.size.height - 23.5)];
    titleLabel.center = CGPointMake(titleLabel.center.x, self.center.y - 10);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties scMediumFont: 18.0f];
    titleLabel.textColor = RGB(155, 155, 155);
    titleLabel.text = [dayName lowercaseString];
    titleLabel.center = CGPointMake(self.center.x, titleLabel.center.y);
    [self addSubview: titleLabel];
}

@end

@implementation HighlightOldEventCell

- (void) setup {
    self.contentView.frame = self.frame;
    self.backgroundColor = RGB(232, 232, 232);
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 20)];
    backgroundView.backgroundColor = UIColor.whiteColor;
    backgroundView.clipsToBounds = YES;
    [self.contentView addSubview:backgroundView];
    
    self.eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 16.5, self.frame.size.width - 40, 20)];
    self.eventNameLabel.textAlignment = NSTextAlignmentLeft;
    self.eventNameLabel.numberOfLines = 2;
    self.eventNameLabel.font = [FontProperties semiboldFont:18.0f];
    self.eventNameLabel.textColor = RGB(121, 121, 121);
    [backgroundView addSubview:self.eventNameLabel];

    self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 100, 10)];
    self.dateLabel.textAlignment = NSTextAlignmentLeft;
    self.dateLabel.textColor = RGB(165, 165, 165);
    self.dateLabel.font = [FontProperties mediumFont:10.0f];
    [self.contentView addSubview:self.dateLabel];

    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, 53, 85, 0.5)];
    lineView.backgroundColor = RGB(215, 215, 215);
    [backgroundView addSubview:lineView];
    
    self.numberOfPeopleGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, self.frame.size.width, 20)];
    self.numberOfPeopleGoingLabel.textColor = RGB(119, 119, 119);
    self.numberOfPeopleGoingLabel.textAlignment = NSTextAlignmentLeft;
    self.numberOfPeopleGoingLabel.font = [FontProperties lightFont:15.0f];
    [backgroundView addSubview:self.numberOfPeopleGoingLabel];
    
    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    self.eventPeopleScrollView.widthOfEachCell = 0.9*(float)[[UIScreen mainScreen] bounds].size.width/(float)5.5;
    self.eventPeopleScrollView.frame = CGRectMake(0, 89, self.frame.size.width, self.eventPeopleScrollView.widthOfEachCell + 20);
    self.eventPeopleScrollView.backgroundColor = UIColor.clearColor;
    [backgroundView addSubview:self.eventPeopleScrollView];
    
    UILabel *topBuzzLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 5, 100, 20)];
    topBuzzLabel.textColor = [FontProperties getBlueColor];
    topBuzzLabel.text = @"Top Buzz";
    topBuzzLabel.textAlignment = NSTextAlignmentLeft;
    topBuzzLabel.font = [FontProperties mediumFont:15.0];
    [backgroundView addSubview:topBuzzLabel];
    
    self.arrayOfImageViews = [NSMutableArray new];
   
    UIButton *firstButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 35, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    firstButton.tag = 0;
    [firstButton addTarget:self action:@selector(chooseImage:) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:firstButton];

    UIImageView *firstImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    firstImageView.contentMode = UIViewContentModeScaleAspectFill;
    firstImageView.clipsToBounds = YES;
    [firstButton addSubview:firstImageView];
    [self.arrayOfImageViews addObject:firstImageView];
    
    UIButton *secondButton = [[UIButton alloc] initWithFrame:CGRectMake((self.frame.size.width - 2)/2 + 2, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 35, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    [secondButton addTarget:self action:@selector(chooseImage:) forControlEvents:UIControlEventTouchUpInside];
    secondButton.tag = 1;
    [backgroundView addSubview:secondButton];
    
    UIImageView *secondImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    secondImageView.contentMode = UIViewContentModeScaleAspectFill;
    secondImageView.clipsToBounds = YES;
    [secondButton addSubview:secondImageView];
    [self.arrayOfImageViews addObject:secondImageView];
    
    UIButton *thirdButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 35 + (self.frame.size.width - 2)/2 + 2, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    [thirdButton addTarget:self action:@selector(chooseImage:) forControlEvents:UIControlEventTouchUpInside];
    thirdButton.tag = 2;
    [backgroundView addSubview:thirdButton];
    
    self.thirdImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    self.thirdImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thirdImageView.clipsToBounds = YES;
    [thirdButton addSubview:self.thirdImageView];
    [self.arrayOfImageViews addObject:self.thirdImageView];
    
    UIButton *fourthButton = [[UIButton alloc] initWithFrame:CGRectMake((self.frame.size.width - 2)/2 + 2, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 35 + (self.frame.size.width - 2)/2 + 2, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    fourthButton.backgroundColor = UIColor.redColor;
    [fourthButton addTarget:self action:@selector(chooseImage:) forControlEvents:UIControlEventTouchUpInside];
    fourthButton.tag = 3;
    [backgroundView addSubview:fourthButton];
    
    self.fourthImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, (self.frame.size.width - 2)/2, (self.frame.size.width - 2)/2)];
    self.fourthImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.fourthImageView.clipsToBounds = YES;
    [fourthButton addSubview:self.fourthImageView];
    [self.arrayOfImageViews addObject:self.fourthImageView];
}

-(void) chooseImage:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = buttonSender.tag;
    WGEventMessage *eventMessage = (WGEventMessage *)[self.event.messages objectAtIndex:tag];
    [self.placesDelegate showHighlightForEvent:self.event
                               andEventMessage:eventMessage];

}

- (void)setEvent:(WGEvent *)event {
    _event = event;
    self.eventNameLabel.text = _event.name;
    if (_event.numAttending.intValue > 0) {
        self.numberOfPeopleGoingLabel.text = [NSString stringWithFormat:@"%@ went", _event.numAttending];
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
    
    self.eventPeopleScrollView.event = _event;
    NSDate *nowDate = [NSDate date];
    NSDateComponents *differenceDates = [event.created differenceBetweenDates:nowDate];
    int days = [differenceDates day];
    if (days == 1) self.dateLabel.text = @"Yesterday";
    else self.dateLabel.text = [NSString stringWithFormat:@"%d days ago", days];
    for (int i = 0; i < 4; i++) {
        UIImageView *imageView = [self.arrayOfImageViews objectAtIndex:i];
        if (i >= event.messages.count) {
            imageView.image = nil;
        }
        else {
            WGEventMessage *eventMessage = (WGEventMessage *)[event.messages objectAtIndex:i];
            NSString *contentURL;
            if (eventMessage.thumbnail) contentURL = eventMessage.thumbnail;
            else  contentURL = eventMessage.media;
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", WGProfile.currentUser.cdnPrefix, contentURL]];
            [imageView setImageWithURL:imageURL completed:nil];
        }
    }
    
}

@end

@implementation MoreThan2PhotosOldEventCell

+ (CGFloat)height {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    return 154 + 0.9*width/5.5 + (width -2);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [MoreThan2PhotosOldEventCell height]);
    
    UIImageView *shadowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-5, [MoreThan2PhotosOldEventCell height] - 20 - 7, self.frame.size.width + 10, 12)];
    shadowImageView.image = [UIImage imageNamed:@"shadow"];
    [self.contentView addSubview:shadowImageView];
    
    [super setup];
    self.thirdImageView.hidden = NO;
    self.fourthImageView.hidden = NO;
}

@end

@implementation LessThan2PhotosOldEventCell

+ (CGFloat)height {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    return 154 + 0.9*width/5.5 + (width -2)/2;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [LessThan2PhotosOldEventCell height]);
    
    UIImageView *shadowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-5, [LessThan2PhotosOldEventCell height] - 20 - 7, self.frame.size.width + 10, 12)];
    shadowImageView.image = [UIImage imageNamed:@"shadow"];
    [self.contentView addSubview:shadowImageView];
    
    [super setup];
    self.thirdImageView.hidden = YES;
    self.fourthImageView.hidden = YES;
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
    self.showHighlightsButton.layer.borderColor = RGB(232, 232, 232).CGColor;
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
