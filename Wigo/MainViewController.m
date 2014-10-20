//
//  MainViewController.m
//
//  Created by Giuliano Giacaglia on 28/6/13.

// Font

#import "MainViewController.h"
#import "Globals.h"

#import "UIImageViewShake.h"

// Extensions
#import "UIButtonAligned.h"
#import "UIButtonUngoOut.h"
#import "RWBlurPopover.h"
#import "PopViewController.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "CSStickyHeaderFlowLayout.h"
#import "PeopleViewController.h"

@interface MainViewController ()

// Who and Where Buttons properties
@property UIImageView *whoImageView;
// Saving Data
@property int numberFetchedMyInfoAndEveryoneElse;
@property NSMutableArray *userTappedIDArray;
@property int numberOfFetchedParties;
@property Party *followingAcceptedParty;
@property Party *whoIsGoingOutParty;
@property Party *notGoingOutParty;

@property NSNumber *page;
@property BOOL spinnerAtCenter;
@property BOOL fetchingUserInfo;
@property BOOL fetchingIsThereNewPerson;

@property UIButtonAligned *rightButton;
@end

BOOL fetchingFollowing;
BOOL didProfileSegue;
int userInt;
UILabel *redDotLabel;
NSString *goingOutString;
NSString *notGoingOutString;

@implementation MainViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = NO;
    [self initializeTabBar];
    [self initializeNavigationItem];
    [self showTapButtons];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [EventAnalytics tagEvent:@"Who View"];
    self.tabBarController.tabBar.hidden = NO;
    if (!didProfileSegue) {
        [self fetchUserInfo];
        [self fetchFirstPageFollowing];
        [self fetchIsThereNewPerson];
        [self fetchSummaryGoingOut];
    }
    didProfileSegue = NO;
    userInt = -1;
}

- (int) getTapInitialPosition {
    if ([[Profile user] isGoingOut]) return 1;
    else return 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    goingOutString = [NSString new];
    notGoingOutString = [NSString new];
    didProfileSegue = NO;
    fetchingFollowing = NO;
    userInt = -1;
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 1, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGBAlpha(244, 149, 45, 0.1f);
    [self.navigationController.navigationBar addSubview:lineView];
    
    

    [FBAppEvents logEvent:FBAppEventNameActivatedApp];
    [self initializeFlashScreen];
    _spinnerAtCenter = YES;
    
    [self initializeCollectionView];
    [self initializeNotificationObservers];
}


// BEING CALLED TWICE
- (void)loadViewAfterSigningUser {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"presentPush" object:nil];
    [self fetchAppStart];
    _fetchingUserInfo = NO;
    _fetchingIsThereNewPerson = NO;
    _numberFetchedMyInfoAndEveryoneElse = 0;
    [self fetchFirstPageFollowing];
    [self fetchUserInfo];
    [self fetchIsThereNewPerson];
    [self fetchSummaryGoingOut];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadColorWhenTabBarIsMessage" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTabBarNotifications" object:nil];
}

#pragma mark - Network function

- (BOOL)shouldFetchAppStartup {
    NSDate *dateAccessed = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastTimeAccessed"];
    if (!dateAccessed) {
        NSDate *firstSaveDate = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:firstSaveDate forKey: @"lastTimeAccessed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
    else {
        NSDate *newDate = [NSDate date];
        NSDateComponents *differenceDateComponents = [Time differenceBetweenFromDate:dateAccessed toDate:newDate];
        if ([differenceDateComponents hour] > 0 || [differenceDateComponents day] > 0 || [differenceDateComponents weekOfYear] > 0 || [differenceDateComponents month] > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:newDate forKey: @"lastTimeAccessed"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        }
    }
    return NO;
}

- (void)fetchAppStart {
    if ([self shouldFetchAppStartup]) {
        [Network queryAsynchronousAPI:@"app/startup" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (!error) {
                    if ([[jsonResponse allKeys] containsObject:@"prompt"]) {
                        NSDictionary *prompt = [jsonResponse objectForKey:@"prompt"];
                        if (prompt) [self presentViewController:[[PopViewController alloc] initWithDictionary:prompt] animated:YES completion:nil];
                    }
                    if ([[jsonResponse allKeys] containsObject:@"analytics"]) {
                        NSDictionary *analytics = [jsonResponse objectForKey:@"analytics"];
                        if (analytics) {
                            BOOL gAnalytics = YES;
                            NSNumber *gval = [analytics objectForKey:@"gAnalytics"];
                            if (gval) {
                                gAnalytics = [gval boolValue];
                            }
                            
                            [Profile setGoogleAnalyticsEnabled:gAnalytics];
                            [[NSUserDefaults standardUserDefaults] setBool:gAnalytics forKey:@"googleAnalyticsEnabled"];
                            
                            BOOL localytics = YES;
                            NSNumber *lval = [analytics objectForKey:@"localytics"];
                            if (lval) {
                                localytics = [lval boolValue];
                            }
                            [Profile setLocalyticsEnabled:localytics];
                            [[NSUserDefaults standardUserDefaults] setBool:localytics forKey:@"localyticsEnabled"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                            if (gAnalytics) [appDelegate initializeGoogleAnalytics];
                            if (localytics) [appDelegate initializeLocalytics];
                        }
                    }
                }
            });
        }];
    }
}

