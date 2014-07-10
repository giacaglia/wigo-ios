//
//  MainViewController.m
//
//  Created by Giuliano Giacaglia on 28/6/13.

// Font
#import "FontProperties.h"

#import "MainViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "UIImageViewShake.h"

// Extensions
#import "UIButtonAligned.h"
#import "UIButtonUngoOut.h"

#import "Profile.h"
#import "User.h"
#import "Party.h"
#import "Network.h"
#import "MBProgressHUD.h"

#import "SDWebImage/UIImageView+WebCache.h"


@interface MainViewController ()

// Properties shared by Who and Where View
@property BOOL isGoingOut;

// Properties of the Who View
@property UIScrollView *scrollView;
@property int startingYPosition;
@property int shownImageNumber;

// Tap Array (First object tag is 2)
@property NSMutableArray *tapArray;
@property NSMutableArray *tapButtonArray;
@property int indexOfImage;
@property NSMutableArray *tapFrameArray;

// Bar at top
@property UIView *barAtTopView;
@property UILabel *barAtTopLabel;
@property BOOL goingOutIsAttachedToScrollView;
@property CGPoint barAtTopPoint;

//Not going out View
@property UIView *notGoingOutView;
@property BOOL notGoingOutIsAttachedToScrollView;
@property CGPoint notGoingOutStartingPoint;
@property CGPoint scrollViewPointWhenDeatached;

// Who and Where Buttons properties
@property UIImageView *whoImageView;

// Saving Data
@property int numberFetchedMyInfoAndEveryoneElse;
@property NSMutableArray *userTappedIDArray;
@property int numberOfFetchedParties;
@property Party *everyoneParty;
@property Party *followingAcceptedParty;
@property Party *followingNotAcceptedParty;
@property Party *whoIsGoingOutParty;
@property Party *notGoingOutParty;
@property UITableView *whoTableView;
@end

@implementation MainViewController

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    [self initializeTabBar];
    [self initializeNavigationItem];
}

- (void) viewDidAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeFlashScreen];
    
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor clearColor]];
    [self initializeScrollView];
    [self initializeNotificationObservers];
}

- (void)loadViewAfterSigningUser {
    _numberFetchedMyInfoAndEveryoneElse = 0;
    [self fetchUserInfo];
    [self fetchEveryone];
    [self fetchFollowers];
    [self fetchTaps];
}

- (void) fetchUserInfo {
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        User *user = [[User alloc] initWithDictionary:jsonResponse];
        User *profileUser = [Profile user];
//        NSLog([user isGoingOut] ? @"Is Going out" : @"Not going out");
        [profileUser setIsGoingOut:[user isGoingOut]];
        [Profile setUser:profileUser];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateTitleView];
            [self fetchedMyInfoOrPeoplesInfoOrTaps];
        });
    }];
}

- (void) fetchEveryone {
    [Network fetchAsynchronousAPI:@"users/" withResult:^(NSArray *arrayOfUsers, NSError *error) {
        _everyoneParty = [[Party alloc] initWithObjectName:@"User"];
        [_everyoneParty addObjectsFromArray:arrayOfUsers];
        [Profile setEveryoneParty:_everyoneParty];
    }];
}

- (void)fetchFollowers {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _numberOfFetchedParties = 0;
    [Network queryAsynchronousAPI:@"follows/?user=me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
        NSMutableArray *arrayOfAcceptedUsers = [[NSMutableArray alloc] initWithCapacity:0];
        NSMutableArray *arrayOfNotAcceptedUsers = [[NSMutableArray alloc] initWithCapacity:0];
        
        for (NSDictionary *object in arrayOfFollowObjects) {
            if ([[object objectForKey:@"accepted"] isEqualToNumber:@1]) {
                [arrayOfAcceptedUsers addObject:[object objectForKey:@"follow"]];
            }
            else {
                [arrayOfNotAcceptedUsers addObject:[object objectForKey:@"follow"]];
            }
        }
        _followingAcceptedParty = [[Party alloc] initWithObjectName:@"User"];
        [_followingAcceptedParty addObjectsFromArray:arrayOfAcceptedUsers];
        _followingNotAcceptedParty = [[Party alloc] initWithObjectName:@"User"];
        [_followingNotAcceptedParty addObjectsFromArray:arrayOfNotAcceptedUsers];
        [Profile setFollowingParty:_followingAcceptedParty];
        [Profile setNotAcceptedFollowingParty:_followingNotAcceptedParty];
        [self fetchedOneParty];
        
        [self fetchGoingOuts];
    }];
}

