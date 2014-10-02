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

@interface MainViewController ()

// Bar at top
@property UIView *barAtTopView;
@property BOOL goingOutIsAttachedToScrollView;
@property CGPoint barAtTopPoint;

//Not going out View
@property UIView *notGoingOutView;
@property BOOL isFirstTimeNotGoingOutIsAttachedToScrollView;
@property BOOL notGoingOutIsAttachedToScrollView;
@property CGPoint notGoingOutStartingPoint;
@property CGPoint scrollViewPointWhenDeatached;

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
@property UILabel *goingOutLabel;
@property UILabel *goingOutLabelOnTopOfNotGoingOutLabel;
@property UILabel *notGoingOutLabel;
@property BOOL spinnerAtCenter;
@property BOOL fetchingFirstPage;
@property BOOL fetchingUserInfo;
@property BOOL fetchingIsThereNewPerson;

@property UIButtonAligned *rightButton;

@end

BOOL didProfileSegue;
int userInt;

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
        [self fetchFirstPageFollowing];
        if (!_fetchingUserInfo) [self fetchUserInfo];
        if (!_fetchingIsThereNewPerson)  [self fetchIsThereNewPerson];
        [self fetchSummaryGoingOut];
    }
    didProfileSegue = NO;
    userInt = -1;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    didProfileSegue = NO;
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
    _isFirstTimeNotGoingOutIsAttachedToScrollView = YES;
    
    [self initializeWhoView];
    [self initializeNotificationObservers];
}


// BEING CALLED TWICE
- (void)loadViewAfterSigningUser {
    [self fetchAppStart];
    _fetchingFirstPage = NO;
    _fetchingUserInfo = NO;
    _fetchingIsThereNewPerson = NO;
    _numberFetchedMyInfoAndEveryoneElse = 0;
    [self fetchFirstPageFollowing];
    if (!_fetchingUserInfo) [self fetchUserInfo];
    if (!_fetchingIsThereNewPerson)  [self fetchIsThereNewPerson];
    [self fetchSummaryGoingOut];
    [self fetchAreThereMoreThan3Events];

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
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *differenceDateComponents = [gregorianCalendar
                                                      components: NSHourCalendarUnit
                                                      fromDate:dateAccessed
                                                      toDate:newDate
                                                      options:0];
        if ([differenceDateComponents hour] >= 1) {
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
    _fetchingUserInfo = YES;
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if ([[jsonResponse allKeys] containsObject:@"status"]) {
            if (![[jsonResponse objectForKey:@"status"] isEqualToString:@"error"]) {
                User *user = [[User alloc] initWithDictionary:jsonResponse];
                if ([user key]) {
                    User *profileUser = [Profile user];
                    [profileUser setIsGoingOut:[user isGoingOut]];
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        _fetchingUserInfo = NO;
                        [self updateTitleView];
                        [self fetchedMyInfoOrPeoplesInfo];
                    });
                }
            }
        }
        else {
            User *user = [[User alloc] initWithDictionary:jsonResponse];
            if ([user key]) {
                User *profileUser = [Profile user];
                [profileUser setIsGoingOut:[user isGoingOut]];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    _fetchingUserInfo = NO;
                    [self updateTitleView];
                    [self fetchedMyInfoOrPeoplesInfo];
                });

            }
        }
    }];
}

- (void)fetchFirstPageFollowing {
    if (!_fetchingFirstPage) {
        _fetchingFirstPage = YES;
        _isFirstTimeNotGoingOutIsAttachedToScrollView = YES;
        _page = @1;
        [self fetchFollowing];
    }
}