- (void) fetchUserInfo {
    if ([[Profile user] key] && !_fetchingUserInfo ) {
        _fetchingUserInfo = YES;
        [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            if ([[jsonResponse allKeys] containsObject:@"status"]) {
                if (![[jsonResponse objectForKey:@"status"] isEqualToString:@"error"]) {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        User *user = [[User alloc] initWithDictionary:jsonResponse];
                        if ([user key]) {
                            [Profile setUser:user];
                            _fetchingUserInfo = NO;
                            [self initializeNavigationItem];
                            [self fetchedMyInfoOrPeoplesInfo];
                        }
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    User *user = [[User alloc] initWithDictionary:jsonResponse];
                    if ([user key]) {
                        [Profile setUser:user];
                        _fetchingUserInfo = NO;
                        [self initializeNavigationItem];
                        [self fetchedMyInfoOrPeoplesInfo];
                    }
                });
            }
        }];
    }
}



- (void)fetchFirstPageFollowing {
    _page = @1;
    [self fetchFollowing];
}

- (void)fetchFollowing {
    if (!fetchingFollowing) {
        fetchingFollowing = YES;
        
        NSString *queryString;
        if (![_page isEqualToNumber:@1] && [_followingAcceptedParty nextPageString]) {
            queryString = [_followingAcceptedParty nextPageString];
        }
        else {
            queryString = [NSString stringWithFormat:@"users/?user=friends&ordering=is_goingout&page=%@", [_page stringValue]];
        }
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    fetchingFollowing = NO;
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    if ([_page isEqualToNumber:@1]) {
                        _followingAcceptedParty = [[Party alloc] initWithObjectType:USER_TYPE];
                        _whoIsGoingOutParty = [[Party alloc] initWithObjectType:USER_TYPE];
                        _notGoingOutParty = [[Party alloc] initWithObjectType:USER_TYPE];
                        if ([[Profile user] isGoingOut]) [_whoIsGoingOutParty addObject:[Profile user]];
                    }
                    NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
                    [_followingAcceptedParty addObjectsFromArray:arrayOfUsers];
                    NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
                    [_followingAcceptedParty addMetaInfo:metaDictionary];
                    [Profile setFollowingParty:_followingAcceptedParty];
                    User *user;
                    for (int i = 0; i < [arrayOfUsers count]; i++) {
                        NSDictionary *userDictionary = [arrayOfUsers objectAtIndex:i];
                        user = [[User alloc] initWithDictionary:userDictionary];
                        if ([user isGoingOut]) {
                            [_whoIsGoingOutParty addObject:user];
                        }
                        else {
                            [_notGoingOutParty addObject:user];
                        }
                    }
                    _page = @([_page intValue] + 1);
                    if (!_spinnerAtCenter) [_collectionView didFinishPullToRefresh];
                    [_collectionView reloadData];
                    fetchingFollowing = NO;
                    [self fetchedMyInfoOrPeoplesInfo];
                });
            }
        }];
    }
    else {
        if (!_spinnerAtCenter) [_collectionView didFinishPullToRefresh];
        fetchingFollowing = NO;
    }
   
}


- (void) fetchIsThereNewPerson {
    if (!_fetchingIsThereNewPerson) {
        _fetchingIsThereNewPerson = YES;
        [Network queryAsynchronousAPI:@"users/?limit=1" withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
            NSArray *objects = [jsonResponse objectForKey:@"objects"];
            _fetchingIsThereNewPerson = NO;
            if ([objects isKindOfClass:[NSArray class]]) {
                User *lastUserJoined = [[User alloc] initWithDictionary:[objects objectAtIndex:0]];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    User *profileUser = [Profile user];
                    if (profileUser) {
                        NSNumber *lastUserRead = [profileUser lastUserRead];
                        NSNumber *lastUserJoinedNumber = (NSNumber *)[lastUserJoined objectForKey:@"id"];
                        [Profile setLastUserJoined:lastUserJoinedNumber];
                        [_rightButton.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30, 30)];
                        imageView.image = [UIImage imageNamed:@"followPlus"];
                        [_rightButton addSubview:imageView];

                        if ([lastUserRead intValue] < [lastUserJoinedNumber intValue]) {
                            redDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 10, 10)];
                            redDotLabel.backgroundColor = [UIColor redColor];
                            redDotLabel.layer.borderColor = [UIColor clearColor].CGColor;
                            redDotLabel.clipsToBounds = YES;
                            redDotLabel.layer.borderWidth = 3;
                            redDotLabel.layer.cornerRadius = 5;
                            [_rightButton addSubview:redDotLabel];
                        }
                        else {
                            if (redDotLabel) [redDotLabel removeFromSuperview];
                        }
                    }
                });
            }
        }];
    }
}