- (void)fetchGoingOuts {
    [Network fetchAsynchronousAPI:@"goingouts/?user=friends" withResult:^(NSArray *arrayOfUsers, NSError *error) {
        _whoIsGoingOutParty = [[Party alloc] initWithObjectName:@"User"];
        for (NSDictionary *object in arrayOfUsers) {
            NSNumber* userID = [object objectForKey:@"user"];
            [_whoIsGoingOutParty addObject:[_followingAcceptedParty getObjectWithId:userID]];
        }
        [_whoIsGoingOutParty removeUserFromParty:[Profile user]];
        [self fetchedOneParty];
    }];
}

- (void)fetchTaps {
    [Network fetchAsynchronousAPI:@"taps/?user=me" withResult:^(NSArray *taps, NSError *error) {
        _userTappedIDArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [taps count]; i++) {
            NSDictionary *userTappedDictionary = [[taps objectAtIndex:i] objectForKey:@"tapped"];
            [_userTappedIDArray addObject:[userTappedDictionary objectForKey:@"id"]];
        }
        [self fetchedMyInfoOrPeoplesInfoOrTaps];
    }];
}

- (void)fetchedOneParty {
    _numberOfFetchedParties +=1;
    if (_numberOfFetchedParties == 2) {
        
        // Update NOT GOING OUT PARTY
        _notGoingOutParty = [[Party alloc] initWithObjectName:@"User"];
        for (User *user in [_followingAcceptedParty getObjectArray]) {
            if (![_whoIsGoingOutParty containsObject:user]) {
                [_notGoingOutParty addObject:user];
            }
        }
        [_notGoingOutParty removeUserFromParty:[Profile user]];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self newInitializeWhoView];
            [self fetchedMyInfoOrPeoplesInfoOrTaps];
        });
    }
}

#pragma mark - viewDidLoad initializations

- (void)initializeFlashScreen {
    self.signViewController = [[SignViewController alloc] init];
    self.signNavigationViewController = [[SignNavigationViewController alloc] initWithRootViewController:self.signViewController];
    [self presentViewController:self.signNavigationViewController animated:NO completion:nil];
}

- (void) initializeScrollView {
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height)];
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint notGoingOutPoint = [_notGoingOutView.superview convertPoint:_notGoingOutView.frame.origin toView:nil];
    // Going Out Label
    if (_goingOutIsAttachedToScrollView) {
        if (_scrollView.contentOffset.y > 0) {
            [_barAtTopView removeFromSuperview];
            _barAtTopView.frame = CGRectMake(0, 64, self.view.frame.size.width, 30);
            [self.view addSubview:_barAtTopView];
            _goingOutIsAttachedToScrollView = NO;
        }
    }
    if (!_goingOutIsAttachedToScrollView) {
        if (notGoingOutPoint.y <= 64 + 30) { // add to the scroll view when
            [_barAtTopView removeFromSuperview];
            _barAtTopView.frame = CGRectMake(0, _notGoingOutView.frame.origin.y - 30, self.view.frame.size.width, 30);
            [_scrollView addSubview:_barAtTopView];
            _goingOutIsAttachedToScrollView = YES;
        }
        if ( _scrollView.contentOffset.y < 0) {
            [_barAtTopView removeFromSuperview];
            _barAtTopView.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
            [_scrollView addSubview:_barAtTopView];
            _goingOutIsAttachedToScrollView = YES;
        }
    }
    
    // Not Going out label
    if (_notGoingOutIsAttachedToScrollView) {
        if (notGoingOutPoint.y <= 64) {
            [_notGoingOutView removeFromSuperview];
            _notGoingOutView.frame = CGRectMake(0, 64, self.view.frame.size.width, 30);
            [self.view addSubview:_notGoingOutView];
            _scrollViewPointWhenDeatached = _scrollView.contentOffset;
            _notGoingOutIsAttachedToScrollView = NO;
        }
    }
    if (!_notGoingOutIsAttachedToScrollView) {
        if (_scrollView.contentOffset.y < _scrollViewPointWhenDeatached.y) {
            [_notGoingOutView removeFromSuperview];
            _notGoingOutView.frame = CGRectMake(0, _notGoingOutStartingPoint.y - 64, self.view.frame.size.width, 30);
            [_scrollView addSubview:_notGoingOutView];
            _notGoingOutIsAttachedToScrollView = YES;
        }
    }
}

