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

#import "SDWebImage/UIImageView+WebCache.h"
#import "WiGoSpinnerView.h"

static NSString * const cellIdentifier = @"ContentViewCell";
static NSString * const headerCellIdentifier = @"HeaderContentCell";

@interface MainViewController ()

// Properties shared by Who and Where View
@property BOOL isGoingOut;


// Tap Array (First object tag is 2)
@property NSMutableArray *tapArray;
@property NSMutableArray *userTapArray;
@property NSMutableArray *tapButtonArray;
@property int indexOfImage;
@property NSMutableArray *tapFrameArray;

// Bar at top
@property UIView *barAtTopView;
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
@property Party *followingAcceptedParty;
@property Party *whoIsGoingOutParty;
@property Party *notGoingOutParty;

@property NSNumber *page;
@property UILabel *goingOutLabel;
@property UILabel *goingOutLabelOnTopOfNotGoingOutLabel;
@property UILabel *notGoingOutLabel;
@property BOOL started;
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
    [self initializeWhoView];
    [self initializeNotificationObservers];
}

- (void)loadViewAfterSigningUser {
    _started = NO;
    _numberFetchedMyInfoAndEveryoneElse = 0;
    _followingAcceptedParty = [[Party alloc] initWithObjectName:@"User"];
    _whoIsGoingOutParty = [[Party alloc] initWithObjectName:@"User"];
    _notGoingOutParty = [[Party alloc] initWithObjectName:@"User"];
    
    _page = @1;
    
    [self fetchUserInfo];
    [self fetchFollowers];
}

#pragma mark - Fetch Data

- (void) fetchUserInfo {
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        User *user = [[User alloc] initWithDictionary:jsonResponse];
        User *profileUser = [Profile user];
        [profileUser setIsGoingOut:[user isGoingOut]];
        [Profile setUser:profileUser];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateTitleView];
            [self fetchedMyInfoOrPeoplesInfo];
        });
    }];
}

- (void)fetchFollowers {
    NSString *queryString = [NSString stringWithFormat:@"users/?user=friends&ordering=goingout&page=%@", [_page stringValue]];
    [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [WiGoSpinnerView hideSpinnerForView:self.view];
            _page = @([_page intValue] + 1);
            [_collectionView reloadData];
            [self fetchedMyInfoOrPeoplesInfo];
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

- (void)initializeWhoView {
    [self initializeBarAtTopWithText:@"GOING OUT"];
    [self initializeNotGoingOutBar];
//    _startingYPosition -= 64;
    _tapArray = [[NSMutableArray alloc] initWithCapacity:0];
    _userTapArray = [[NSMutableArray alloc] initWithCapacity:0];
    _tapButtonArray = [[NSMutableArray alloc] initWithCapacity:0];
   
    [self initializeCollectionView];
    
}

- (void) initializeBarAtTopWithText:(NSString *)textAtTop {
    if (!_barAtTopView) {
        _barAtTopView = [[UIView alloc] init];
        _barAtTopView.backgroundColor = RGBAlpha(255, 255, 255, 0.95f);
        UILabel *barAtTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 15)];
        barAtTopLabel.text = textAtTop;
        barAtTopLabel.textAlignment = NSTextAlignmentLeft;
        barAtTopLabel.font = [UIFont fontWithName:@"Whitney-LightSC" size:15.0];
        [_barAtTopView addSubview:barAtTopLabel];
    }
    
    _barAtTopView.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    [_barAtTopView removeFromSuperview];
     [self.view addSubview:_barAtTopView];
    _barAtTopPoint = _barAtTopView.frame.origin;
    _goingOutIsAttachedToScrollView = NO;
}

- (void) initializeNotGoingOutBar {
    if (!_notGoingOutView) {
        _notGoingOutView = [[UIView alloc] init];
        _notGoingOutView.backgroundColor = [UIColor whiteColor];
        [self.view bringSubviewToFront:_notGoingOutView];
        
        UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 15)];
        goingOutLabel.text = @"NOT GOING OUT YET";
        goingOutLabel.textAlignment = NSTextAlignmentLeft;
        goingOutLabel.font = [UIFont fontWithName:@"Whitney-LightSC" size:15.0];
        [_notGoingOutView addSubview:goingOutLabel];
    }
    
//    _notGoingOutView.frame = CGRectMake(0, _startingYPosition, self.view.frame.size.width, 30);
//    [_notGoingOutView removeFromSuperview];
//    [_collectionView addSubview:_notGoingOutView];
//    _notGoingOutStartingPoint = _notGoingOutView.frame.origin;
    _notGoingOutIsAttachedToScrollView = YES;
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
            UIImageViewShake *tappedImageView = [_tapArray objectAtIndex:i];
            tappedImageView.hidden = NO;
            UIButton *tapButton = [_tapButtonArray objectAtIndex:i];
            tapButton.enabled = YES;
            
            User *user = [_userTapArray objectAtIndex:i];
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
    [self showTapButtons];
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
                [self sendTapToUserWithTag:tag];
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

}