- (void)updateUserAtTable:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    User *user = [[User alloc] initWithDictionary:userInfo];
    if (user) {
        int section;
        int tag = userInt;
        if (tag < 0) {
            tag = -tag;
            tag -= 1;
            section = 1;
            int sizeOfArray = (int)[[_notGoingOutParty getObjectArray] count];
            if (sizeOfArray > 0 && sizeOfArray > tag  && tag >= 0) {
                [_notGoingOutParty replaceObjectAtIndex:tag withObject:user];
                [_collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:tag inSection:section]]];
            }
        }
        else {
            tag -= 1;
            section = 0;
            int sizeOfArray = (int)[[_whoIsGoingOutParty getObjectArray] count];
            if (sizeOfArray > 0 && sizeOfArray > tag  && tag >= 0) {
                [_whoIsGoingOutParty replaceObjectAtIndex:tag withObject:user];
                [_collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:tag inSection:section]]];
            }
        }
        
    }
}

- (void) fetchSummaryGoingOut {
    [Network queryAsynchronousAPI:@"goingouts/summary/" withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        if ([[jsonResponse allKeys] containsObject:@"friends"]) {
            NSNumber *friendsGoingOut = [jsonResponse objectForKey:@"friends"];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                goingOutString = [NSString stringWithFormat:@"GOING OUT: %d", [friendsGoingOut intValue] + [self getTapInitialPosition]];
                NSNumber *notGoingOutNumber = @([[[Profile user] numberOfFollowing] intValue] - [friendsGoingOut intValue]);
                notGoingOutString = [NSString stringWithFormat:@"NOT GOING OUT YET: %@", notGoingOutNumber];
            });
        }
    }];
}

#pragma mark - viewDidLoad initializations

- (void)initializeFlashScreen {
    self.signViewController = [[SignViewController alloc] init];
    self.signNavigationViewController = [[SignNavigationViewController alloc] initWithRootViewController:self.signViewController];
    [self presentViewController:self.signNavigationViewController animated:NO completion:nil];
}



- (void)initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateViewNotGoingOut)
                                                 name:@"updateViewNotGoingOut"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadViewAfterSigningUser)
                                                 name:@"loadViewAfterSigningUser"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchFirstPageFollowing)
                                                 name:@"fetchFollowing"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollUp)
                                                 name:@"scrollUp"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchUserInfo)
                                                 name:@"fetchUserInfo"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUserAtTable:)
                                                 name:@"updateUserAtTable"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goOutPressed)
                                                 name:@"goOutPressed"
                                               object:nil];

}

- (void)scrollUp {
    [_collectionView setContentOffset:CGPointZero animated:YES];
}

- (void) updateViewNotGoingOut {
    [self updateTitleView];
    
    for (int i = [self getTapInitialPosition]; i < [[_whoIsGoingOutParty getObjectArray] count]; i++) {
        User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        UIImageViewShake *tappedImageView = [user objectForKey:@"tappedImageView"];
        tappedImageView.hidden = YES;
        UIButton *tapButton = [user objectForKey:@"tapButton"];
        tapButton.enabled = NO;
    }
    
    for (int i = 0; i < [[_notGoingOutParty getObjectArray] count]; i++) {
        User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
        UIImageViewShake *tappedImageView =  [user objectForKey:@"tappedImageView"];
        tappedImageView.hidden = YES;
        UIButton *tapButton = [user objectForKey:@"tapButton"];
        tapButton.enabled = NO;
    }
    
}



- (void) initializeTabBar {
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whoTabIcon"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
}