- (void)fetchFollowing {
    NSString *queryString = [NSString stringWithFormat:@"users/?user=friends&ordering=is_goingout&page=%@", [_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ([_page isEqualToNumber:@1]) _fetchingFirstPage = NO;
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ([_page isEqualToNumber:@1]) {
                    _isFirstTimeNotGoingOutIsAttachedToScrollView = YES;
                    _notGoingOutView.hidden = YES;
                    _followingAcceptedParty = [[Party alloc] initWithObjectType:USER_TYPE];
                    _whoIsGoingOutParty = [[Party alloc] initWithObjectType:USER_TYPE];
                    _notGoingOutParty = [[Party alloc] initWithObjectType:USER_TYPE];
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
                if ([_page isEqualToNumber:@1]) _fetchingFirstPage = NO;
                if (!_spinnerAtCenter) [_collectionView didFinishPullToRefresh];
                _page = @([_page intValue] + 1);
                [_collectionView reloadData];
                [self.view bringSubviewToFront:_barAtTopView];
                [self fetchedMyInfoOrPeoplesInfo];
            });
        }
    }];
}


- (void) fetchIsThereNewPerson {
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
                    [_rightButton.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                    if ([lastUserRead intValue] < [lastUserJoinedNumber intValue]) {
                        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30, 30)];
                        imageView.image = [UIImage imageNamed:@"orangeFollowPlus"];
                        [_rightButton addSubview:imageView];
                    }
                    else {
                        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30, 30)];
                        imageView.image = [UIImage imageNamed:@"followPlus"];
                        [_rightButton addSubview:imageView];
                    }
                }
            });
        }
    }];
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
                for (UIView *subview in [_barAtTopView subviews]) {
                    if ([subview isKindOfClass:[UILabel class]]) {
                        NSString *newString = [NSString stringWithFormat:@"GOING OUT: %@", friendsGoingOut];
                        UILabel *label = (UILabel *)subview;
                        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:newString];
                        [attributedString addAttribute:NSFontAttributeName
                                     value:[FontProperties numericLightFont:15.0f]
                                     range:NSMakeRange(11, [friendsGoingOut stringValue].length)];
                        label.attributedText = attributedString;
                    }
                }
                for (UIView *subview in [_notGoingOutView subviews]) {
                    if ([subview isKindOfClass:[UILabel class]]) {
                        NSNumber *notGoingOutNumber = @([[[Profile user] numberOfFollowing] intValue] - [friendsGoingOut intValue]);
                        NSString *newString = [NSString stringWithFormat:@"NOT GOING OUT YET: %@", notGoingOutNumber];
                        UILabel *label = (UILabel *)subview;
                        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:newString];
                        [attributedString addAttribute:NSFontAttributeName
                                                 value:[FontProperties numericLightFont:15.0f]
                                                 range:NSMakeRange(19, [notGoingOutNumber stringValue].length)];
                        label.attributedText = attributedString;
                    }
                }
                
            });
        }
    }];
}

- (void) fetchAreThereMoreThan3Events {
        NSString *queryString = @"events/?date=tonight&page=1&attendees_limit=0";
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSArray *events = [jsonResponse objectForKey:@"objects"];
                if ([events count] >= 3) {
                    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
                    tabController.selectedViewController
                    = [tabController.viewControllers objectAtIndex:1];
                }
            });
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
    
    for (int i = 0; i < [[_whoIsGoingOutParty getObjectArray] count]; i++) {
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

- (void)initializeWhoView {
    [self initializeBarAtTopWithText:@"GOING OUT"];
    [self initializeNotGoingOutBar];
    [self initializeCollectionView];
}

- (void) initializeBarAtTopWithText:(NSString *)textAtTop {
    if (!_barAtTopView) {
        _barAtTopView = [[UIView alloc] init];
        _barAtTopView.backgroundColor = RGBAlpha(255, 255, 255, 0.95f);
        UILabel *barAtTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 15)];
        barAtTopLabel.text = textAtTop;
        barAtTopLabel.textAlignment = NSTextAlignmentLeft;
        UIFont *font = [FontProperties scLightFont:15.0f];
        barAtTopLabel.font = font;
        [_barAtTopView addSubview:barAtTopLabel];
    }
    
    _barAtTopView.frame = CGRectMake(0, 64, self.view.frame.size.width, 30);
    [self.view addSubview:_barAtTopView];
    [self.view bringSubviewToFront:_barAtTopView];
    _barAtTopPoint = _barAtTopView.frame.origin;
    _goingOutIsAttachedToScrollView = NO;
}