- (void) sendTapToUserWithTag:(int)tag {
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
    if (![user isTapped]) {
        [Network sendTapToUserWithIndex:[user objectForKey:@"id"]];
    }
}

- (void)fetchedMyInfoOrPeoplesInfo {
    _numberFetchedMyInfoAndEveryoneElse += 1;
    if (_numberFetchedMyInfoAndEveryoneElse == 2) {
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
        tappedImageView.center = self.view.center;
//        tappedImageView.center = CGPointMake(self.view.center.x - tappedImageView.superview.frame.origin.x + _scrollView.contentOffset.x, self.view.center.y - tappedImageView.superview.frame.origin.y + _scrollView.contentOffset.y);
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

- (void)addRefreshToCollectonView {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshPeople:) forControlEvents:UIControlEventValueChanged];
    [_collectionView addSubview:refreshControl];
}

- (void)refreshPeople:(UIRefreshControl *)refreshControl
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [refreshControl endRefreshing];
        });
    });
}

#pragma mark - Collection view Data Source

- (void) initializeCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 4;
    layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, 30);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49) collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerCellIdentifier];
    _collectionView.backgroundColor = [UIColor clearColor];
    [self addRefreshToCollectonView];
    [self.view addSubview:_collectionView];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    int hasNextPage = ([_followingAcceptedParty hasNextPage] ? 1 : 0);
    return 2 + hasNextPage;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) {
        return [[_whoIsGoingOutParty getObjectArray] count];
    }
    else if (section == 1) {
        return [[_notGoingOutParty getObjectArray] count];
    }
    else {
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];

    NSArray *userArray;
    if ([indexPath section] == 0) {
         userArray = [_whoIsGoingOutParty getObjectArray];
    }
    else if ([indexPath section] == 1) {
        userArray = [_notGoingOutParty getObjectArray];
    }
    else {
        [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self fetchFollowers];
        return cell;
    }
  
    int tag = _indexOfImage;
    if (_indexOfImage > 0 ) {
        _indexOfImage += 1;
    }
    else {
        _indexOfImage -= 1;
    }
    User *user = [userArray objectAtIndex:[indexPath row]];
    UIImageView *imgView = [[UIImageView alloc] init];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.clipsToBounds = YES;
    [imgView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    imgView.frame = CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height);
    imgView.userInteractionEnabled = YES;
    imgView.alpha = 1.0;
    imgView.tag = tag;
    [cell.contentView addSubview:imgView];
    
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
    profileName.frame = CGRectMake(0, cell.contentView.frame.size.width - 25, cell.contentView.frame.size.width, 25);
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
    tappedImageView.hidden = YES;
    [imgView addSubview:tappedImageView];
    
    [_userTapArray addObject:user];
    [_tapArray addObject:tappedImageView];
    
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

#pragma mark - Header for UICollectionView

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
        if ([indexPath section] == 0) {
            _goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width, 30)];
            _goingOutLabel.text = @"GOING OUT";
            _goingOutLabel.font = [UIFont fontWithName:@"Whitney-LightSC" size:15.0];
            [reusableView addSubview:_goingOutLabel];
        }
        else if ([indexPath section] == 1) {
            _goingOutLabelOnTopOfNotGoingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width, 30)];
            _goingOutLabelOnTopOfNotGoingOutLabel.text = @"GOING OUT";
            _goingOutLabelOnTopOfNotGoingOutLabel.font = [UIFont fontWithName:@"Whitney-LightSC" size:15.0];
            _goingOutLabelOnTopOfNotGoingOutLabel.hidden = YES;
            [reusableView addSubview:_goingOutLabelOnTopOfNotGoingOutLabel];
            
            _notGoingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, self.view.frame.size.width, 30)];
            _notGoingOutLabel.text = @"NOT GOING OUT YET";
            _notGoingOutLabel.font = [UIFont fontWithName:@"Whitney-LightSC" size:15.0];
            [reusableView addSubview:_notGoingOutLabel];
            _notGoingOutView.frame = CGRectMake(reusableView.frame.origin.x, reusableView.frame.origin.y + 30, reusableView.frame.size.width, reusableView.frame.size.height);
            _notGoingOutStartingPoint = _notGoingOutView.frame.origin;

        }
        return reusableView;
    }
    return reusableView;
}


- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint notGoingOutPoint = [_notGoingOutView.superview convertPoint:_notGoingOutView.frame.origin toView:nil];
    NSLog(@"not going out point: %fson" , notGoingOutPoint.y);
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
            NSLog(@"allala");
            _goingOutLabelOnTopOfNotGoingOutLabel.hidden = NO;
            [_barAtTopView removeFromSuperview];
            _barAtTopView.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
            [_collectionView addSubview:_barAtTopView];
            _goingOutIsAttachedToScrollView = YES;
        }
        if ( _collectionView.contentOffset.y < 0) {
            NSLog(@"jere");
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



@end