- (void)initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViewNotGoingOut) name:@"updateViewNotGoingOut" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadViewAfterSigningUser) name:@"loadViewAfterSigningUser" object:nil];
}

- (void) updateViewNotGoingOut {
    [self updateTitleView];
    for (int i = 0; i < [_tapArray count]; i++) {
        UIImageViewShake *tappedImageView = [_tapArray objectAtIndex:i];
        tappedImageView.hidden = YES;
        UIButton *tapButton = [_tapButtonArray objectAtIndex:i];
        tapButton.enabled = NO;
    }
}

- (void)initializeWhoTableView {
    _startingYPosition = 64;
    [self initializeBarAtTopWithText:@"GOING OUT"];
    
    _startingYPosition -= 64;
    _whoTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    [self addImagesOfParty:_whoIsGoingOutParty];
    
    //HACK (May need to fix)
    _startingYPosition += 104 + 5;
    _startingYPosition -= 5;
    [self initializeNotGoingOutBar];
    
    _indexOfImage = -1;
    [self addImagesOfParty:_notGoingOutParty];
    _shownImageNumber = 0;
    
    [self fetchUserInfo];
}

- (void) newInitializeWhoView {
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    _startingYPosition = 64;
    [self initializeBarAtTopWithText:@"GOING OUT"];

    _startingYPosition -= 64;
    _tapArray = [[NSMutableArray alloc] initWithCapacity:0];
    _tapButtonArray = [[NSMutableArray alloc] initWithCapacity:0];
    _indexOfImage = 1;
    [self addImagesOfParty:_whoIsGoingOutParty];
    
    //HACK (May need to fix)
    _startingYPosition += 104 + 5;
    _startingYPosition -= 5;
    [self initializeNotGoingOutBar];
    
    _indexOfImage = -1;
    [self addImagesOfParty:_notGoingOutParty];
    _shownImageNumber = 0;
}