- (void) initializeNotGoingOutBar {
    if (!_notGoingOutView) {
        _notGoingOutView = [[UIView alloc] init];
        _notGoingOutView.backgroundColor = RGBAlpha(255, 255, 255, 0.95f);
        _notGoingOutView.hidden = YES;
        [self.view bringSubviewToFront:_notGoingOutView];
        
        UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 15)];
        goingOutLabel.text = @"NOT GOING OUT YET";
        goingOutLabel.textAlignment = NSTextAlignmentLeft;
        goingOutLabel.font = [FontProperties scLightFont:15.0f];
        [_notGoingOutView addSubview:goingOutLabel];
    }
    
    _notGoingOutIsAttachedToScrollView = YES;
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
    
    [self updateTitleView];
}

- (void) showTapButtons {
    if ([[Profile user] isGoingOut]) {
        
        for (int i = 0; i < [[_whoIsGoingOutParty getObjectArray] count]; i++) {
            User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
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
        self.peopleViewController = [[PeopleViewController alloc] initWithUser:[Profile user]];
        [self.navigationController pushViewController:self.peopleViewController animated:YES];
        self.tabBarController.tabBar.hidden = YES;
    }
}

- (void)myProfileSegue {
    if ([Profile user]) {
        self.profileViewController = [[ProfileViewController alloc] initWithUser:[Profile user]];
        [self.navigationController pushViewController:self.profileViewController animated:YES];
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
        if (!_fetchingIsThereNewPerson)  [self fetchIsThereNewPerson];
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
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 4;
    layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, 30);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49) collectionViewLayout:layout];
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
    // GET THE ARRAY OF USERS AND THE CORRESPONDING USER
    NSArray *userArray;
    if ([indexPath section] == 0) {
        if ([[_whoIsGoingOutParty getObjectArray] count] == 0) return cell;
        userArray = [_whoIsGoingOutParty getObjectArray];
    }
    else if ([indexPath section] == 1) {
        if ([[_notGoingOutParty getObjectArray] count] == 0) return cell;
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
//    else {
//        [self fetchFollowing];
//        return cell;
//    }
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
    if ([[Profile user] isGoingOut]) {
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
    
    [user setObject:cell.tapButton forKey:@"tapButton"];
    [user setObject:cell.tappedImageView forKey:@"tappedImageView"];
    [self setUser:user ForIndexPath:indexPath];
    
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

//#pragma mark - Header for UICollectionView
//
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return CGSizeMake(collectionView.bounds.size.width, 30);
    } else if (section == 1){
        return CGSizeMake(collectionView.bounds.size.width, 5 + 26 + 30);
    }
    else return CGSizeMake(collectionView.bounds.size.width, 10);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableView = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        reusableView = [_collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerCellIdentifier forIndexPath:indexPath];
        [[reusableView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

        if ([indexPath section] == 1) {
            _notGoingOutView.hidden = NO;
            if ([[_notGoingOutParty getObjectArray] count] == 0) {
                if (!_isFirstTimeNotGoingOutIsAttachedToScrollView) _isFirstTimeNotGoingOutIsAttachedToScrollView = YES;
                    _notGoingOutView.frame = CGRectMake(reusableView.frame.origin.x, self.view.frame.size.height, reusableView.frame.size.width, 30);
                    [_collectionView addSubview:_notGoingOutView];
                    _notGoingOutStartingPoint = _notGoingOutView.frame.origin;
            }
            else {
                if (_isFirstTimeNotGoingOutIsAttachedToScrollView) {
                    _isFirstTimeNotGoingOutIsAttachedToScrollView = NO;
                    _notGoingOutView.frame = CGRectMake(reusableView.frame.origin.x, reusableView.frame.origin.y + 30, reusableView.frame.size.width, 30);
                    [_collectionView addSubview:_notGoingOutView];
                    _notGoingOutStartingPoint = _notGoingOutView.frame.origin;
                }
            }
            
        }
        return reusableView;
    }
    return reusableView;
}


- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint notGoingOutPoint = [_notGoingOutView.superview convertPoint:_notGoingOutView.frame.origin toView:nil];
    
    // Going Out Label
    if (_goingOutIsAttachedToScrollView) {
        if (_collectionView.contentOffset.y > 0) {
            _goingOutLabelOnTopOfNotGoingOutLabel.hidden = YES;
            [_barAtTopView removeFromSuperview];
            _barAtTopView.frame = CGRectMake(0, 64, self.view.frame.size.width, 30);
            [self.view addSubview:_barAtTopView];
            [self.view bringSubviewToFront:_barAtTopView];
            _goingOutIsAttachedToScrollView = NO;
        }
    }
    if (!_goingOutIsAttachedToScrollView) {
        if (notGoingOutPoint.y <= 64 + 30) { // add to the scroll view when
            _goingOutLabelOnTopOfNotGoingOutLabel.hidden = NO;
            [_barAtTopView removeFromSuperview];
            _barAtTopView.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
            [_collectionView addSubview:_barAtTopView];
            _goingOutIsAttachedToScrollView = YES;
        }
        if ( _collectionView.contentOffset.y < 0) {
            _goingOutLabelOnTopOfNotGoingOutLabel.hidden = YES;
            [_barAtTopView removeFromSuperview];
            _barAtTopView.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
            [_collectionView addSubview:_barAtTopView];
            _goingOutIsAttachedToScrollView = YES;
        }
    }
    
    // Not Going out label
    if (_notGoingOutIsAttachedToScrollView) {
        if (notGoingOutPoint.y <= 64) {
            [_notGoingOutView removeFromSuperview];
            _notGoingOutView.frame = CGRectMake(0, 64, self.view.frame.size.width, 30);
            [self.view addSubview:_notGoingOutView];
            _scrollViewPointWhenDeatached = _collectionView.contentOffset;
            _notGoingOutIsAttachedToScrollView = NO;
        }
    }
    if (!_notGoingOutIsAttachedToScrollView) {
        if (_collectionView.contentOffset.y < _scrollViewPointWhenDeatached.y) {
            [_notGoingOutView removeFromSuperview];
            _notGoingOutView.frame = CGRectMake(0, _notGoingOutStartingPoint.y, self.view.frame.size.width, 30);
            [_collectionView addSubview:_notGoingOutView];
            _notGoingOutIsAttachedToScrollView = YES;
        }
    }
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
        UIImageViewShake *tappedImageView = [user objectForKey:@"tappedImageView"];
        if (tappedImageView != nil) {
            [tapArray addObject:tappedImageView];
            UIButton *tapButton = [user objectForKey:@"tapButton"];
            [tapButtonArray addObject:tapButton];
        }
       
    }
    
    for (int i = 0; i < [[_notGoingOutParty getObjectArray] count]; i++) {
        User *user = [self userForIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
        UIImageViewShake *tappedImageView =  [user objectForKey:@"tappedImageView"];
        if (tappedImageView != nil) {
            [tapArray addObject:tappedImageView];
            UIButton *tapButton = [user objectForKey:@"tapButton"];
            [tapButtonArray addObject:tapButton];
        }
    }
    
    for (UIImageViewShake *tappedImageView in tapArray) {
        CGRect previousFrame = tappedImageView.frame;
        [tapFrameArray addObject:[NSValue valueWithCGRect:previousFrame]];
        CGPoint centerFrame = [self.view convertPoint:self.view.center toView:tappedImageView.superview];
        tappedImageView.center = centerFrame;
        tappedImageView.hidden = YES;
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
        for (int i = 0; i <[tapArray count]; i++) {
            UIImageViewShake *tappedImageView = [tapArray objectAtIndex:i];
            tappedImageView.hidden = NO;
            UIButton *tapButton = [tapButtonArray objectAtIndex:i];
            tapButton.enabled = YES;
            CGRect previousFrame = [[tapFrameArray objectAtIndex:i] CGRectValue];
            tappedImageView.frame = previousFrame;
            [tappedImageView newShake];
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