- (void) initializeNavigationItem {
    CGRect profileFrame = CGRectMake(0, 0, 30, 30);
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
     [profileImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]] placeholderImage:[[UIImage alloc] init] imageArea:[[Profile user] coverImageArea]];
    [profileButton addSubview:profileImageView];
    [profileButton addTarget:self action:@selector(myProfileSegue)
            forControlEvents:UIControlEventTouchUpInside];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.leftBarButtonItem = profileBarButton;
    
    _rightButton = [[UIButtonAligned alloc] initWithFrame: CGRectMake(0, 0, 30, 30) andType:@3];
    UIImageView *imageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30, 30)];
    imageView.image = [UIImage imageNamed:@"followPlus"];
    [_rightButton addSubview:imageView];
    [_rightButton addTarget:self action:@selector(followPressed)
          forControlEvents:UIControlEventTouchUpInside];
    [_rightButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:_rightButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    if ([Profile lastUserJoined]) {
        if ([[[Profile user]  lastUserRead] intValue] < [[Profile lastUserJoined] intValue]) {
            redDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 10, 10)];
            redDotLabel.backgroundColor = [UIColor redColor];
            redDotLabel.layer.borderColor = [UIColor clearColor].CGColor;
            redDotLabel.clipsToBounds = YES;
            redDotLabel.layer.borderWidth = 3;
            redDotLabel.layer.cornerRadius = 5;
            [_rightButton addSubview:redDotLabel];
        }
        else {
            if (redDotLabel) [redDotLabel removeFromSuperview];
        }
    }
    
    [self updateTitleView];
}

- (void) showTapButtons {
    if ([[Profile user] isGoingOut]) {
        for (int i = 0; i < [[_whoIsGoingOutParty getObjectArray] count]; i++) {
            User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (user && ![user isEqualToUser:[Profile user]]) {
                UIImageViewShake *tappedImageView =  [user objectForKey:@"tappedImageView"];
                tappedImageView.hidden = NO;
                UIButton *tapButton = [user objectForKey:@"tapButton"];
                tapButton.enabled = YES;
                if ([user isTapped]) {
                    tappedImageView.tag = -1;
                    tappedImageView.image = [UIImage imageNamed:@"tapFilled"];
                }
                else {
                    tappedImageView.tag = 1;
                    tappedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
                }
            }
        }
        
        for (int i = 0; i < [[_notGoingOutParty getObjectArray] count]; i++) {
            User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
            UIImageViewShake *tappedImageView =  [user objectForKey:@"tappedImageView"];
            tappedImageView.hidden = NO;
            UIButton *tapButton = [user objectForKey:@"tapButton"];
            tapButton.enabled = YES;
            if ([user isTapped]) {
                tappedImageView.tag = -1;
                tappedImageView.image = [UIImage imageNamed:@"tapFilled"];
            }
            else {
                tappedImageView.tag = 1;
                tappedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
            }
        }
    }
}

- (User *)userForIndexPath:(NSIndexPath *)indexPath {
    User *user = [[User alloc] init];
    if ([indexPath section] == 0) {
        user = [[_whoIsGoingOutParty getObjectArray] objectAtIndex:[indexPath row]];
    }
    else if ([indexPath section] ==1) {
        user = [[_notGoingOutParty getObjectArray] objectAtIndex:[indexPath row]];
    }
    return user;
}

- (void)setUser:(User *)user ForIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        [_whoIsGoingOutParty replaceObjectAtIndex:[indexPath row] withObject:user];
    }
    else if ([indexPath section] ==1) {
        [_notGoingOutParty replaceObjectAtIndex:[indexPath row] withObject:user];
    }
}

- (void)followPressed {
    if ([Profile user]) {
        [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:[Profile user]] animated:YES];
        self.tabBarController.tabBar.hidden = YES;
    }
}

- (void)myProfileSegue {
    if ([Profile user]) {
        didProfileSegue = YES;
        [self.navigationController pushViewController:[[ProfileViewController alloc] initWithUser:[Profile user]] animated:YES];
        self.tabBarController.tabBar.hidden = YES;
    }
}


- (void)profileSegue:(id)sender {
    UIButton* profileButton = (UIButton *)sender;
    int tag = (int)profileButton.tag;
    User *user;
    
    userInt = tag;
    if (tag < 0) {
        tag = -tag;
        tag -= 1;
        user = [[_notGoingOutParty getObjectArray] objectAtIndex:tag];
    }
    else {
        tag -= 1;
        user = [[_whoIsGoingOutParty getObjectArray] objectAtIndex:tag];
    }
    
    if (user) {
        didProfileSegue = YES;
        self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.profileViewController animated:YES];
        self.tabBarController.tabBar.hidden = YES;
    }
}

- (void) updateTitleView {
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    [self.navigationItem.leftBarButtonItem setTintColor:[FontProperties getOrangeColor]];
    self.navigationItem.titleView = nil;
    if ([[Profile user] isGoingOut]) {
        UIButtonUngoOut *ungoOutButton = [[UIButtonUngoOut alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
        self.navigationItem.titleView = ungoOutButton;
    }
    else {
        UIButton *goOutButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"go-out" withExtension:@"gif"];
        FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
        FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200, 30)];
        imageView.animatedImage = image;
        [goOutButton addSubview:imageView];
        [goOutButton addTarget:self action:@selector(goOutPressed) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = goOutButton;
    }
    [self updateUIShowingMyselfGoingOut];
}