- (void)addImagesOfParty:(Party *)party {
    int NImages = 3;
    int distanceOfEachImage = 4;
    int totalDistanceOfAllImages = distanceOfEachImage * (NImages - 1); // 10 pts is the distance of each image
    int sizeOfEachImage = self.view.frame.size.width - totalDistanceOfAllImages; // 10 pts on the extreme left and extreme right
    sizeOfEachImage /= NImages;
    int positionX = 0;
    NSArray *userArray = [party getObjectArray];
    for (int i = 0; i < [userArray count]; i++) {
        int tag = _indexOfImage;
        if (_indexOfImage > 0 ) {
            _indexOfImage += 1;
        }
        else {
            _indexOfImage -= 1;
        }
        User *user = [userArray objectAtIndex:i];
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        [imgView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
        imgView.frame = CGRectMake(positionX, _startingYPosition, sizeOfEachImage, sizeOfEachImage);
        imgView.userInteractionEnabled = YES;
        positionX += sizeOfEachImage + distanceOfEachImage;
        if (i%(NImages) == (NImages -1)) { //If it's the last image in the row
            _startingYPosition += sizeOfEachImage + 5; // 5 is the distance of the images on the bottom
            positionX = 0;
        }
        imgView.alpha = 1.0;
        imgView.tag = tag;
        [_scrollView addSubview:imgView];
        
        UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, imgView.frame.size.height * 0.5, imgView.frame.size.width, imgView.frame.size.height * 0.5)];
        [profileButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
        [imgView bringSubviewToFront:profileButton];
        [imgView addSubview:profileButton];
        
        UIButton *buttonAtTop = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, imgView.frame.size.width * 0.5, imgView.frame.size.height * 0.5)];
        [buttonAtTop addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
        [imgView bringSubviewToFront:buttonAtTop];
        [imgView addSubview:buttonAtTop];
        
        UILabel *profileName = [[UILabel alloc] init];
        profileName.text = [user firstName];
        profileName.textColor = [UIColor whiteColor];
        profileName.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.frame = CGRectMake(0, sizeOfEachImage - 25, sizeOfEachImage, 25);
        profileName.font = [FontProperties getSmallFont];
        profileName.tag = -1;
        [imgView addSubview:profileName];
        
        UIButton *tapButton = [[UIButton alloc] initWithFrame:CGRectMake(imgView.frame.size.width/2, 0, imgView.frame.size.width/2, imgView.frame.size.height/2)];
        [tapButton addTarget:self action:@selector(selectedProfile:) forControlEvents:UIControlEventTouchUpInside];
        [imgView bringSubviewToFront:tapButton];
        [imgView addSubview:tapButton];
        tapButton.enabled = NO;
        tapButton.tag = tag;
        [_tapButtonArray addObject:tapButton];
        
        UIImageViewShake *tappedImageView = [[UIImageViewShake alloc] initWithFrame:CGRectMake(imgView.frame.size.width - 30 - 5, 5, 30, 30)];
        tappedImageView.tintColor = [FontProperties getOrangeColor];
        if ([self isUserTapped:user]) {
            tappedImageView.tag = -1;
            tappedImageView.image = [UIImage imageNamed:@"tapFilled"];
        }
        else {
            tappedImageView.tag = 1;
            tappedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
        }

        if (![[Profile user] isGoingOut]) {
            tappedImageView.hidden = YES;
        }
        else {
            tapButton.enabled = YES;
        }
        [_tapArray addObject:tappedImageView];
        [imgView addSubview:tappedImageView];
    }
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, MAX(_startingYPosition, self.view.frame.size.height + 200));
}

- (void) initializeBarAtTopWithText:(NSString *)textAtTop {
    if (!_barAtTopView) {
        _barAtTopView = [[UIView alloc] init];
        _barAtTopView.backgroundColor = RGBAlpha(255, 255, 255, 0.95f);
        [self.view bringSubviewToFront:_barAtTopView];
       
        _barAtTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 15)];
        _barAtTopLabel.text = textAtTop;
        _barAtTopLabel.textAlignment = NSTextAlignmentLeft;
        _barAtTopLabel.font = [UIFont fontWithName:@"Whitney-LightSC" size:15.0];
        [_barAtTopView addSubview:_barAtTopLabel];
    }
    
    _barAtTopView.frame = CGRectMake(0, _startingYPosition, self.view.frame.size.width, 30);
    [_barAtTopView removeFromSuperview];
     [self.view addSubview:_barAtTopView];
    _barAtTopPoint = _barAtTopView.frame.origin;
    _goingOutIsAttachedToScrollView = NO;
    _startingYPosition += 30;
}

- (void) initializeNotGoingOutBar {
    if (!_notGoingOutView) {
        _notGoingOutView = [[UIView alloc] init];
        _notGoingOutView.backgroundColor = RGBAlpha(255, 255, 255, 0.95f);
        [self.view bringSubviewToFront:_notGoingOutView];
        
        UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 15)];
        goingOutLabel.text = @"NOT GOING OUT YET";
        goingOutLabel.textAlignment = NSTextAlignmentLeft;
        goingOutLabel.font = [UIFont fontWithName:@"Whitney-LightSC" size:15.0];
        [_notGoingOutView addSubview:goingOutLabel];
    }
    
    _notGoingOutView.frame = CGRectMake(0, _startingYPosition, self.view.frame.size.width, 30);
    [_notGoingOutView removeFromSuperview];
    [_scrollView addSubview:_notGoingOutView];
    _notGoingOutStartingPoint = [_notGoingOutView.superview convertPoint:_notGoingOutView.frame.origin toView:nil];
    _notGoingOutIsAttachedToScrollView = YES;
    _startingYPosition += 30;
}


