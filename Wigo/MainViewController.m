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
@property BOOL fetchinfUserInfo;

@end

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
    if (!_fetchingFirstPage) [self fetchFirstPageFollowing];
    if (!_fetchinfUserInfo) [self fetchUserInfo];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

- (void)loadViewAfterSigningUser {
    _fetchingFirstPage = NO;
    _fetchinfUserInfo = NO;
    _numberFetchedMyInfoAndEveryoneElse = 0;
    [self fetchFirstPageFollowing];
    [self fetchUserInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadColorWhenTabBarIsMessage" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTabBarNotifications" object:nil];
}

#pragma mark - Network function

- (void) fetchUserInfo {
    _fetchinfUserInfo = YES;
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        User *user = [[User alloc] initWithDictionary:jsonResponse];
        User *profileUser = [Profile user];
        [profileUser setIsGoingOut:[user isGoingOut]];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            _fetchinfUserInfo = NO;
            [self updateTitleView];
            [self fetchedMyInfoOrPeoplesInfo];
        });
    }];
}

- (void)fetchFirstPageFollowing {
    _fetchingFirstPage = YES;
    _isFirstTimeNotGoingOutIsAttachedToScrollView = YES;
    _page = @1;
    [self fetchFollowing];
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
    Party *everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    [Network queryAsynchronousAPI:@"users/?ordering=-id&limit=1" withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
        [everyoneParty addObjectsFromArray:arrayOfUsers];
        [Profile setEveryoneParty:everyoneParty];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
//            _contentParty = _everyoneParty;
//            [_tableViewOfPeople reloadData];
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
}

- (void)scrollUp {
    [_collectionView setContentOffset:CGPointZero animated:YES];
}

- (void) updateViewNotGoingOut {
    [self updateTitleView];
    
    for (int i = 0; i < [[_whoIsGoingOutParty getObjectArray] count]; i++) {
        User *user = [self getUserForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        UIImageViewShake *tappedImageView = [user objectForKey:@"tappedImageView"];
        tappedImageView.hidden = YES;
        UIButton *tapButton = [user objectForKey:@"tapButton"];
        tapButton.enabled = NO;
    }
    
    for (int i = 0; i < [[_notGoingOutParty getObjectArray] count]; i++) {
        User *user = [self getUserForIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
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
    [self initializeSeeSchoolButton];
}

- (void) initializeBarAtTopWithText:(NSString *)textAtTop {
    if (!_barAtTopView) {
        _barAtTopView = [[UIView alloc] init];
        _barAtTopView.backgroundColor = RGBAlpha(255, 255, 255, 0.95f);
        UILabel *barAtTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 15)];
        barAtTopLabel.text = textAtTop;
        barAtTopLabel.textAlignment = NSTextAlignmentLeft;
        barAtTopLabel.font = [FontProperties scLightFont:15.0f];
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

- (void)initializeSeeSchoolButton {
    UIButton *seeSchoolButton = [[UIButton alloc] initWithFrame:CGRectMake(25, 64 + self.view.frame.size.width + 20, self.view.frame.size.width - 50, 50)];
    [seeSchoolButton addTarget:self action:@selector(followPressed) forControlEvents:UIControlEventTouchUpInside];
    [seeSchoolButton setTitle:[NSString stringWithFormat:@"See school (%d)", 100] forState:UIControlStateNormal];
    [seeSchoolButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    seeSchoolButton.layer.cornerRadius = 15;
    seeSchoolButton.layer.borderWidth = 1;
    seeSchoolButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
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
    [profileImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]]];
    [profileButton addSubview:profileImageView];
    [profileButton addTarget:self action:@selector(myProfileSegue)
            forControlEvents:UIControlEventTouchUpInside];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.leftBarButtonItem = profileBarButton;
    
    UIButtonAligned *rightButton = [[UIButtonAligned alloc] initWithFrame: CGRectMake(0, 0, 30, 30) andType:@3];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"glowing" withExtension:@"gif"];
    FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30, 30)];
    imageView.animatedImage = image;
    [rightButton addSubview:imageView];
    [rightButton addTarget:self action:@selector(followPressed)
          forControlEvents:UIControlEventTouchUpInside];
    [rightButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    [self updateTitleView];
}

- (void) showTapButtons {
    if ([[Profile user] isGoingOut]) {
        
        for (int i = 0; i < [[_whoIsGoingOutParty getObjectArray] count]; i++) {
            User *user = [self getUserForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
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
            User *user = [self getUserForIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
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

- (User *)getUserForIndexPath:(NSIndexPath *)indexPath {
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
    int tag = (int)superview.tag;
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
    User *profileUser = [Profile user];
    [profileUser setIsGoingOut:YES];
    [self updateTitleView];
    [self showTapButtons];
    [self animationShowingTapIcons];
    [Network postGoOut];
}


- (void) selectedProfile:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    UIImageView *imageView = (UIImageView *)[buttonSender superview];
    
    for (UIView *subview in imageView.subviews)
    {
        if (subview.tag == 1) {
            if ([subview isMemberOfClass:[UIImageViewShake class]]) {
                UIImageViewShake *imageView = (UIImageViewShake *)subview;
                [imageView newShake];
                imageView.image = [UIImage imageNamed:@"tapFilled"];
                subview.tag = -1;
                [self sendTapToUserAtIndex:tag];
            }
        }
        else if (subview.tag == -1) {
            if ([subview isMemberOfClass:[UIImageViewShake class]]) {
                UIImageView *imageView = (UIImageView *)subview;
                imageView.image = [UIImage imageNamed:@"tapUnfilled"];
                subview.tag = 1;
                [self updateUserAtIndex:tag];
            }
        }
    }
}

- (void) sendTapToUserAtIndex:(int)tag {
    [EventAnalytics tagEvent:@"Tap User"];

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
    }];
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
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:collectionViewCellIdentifier];
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
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:collectionViewCellIdentifier forIndexPath:indexPath];
    cell.contentView.hidden = YES;
    if (cell == nil) {
        cell = [[UICollectionViewCell alloc] init];
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.contentView.backgroundColor = [UIColor whiteColor];

    NSArray *userArray;
    if ([indexPath section] == 0) {
        if ([[_whoIsGoingOutParty getObjectArray] count] == 0) return cell;
        userArray = [_whoIsGoingOutParty getObjectArray];
    }
    else if ([indexPath section] == 1) {
        if ([[_notGoingOutParty getObjectArray] count] == 0) return cell;
        userArray = [_notGoingOutParty getObjectArray];
    }
    else {
        [self fetchFollowing];
        return cell;
    }
    
    int tag;
    if ([indexPath section] == 0) {
        tag = (int)[indexPath row];
        tag += 1;
    }
    else {
        tag = - (int)[indexPath row];
        tag -= 1;
    }
    if ([userArray count] == 0) return cell;
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
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, imgView.frame.size.width, imgView.frame.size.height)];
    [profileButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [imgView bringSubviewToFront:profileButton];
    [imgView addSubview:profileButton];
    
    UILabel *profileName = [[UILabel alloc] init];
    profileName.text = [user firstName];
    profileName.textColor = [UIColor whiteColor];
    profileName.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
    profileName.textAlignment = NSTextAlignmentCenter;
    profileName.frame = CGRectMake(0, cell.contentView.frame.size.width - 25, cell.contentView.frame.size.width, 25);
    profileName.font = [FontProperties getSmallFont];
    profileName.tag = -1;
    [imgView addSubview:profileName];
    
    if ([user isFavorite]) {
        UIImageView *favoriteSmall = [[UIImageView alloc] initWithFrame:CGRectMake(6, 7, 10, 10)];
        favoriteSmall.image = [UIImage imageNamed:@"favoriteSmall"];
        [profileName addSubview:favoriteSmall];
    }
    
    UIButton *tapButton = [[UIButton alloc] initWithFrame:CGRectMake(imgView.frame.size.width/2, 0, imgView.frame.size.width/2, imgView.frame.size.height/2)];
    [tapButton addTarget:self action:@selector(selectedProfile:) forControlEvents:UIControlEventTouchUpInside];
    [imgView bringSubviewToFront:tapButton];
    [imgView addSubview:tapButton];
    tapButton.enabled = [[Profile user] isGoingOut] ? YES : NO;
    tapButton.tag = tag;
    
    UIImageViewShake *tappedImageView = [[UIImageViewShake alloc] initWithFrame:CGRectMake(imgView.frame.size.width - 30 - 5, 5, 30, 30)];
    tappedImageView.tintColor = [FontProperties getOrangeColor];
    tappedImageView.hidden = [[Profile user] isGoingOut] ? NO : YES;
    if ([user isTapped]) {
        tappedImageView.tag = -1;
        tappedImageView.image = [UIImage imageNamed:@"tapFilled"];
    }
    else {
        tappedImageView.tag = 1;
        tappedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
    }
    [imgView addSubview:tappedImageView];
    
    [user setObject:tapButton forKey:@"tapButton"];
    [user setObject:tappedImageView forKey:@"tappedImageView"];
    [self setUser:user ForIndexPath:indexPath];
    cell.contentView.hidden = NO;
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
        User *user = [self getUserForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        UIImageViewShake *tappedImageView = [user objectForKey:@"tappedImageView"];
        if (tappedImageView != nil) {
            [tapArray addObject:tappedImageView];
            UIButton *tapButton = [user objectForKey:@"tapButton"];
            [tapButtonArray addObject:tapButton];
        }
       
    }
    
    for (int i = 0; i < [[_notGoingOutParty getObjectArray] count]; i++) {
        User *user = [self getUserForIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
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