- (void)updateUIShowingMyselfGoingOut {
    if ([[_whoIsGoingOutParty getObjectArray] count] > 0) {
        User *firstUser = [[_whoIsGoingOutParty getObjectArray] objectAtIndex:0];
        if (firstUser && [Profile user]) {
            if ([[Profile user] isGoingOut]) {
                if (![firstUser isEqualToUser:[Profile user]]) {
                    [_whoIsGoingOutParty insertObject:[Profile user] inObjectArrayAtIndex:0];
                    [_collectionView reloadData];
                }
            }
            else {
                if ([firstUser isEqualToUser:[Profile user]]) {
                    [_whoIsGoingOutParty removeObjectAtIndex:0];
                    [_collectionView reloadData];
                }
            }
        }
    }
}

- (UIImageView *)gifGoOut {
    NSMutableArray *goOutArray = [[NSMutableArray array] init];
    for (NSUInteger i  = 1; i <= 60; i++) {
        NSString *fileName = [NSString stringWithFormat:@"go-out_2-%lu.png",(unsigned long)i];
        [goOutArray addObject:[UIImage imageNamed:fileName]];
    }
    UIImageView *gifGoOutImageView = [[UIImageView alloc] init];
    gifGoOutImageView.animationImages = [NSArray arrayWithArray:goOutArray];
    [gifGoOutImageView startAnimating];
    return gifGoOutImageView;
}

- (UIImageView *)gifGlowing {
    NSMutableArray *goOutArray = [[NSMutableArray array] init];
    for (NSUInteger i  = 0; i <= 59; i++) {
        NSString *fileName = [NSString stringWithFormat:@"glowing-%lu.png",(unsigned long)i];
        [goOutArray addObject:[UIImage imageNamed:fileName]];
    }
    UIImageView *gifGoOutImageView = [[UIImageView alloc] init];
    gifGoOutImageView.animationImages = [NSArray arrayWithArray:goOutArray];
    [gifGoOutImageView startAnimating];
    return gifGoOutImageView;
}

- (void) goOutPressed {
    [Network postGoOut];
    [[Profile user] setIsGoingOut:YES];
    [self updateTitleView];
    [self showTapButtons];
    [self animationShowingTapIcons];
//    [self fetchUserInfo]; //TODO: Needs to be added when sent a notification from the startup view
}


- (void) tapPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    NSIndexPath *indexPath = [self indexPathFromTag:tag];
    WigoCustomCell *cell = (WigoCustomCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    User *user = [self userForIndexPath:indexPath];
    
    [cell.tappedImageView.superview bringSubviewToFront:cell.tappedImageView];
    if ([user isTapped]) {
        cell.tappedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
        [self updateUserAtIndex:tag];
    }
    else {
        [cell.tappedImageView newShake];
        cell.tappedImageView.image = [UIImage imageNamed:@"tapFilled"];
        [self sendTapToUserAtIndex:tag];
    }
}

- (void) sendTapToUserAtIndex:(int)tag {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Who", @"Tap Source", nil];
    [EventAnalytics tagEvent:@"Tap User" withDetails:options];

    User *user;
    if (tag < 0) {
        tag = -tag;
        tag -= 1;
        user = [[_notGoingOutParty getObjectArray] objectAtIndex:tag];
        [user setIsTapped:YES];
        [_notGoingOutParty replaceObjectAtIndex:tag withObject:user];
    }
    else {
        tag -= 1;
        user = [[_whoIsGoingOutParty getObjectArray] objectAtIndex:tag];
        [user setIsTapped:YES];
        [_whoIsGoingOutParty replaceObjectAtIndex:tag withObject:user];
    }
    [Network sendAsynchronousTapToUserWithIndex:[user objectForKey:@"id"]];
}

- (void) updateUserAtIndex:(int)tag {
    User *user;
    if (tag < 0) {
        tag = -tag;
        tag -= 1;
        user = [[_notGoingOutParty getObjectArray] objectAtIndex:tag];
        [user setIsTapped:NO];
        [_notGoingOutParty replaceObjectAtIndex:tag withObject:user];
    }
    else {
        tag -= 1;
        user = [[_whoIsGoingOutParty getObjectArray] objectAtIndex:tag];
        [user setIsTapped:NO];
        [_whoIsGoingOutParty replaceObjectAtIndex:tag withObject:user];
    }
    [Network sendUntapToUserWithId:[user objectForKey:@"id"]];
}