- (void) initializeTabBar {
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"peopleSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
}

- (void) initializeNavigationItem {
    CGRect profileFrame = CGRectMake(0, 0, 30, 30);
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]]];
    [profileButton addSubview:profileImageView];
    [profileButton addTarget:self action:@selector(myProfileSegue)
            forControlEvents:UIControlEventTouchUpInside];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.leftBarButtonItem = profileBarButton;
    
    UIButtonAligned *rightButton = [[UIButtonAligned alloc] initWithFrame: CGRectMake(0, 0, 31, 22) andType:@3];
    [rightButton setBackgroundImage:[UIImage imageNamed:@"plusPerson"] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(followPressed)
            forControlEvents:UIControlEventTouchUpInside];
    [rightButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    [self updateTitleView];
}

- (void) showTapButtons {
    if ([[Profile user] isGoingOut]) {
        for (int i = 0; i < [_tapArray count]; i++) {
            NSLog(@"i: %d", i);
            UIImageViewShake *tappedImageView = [_tapArray objectAtIndex:i];
            tappedImageView.hidden = NO;
            UIButton *tapButton = [_tapButtonArray objectAtIndex:i];
            tapButton.enabled = YES;
            
        }
    }
}

- (void)followPressed {
    self.peopleViewController = [[PeopleViewController alloc] initWithUser:[Profile user]];
    [self.navigationController pushViewController:self.peopleViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)myProfileSegue {
    self.profileViewController = [[ProfileViewController alloc] initWithProfile:YES];
    [self.navigationController pushViewController:self.profileViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)profileSegue:(id)sender {
    UIImageView* superview = (UIImageView *)[sender superview];
    int tag = superview.tag;
    User *user;

    if (tag < 0) {
        tag = -tag;
        tag -= 1;
        user = [[_notGoingOutParty getObjectArray] objectAtIndex:tag];
    }
    else {
        tag -= 1;
        user = [[_whoIsGoingOutParty getObjectArray] objectAtIndex:tag];
    }
    
    self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:self.profileViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void) updateTitleView {
    if ([[Profile user] isGoingOut]) {
        self.navigationItem.titleView = nil;
        UIButtonUngoOut *ungoOutButton = [[UIButtonUngoOut alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
        [ungoOutButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
        self.navigationItem.titleView = ungoOutButton;
    }
    else {
        UIButton *goOutButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
        [goOutButton setTitle:@"GO OUT" forState:UIControlStateNormal];
        [goOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        goOutButton.backgroundColor = [FontProperties getOrangeColor];
        goOutButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        goOutButton.titleLabel.font = [FontProperties getTitleFont];
        goOutButton.layer.borderWidth = 1;
        goOutButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
        goOutButton.layer.cornerRadius = 7;
        [goOutButton addTarget:self action:@selector(goOutPressed) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.title = @"GO OUT";
        self.navigationItem.titleView = goOutButton;
    }
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    [self.navigationItem.leftBarButtonItem setTintColor:[FontProperties getOrangeColor]];
}

- (void) goOutPressed {
    User *profileUser = [Profile user];
    [profileUser setIsGoingOut:YES];
    [Profile setUser:profileUser];
    [self updateTitleView];
    [self animationShowingTapIcons];
    [Network postGoOut];
}


- (void) selectedProfile:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = buttonSender.tag;
    UIImageView *imageView = (UIImageView *)[buttonSender superview];

    for (UIView *subview in imageView.subviews)
    {
        if (subview.tag == 1) {
            if ([subview isMemberOfClass:[UIImageViewShake class]]) {
                UIImageView *imageView = (UIImageView *)subview;
                imageView.image = [UIImage imageNamed:@"tapFilled"];
                subview.tag = -1;
            }
        }
        else if (subview.tag == -1) {
            if ([subview isMemberOfClass:[UIImageViewShake class]]) {
                UIImageView *imageView = (UIImageView *)subview;
                imageView.image = [UIImage imageNamed:@"tapUnfilled"];
                subview.tag = 1;
            }
        }
    }
    User *user;
    if (tag < 0) {
        tag = -tag;
        tag -= 1;
        user = [[_notGoingOutParty getObjectArray] objectAtIndex:tag];
    }
    else {
        tag -= 1;
        user = [[_whoIsGoingOutParty getObjectArray] objectAtIndex:tag];
    }
    [Network sendTapToUserWithIndex:[user objectForKey:@"id"]];
}


- (BOOL) isUserTapped:(User *)user {
    if ([_userTappedIDArray containsObject:[user objectForKey:@"id"]]) {
        return YES;
    }
    return NO;
}


- (void)fetchedMyInfoOrPeoplesInfoOrTaps {
    _numberFetchedMyInfoAndEveryoneElse += 1;
    if (_numberFetchedMyInfoAndEveryoneElse == 3) {
        [self showTapButtons];
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
    tapLabel.text = @"TAP PEOPLE YOU WANT TO SEE OUT";
    tapLabel.textAlignment = NSTextAlignmentCenter;
    tapLabel.numberOfLines = 0;
    tapLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tapLabel.font = [FontProperties getBigButtonFont];
    tapLabel.textColor = [UIColor whiteColor];
    tapLabel.alpha = 0;
    [orangeTapImgView addSubview:tapLabel];
    
    // Center the Taps in the center.
    _tapFrameArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (UIImageViewShake *tappedImageView in _tapArray) {
        CGRect previousFrame = tappedImageView.frame;
        [_tapFrameArray addObject:[NSValue valueWithCGRect:previousFrame]];
        tappedImageView.center = CGPointMake(self.view.center.x - tappedImageView.superview.frame.origin.x + _scrollView.contentOffset.x, self.view.center.y - tappedImageView.superview.frame.origin.y + _scrollView.contentOffset.y);
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
    [UIView animateWithDuration:0.3
                     animations:^{
                         orangeTapImgView.alpha = 1.0;
                         tapLabel.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
    [UIView animateWithDuration:1.6 delay:0.4 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         orangeTapImgView.alpha = 0.5;
                         orangeTapImgView.frame = CGRectMake(self.view.center.x - 125, self.view.center.y - 125, 250, 250);
                         tapLabel.frame = CGRectMake(125 - 70, 125 - 60, 140, 120);
                     }
                     completion:^(BOOL finished) {
    [UIView animateWithDuration:0.4
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
    [UIView animateWithDuration:0.3
                     animations:^{
                         for (int i = 0; i <[_tapArray count]; i++) {
                             UIImageViewShake *tappedImageView = [_tapArray objectAtIndex:i];
                             tappedImageView.hidden = NO;
                             UIButton *tapButton = [_tapButtonArray objectAtIndex:i];
                             tapButton.enabled = YES;
                             
                             CGRect previousFrame = [[_tapFrameArray objectAtIndex:i] CGRectValue];
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

#pragma mark - Refresh Control

//- (void)addRefreshToSrollView {
//    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
//    [refreshControl addTarget:self action:@selector(testRefresh:) forControlEvents:UIControlEventValueChanged];
//    [_scrollView addSubview:refreshControl];
//}
//
//- (void)testRefresh:(UIRefreshControl *)refreshControl
//{
//    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing data..."];
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    [self loadViewAfterSigningUser];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//            [formatter setDateFormat:@"MMM d, h:mm a"];
//            NSString *lastUpdate = [NSString stringWithFormat:@"Last updated on %@", [formatter stringFromDate:[NSDate date]]];
//            
//            refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdate];
//            
//            [refreshControl endRefreshing];
//        });
//    });
//}
//


@end