- (void)fetchedMyInfoOrPeoplesInfo {
    _numberFetchedMyInfoAndEveryoneElse += 1;
    if (_numberFetchedMyInfoAndEveryoneElse == 2) {
        [self showTapButtons];
    }
}


- (void)addRefreshToCollectonView {
    [WiGoSpinnerView addDancingGToUIScrollView:_collectionView withHandler:^{
        _spinnerAtCenter = NO;
        [self fetchFirstPageFollowing];
        [self fetchIsThereNewPerson];
        [self fetchSummaryGoingOut];
    }];
}

- (NSIndexPath *)indexPathFromTag:(int)tag {
    if (tag < 0) {
        tag = -tag;
        tag -= 1;
        return [NSIndexPath indexPathForRow:tag inSection:1];
    }
    else {
        tag -= 1;
        return [NSIndexPath indexPathForRow:tag inSection:0];
    }
}

#pragma mark - Collection view Data Source

- (void) initializeCollectionView {
    self.automaticallyAdjustsScrollViewInsets = NO;
    CSStickyHeaderFlowLayout *layout = [[CSStickyHeaderFlowLayout alloc] init];
    if ([layout isKindOfClass:[CSStickyHeaderFlowLayout class]]) {
        layout.parallaxHeaderReferenceSize = CGSizeMake(320, 1);
        layout.parallaxHeaderMinimumReferenceSize = CGSizeMake(320, 1);
    }
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 4;
    layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, 30);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49) collectionViewLayout:layout];
    [_collectionView registerNib:[UINib nibWithNibName:@"Footer" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    [_collectionView registerNib:[UINib nibWithNibName:@"LineHeader" bundle:nil] forSupplementaryViewOfKind:CSStickyHeaderParallaxHeader withReuseIdentifier:@"header"];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceVertical = YES;
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerCellIdentifier];
    [_collectionView registerNib:[UINib nibWithNibName:@"WigoCustomCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"WigoCustomCell"];
    _collectionView.backgroundColor = [UIColor clearColor];
    [self addRefreshToCollectonView];
    [self.view addSubview:_collectionView];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) {
        return [[_whoIsGoingOutParty getObjectArray] count];
    }
    else {
        int hasNextPage = ([_followingAcceptedParty hasNextPage] ? 1 : 0);
        return [[_notGoingOutParty getObjectArray] count] + hasNextPage;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WigoCustomCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WigoCustomCell" forIndexPath:indexPath];
    cell.userCoverImageView.image = nil;
    cell.tappedImageView.image = nil;
    cell.profileName.text = nil;
    // GET THE ARRAY OF USERS AND THE CORRESPONDING USER
    NSArray *userArray;
    if ([indexPath section] == 0) {
        if ([[_whoIsGoingOutParty getObjectArray] count] == 0) return cell;
        userArray = [_whoIsGoingOutParty getObjectArray];
        if ([[_notGoingOutParty getObjectArray] count] == 0 &&
            [indexPath row] == [[_whoIsGoingOutParty getObjectArray] count]) {
            [self fetchFollowing];
            return cell;
        }
    }
    else if ([indexPath section] == 1) {
        if ([[_notGoingOutParty getObjectArray] count] == 0) {
            if ([_followingAcceptedParty hasNextPage]) [self fetchFollowing];
            return cell;
        }
        userArray = [_notGoingOutParty getObjectArray];
        if ([_followingAcceptedParty hasNextPage] && [[_notGoingOutParty getObjectArray] count] > 7) {
            if ([indexPath row] == [[_notGoingOutParty getObjectArray] count] - 7) {
                [self fetchFollowing];
            }
        }
        else {
            if ([indexPath row] == [[_notGoingOutParty getObjectArray] count]) {
                [self fetchFollowing];
                return cell;
            }
        }
    }

    if ([userArray count] == 0 || (int)[indexPath row] >= [userArray count]) return cell;
    User *user = [userArray objectAtIndex:[indexPath row]];
    
    // DETERMINE THE INTEGER THAT BUTTONS WILL BE TAGGED WITH
    int tag;
    if ([indexPath section] == 0) {
        tag = (int)[indexPath row];
        tag += 1;
    }
    else {
        tag = - (int)[indexPath row];
        tag -= 1;
    }

    if (cell == nil) {
        cell = [[WigoCustomCell alloc] init];
        cell.contentView.backgroundColor = [UIColor redColor];
    }
    cell.delegate = self;
    cell.profileButton.tag = tag;
    cell.profileButton2.tag = tag;
    cell.profileButton3.tag = tag;
    
    [cell.userCoverImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] placeholderImage:[[UIImage alloc] init] imageArea:[user coverImageArea]];
    
    cell.userCoverImageView.tag = tag;
    cell.profileName.text = [user firstName];
    cell.profileName.tag = tag;
    if ([user isFavorite])
        cell.favoriteSmall.image = [UIImage imageNamed:@"favoriteSmall"];
    else cell.favoriteSmall.image = nil;
    cell.tapButton.enabled = [[Profile user] isGoingOut] ? YES : NO;
    cell.tapButton.tag = tag;
    if ([[Profile user] isGoingOut] && ([indexPath section] == 1 || [indexPath row] >= [self getTapInitialPosition])) {
        cell.tappedImageView.hidden = NO;
        cell.profileButton3.enabled = NO;
    }
    else {
        cell.tappedImageView.hidden = YES;
        cell.profileButton3.enabled = YES;
    }
    if ([user isTapped]) {
        cell.tappedImageView.tag = -1;
        cell.tappedImageView.image = [UIImage imageNamed:@"tapFilled"];
    }
    else {
        cell.tappedImageView.tag = 1;
        cell.tappedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
    }
    if (![user isEqualToUser:[Profile user]]) {
        [user setObject:cell.tapButton forKey:@"tapButton"];
        [user setObject:cell.tappedImageView forKey:@"tappedImageView"];
        [self setUser:user ForIndexPath:indexPath];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int NImages = 3;
    int distanceOfEachImage = 4;
    int totalDistanceOfAllImages = distanceOfEachImage * (NImages - 1); // 10 pts is the distance of each image
    int sizeOfEachImage = self.view.frame.size.width - totalDistanceOfAllImages; // 10 pts on the extreme left and extreme right
    sizeOfEachImage /= NImages;
    return CGSizeMake(sizeOfEachImage, sizeOfEachImage);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(self.view.frame.size.width, 56);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return CGSizeMake(collectionView.bounds.size.width, 30);
    } else if (section == 1){
        return CGSizeMake(collectionView.bounds.size.width, 30);
    }
    else return CGSizeMake(collectionView.bounds.size.width, 10);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:headerCellIdentifier
                                                                 forIndexPath:indexPath];
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
        headerView.backgroundColor = [UIColor whiteColor];
        [cell addSubview:headerView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, self.view.frame.size.width - 5, 30)];
        label.backgroundColor = [UIColor whiteColor];
        label.font = [FontProperties scLightFont:15.0f];
        NSString *newString;
        if ([indexPath section] == 0) {
            if (goingOutString.length > 0) {
                newString = goingOutString;
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:newString];
                [attributedString addAttribute:NSFontAttributeName
                                         value:[FontProperties numericLightFont:15.0f]
                                         range:NSMakeRange(11, newString.length - 11)];
                label.attributedText = attributedString;
            }
            else label.text = @"GOING OUT";
           
        }
        else {
            if (notGoingOutString.length > 0) {
               newString = notGoingOutString;
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:newString];
                [attributedString addAttribute:NSFontAttributeName
                                         value:[FontProperties numericLightFont:15.0f]
                                         range:NSMakeRange(19, newString.length - 19)];
                label.attributedText = attributedString;
            }
            else label.text = @"NOT GOING OUT YET";
        }
        
        [headerView addSubview:label];
        
        return cell;
    } else if ([kind isEqualToString:CSStickyHeaderParallaxHeader]) {
        UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                            withReuseIdentifier:@"header"
                                                                                   forIndexPath:indexPath];
        return cell;
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:@"footer"
                                                                               forIndexPath:indexPath];
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
        footerView.backgroundColor = [UIColor whiteColor];
        if ([indexPath section] == 1 && [_followingAcceptedParty hasNextPage]) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
            spinner.center = footerView.center;
            [footerView addSubview:spinner];
            [spinner startAnimating];
        }
        [cell addSubview:footerView];

        return cell;
    }
    return nil;
}

#pragma mark - Animation

- (void) animationShowingTapIcons {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    UIImageView *orangeTapImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeTap"]];
    orangeTapImgView.frame = CGRectMake(0, 0, 30, 30);
    orangeTapImgView.center = self.view.center;
    orangeTapImgView.alpha = 1.0;
    [self.view addSubview:orangeTapImgView];

    UILabel *tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(100 - 70, 100 - 60, 140, 120)];
    NSString *text = @"TAP PEOPLE YOU WANT TO SEE OUT";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    [paragrahStyle setLineSpacing:5];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:NSMakeRange(0, [text length])];
    tapLabel.attributedText = attributedString;
    tapLabel.textAlignment = NSTextAlignmentCenter;
    tapLabel.numberOfLines = 0;
    tapLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tapLabel.font = [FontProperties getBigButtonFont];
    tapLabel.textColor = [UIColor whiteColor];
    tapLabel.alpha = 0;
    [orangeTapImgView addSubview:tapLabel];

    NSMutableArray *tapArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray *tapFrameArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray *tapButtonArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i = 0; i < [[_whoIsGoingOutParty getObjectArray] count]; i++) {
        User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (user && ![user isEqualToUser:[Profile user]]) {
            UIImageViewShake *tappedImageView = [user objectForKey:@"tappedImageView"];
            if (tappedImageView) {
                tappedImageView.hidden = YES;
                [tapArray addObject:tappedImageView];
                UIButton *tapButton = [user objectForKey:@"tapButton"];
                [tapButtonArray addObject:tapButton];
            }
        }
    }
    
    for (int i = 0; i < [[_notGoingOutParty getObjectArray] count]; i++) {
        User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
        UIImageViewShake *tappedImageView =  [user objectForKey:@"tappedImageView"];
        if (tappedImageView) {
            tappedImageView.hidden = YES;
            [tapArray addObject:tappedImageView];
            UIButton *tapButton = [user objectForKey:@"tapButton"];
            [tapButtonArray addObject:tapButton];
        }
    }
    
    for (UIImageViewShake *tappedImageView in tapArray) {
        tappedImageView.hidden = YES;
        CGRect previousFrame = tappedImageView.frame;
        [tapFrameArray addObject:[NSValue valueWithCGRect:previousFrame]];
        CGPoint centerPoint = [self.view convertPoint:self.view.center toView:tappedImageView.superview];
        tappedImageView.center = centerPoint;
    }

    [UIView animateWithDuration:0.3
    animations:^{
        orangeTapImgView.alpha = 0.7;
        orangeTapImgView.frame = CGRectMake(self.view.center.x - 2.5, self.view.center.y - 2.5, 5, 5);
    }
    completion:^(BOOL finished) {
    [UIView animateWithDuration:0.3
    animations:^{
        orangeTapImgView.alpha = 0.85;
        orangeTapImgView.frame = CGRectMake(self.view.center.x - 125, self.view.center.y  - 125, 250, 250);
    }
    completion:^(BOOL finished) {
    [UIView animateWithDuration:0.3
    animations:^{
        orangeTapImgView.frame = CGRectMake(self.view.center.x - 100, self.view.center.y  - 100, 200, 200);
    }
    completion:^(BOOL finished) {
    [UIView animateWithDuration:0.1
    animations:^{
        orangeTapImgView.alpha = 1.0;
        tapLabel.alpha = 1.0;
    }
    completion:^(BOOL finished) {
    [UIView animateWithDuration:2.1 delay:0.5 options:UIViewAnimationOptionCurveLinear
    animations:^{
        orangeTapImgView.alpha = 0.5;
        orangeTapImgView.frame = CGRectMake(self.view.center.x - 125, self.view.center.y - 125, 250, 250);
        tapLabel.frame = CGRectMake(125 - 70, 125 - 60, 140, 120);
    }
    completion:^(BOOL finished) {
    [UIView animateWithDuration:0.1
    animations:^{
        orangeTapImgView.alpha = 0.2;
        orangeTapImgView.frame = CGRectMake(self.view.center.x - 10, self.view.center.y - 10, 10, 10);
        tapLabel.frame = CGRectMake(10 - 5, 10 - 4, 5, 4);
    }
    completion:^(BOOL finished){
    [UIView animateWithDuration:0.1
    animations:^{
        orangeTapImgView.alpha = 0;
        orangeTapImgView.frame = CGRectMake(self.view.center.x - 40, self.view.center.y - 40, 80, 80);
    }
    completion:^(BOOL finished) {
    [UIView animateWithDuration:0.2
    animations:^{
        for (int i = 0; i < [tapArray count]; i++) {
            UIImageViewShake *tappedImageView = [tapArray objectAtIndex:i];
            UIButton *tapButton = [tapButtonArray objectAtIndex:i];
            NSIndexPath *indexPath = [self indexPathFromTag:(int)(tapButton.tag)];
            // Profile user is supposedly already going out (but it does not hurt to double check).
            if ([[Profile user] isGoingOut] && ([indexPath section] == 1 || [indexPath row] >= [self getTapInitialPosition])) {
                tappedImageView.hidden = NO;
                tapButton.enabled = YES;
                CGRect previousFrame = [[tapFrameArray objectAtIndex:i] CGRectValue];
                tappedImageView.frame = previousFrame;
                [tappedImageView newShake];
            }
       }
    }
    completion:^(BOOL finised) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
    }];
    }];
    }];
    }];
    }];
    }];
    }];
}




@end
