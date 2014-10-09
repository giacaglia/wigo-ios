//
//  PeopleViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PeopleViewController.h"
#import "Globals.h"
#import "ProfileViewController.h"
#import "UIButtonAligned.h"
#import "UIImageCrop.h"
#import "MobileContactsViewController.h"

@interface PeopleViewController ()


//Table View of people
@property UITableView *tableViewOfPeople;

// Search Bar Content
@property Party *contentParty;
@property Party *filteredContentParty;

@property BOOL isSearching;
@property  UISearchBar *searchBar;
@property UIImageView *searchIconImageView;

@property ProfileViewController *profileViewController;

@property Party *everyoneParty;
@property Party *followingParty;
@property Party *followersParty;
@property Party *suggestionsParty;

@property NSNumber *page;
@property NSNumber *currentTab;
@end

BOOL didProfileSegue;
int userInt;
int queryQueueInt;
UIView *secondPartSubview;
BOOL fetching;

@implementation PeopleViewController

- (id)initWithUser:(User *)user andTab:(NSNumber *)tab {
    self = [super init];
    if (self) {
        self.user = user;
        _currentTab = tab;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)initWithUser:(User *)user {
    self = [super init];
    if (self) {
        self.user = user;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void)viewDidLoad
{
    queryQueueInt = 0;
    [super viewDidLoad];
    didProfileSegue = NO;
    userInt = -1;
    // Title setup
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserAtTable:) name:@"updateUserAtTable" object:nil];


    [self initializeSearchBar];
    [self initializeTableOfPeople];
}

- (void) viewWillAppear:(BOOL)animated {
    [self initializeBackBarButton];
    [self initializeRightBarButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [EventAnalytics tagEvent:@"People View"];

    if (!didProfileSegue) {
        if ([[self.user allKeys] containsObject:@"tabNumber"]) {
            _currentTab = [self.user objectForKey:@"tabNumber"];
        }
        else if (!_currentTab) _currentTab = @2;
        _contentParty = [[Party alloc] initWithObjectType:USER_TYPE];
        _filteredContentParty = [[Party alloc] initWithObjectType:USER_TYPE];
        [self loadTableView];
    }
    didProfileSegue = NO;
    userInt = -1;
}

- (void)initializeBackBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) initializeRightBarButton {
    if (![self.user isEqualToUser:[Profile user]]) {
        CGRect profileFrame = CGRectMake(0, 0, 30, 30);
        UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@3];
        profileButton.userInteractionEnabled = NO;
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        [profileImageView setImageWithURL:[NSURL URLWithString:[self.user coverImageURL]] imageArea:[self.user coverImageArea]];
        [profileButton addSubview:profileImageView];
        [profileButton setShowsTouchWhenHighlighted:YES];
        UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
        self.navigationItem.rightBarButtonItem = profileBarButton;
    }
}

- (void) goBack {
    [self updateLastUserRead];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tappedView:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)tappedView:(UITapGestureRecognizer*)tapSender {
    UIView *viewSender = (UIView *)tapSender.view;
    int tag = (int)viewSender.tag;
    User *user = [self getUserAtIndex:tag];
    if (user) {
        didProfileSegue = YES;
        userInt = tag;
        self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.profileViewController animated:YES];
    }
}

- (void)tappedButton:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    User *user = [self getUserAtIndex:tag];
    if (user) {
        didProfileSegue = YES;
        userInt = tag;
        self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.profileViewController animated:YES];
    }
}


- (void)initializeTableOfPeople {
    self.automaticallyAdjustsScrollViewInsets = NO;
    _tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 66, self.view.frame.size.width, self.view.frame.size.height - 64)];
    _tableViewOfPeople.delegate = self;
    _tableViewOfPeople.dataSource = self;
    _tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_tableViewOfPeople];
}


#pragma mark - UISearchBar 

- (void)initializeSearchBar {
    UIColor *grayColor = RGB(184, 184, 184);
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 30)];
    _searchBar.barTintColor = [UIColor whiteColor];
    _searchBar.tintColor = grayColor;
    _searchBar.placeholder = @"Search By Name";
    _searchBar.delegate = self;
    _searchBar.layer.borderWidth = 0.5f;
    _searchBar.layer.cornerRadius = 15.0f;
    _searchBar.layer.borderColor = grayColor.CGColor;
    _searchBar.hidden = YES;
    UITextField *searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:grayColor forKeyPath:@"_placeholderLabel.textColor"];
    
    // Search Icon Clear
    UITextField *txfSearchField = [_searchBar valueForKey:@"_searchField"];
    [txfSearchField setLeftViewMode:UITextFieldViewModeNever];

    // Add Custom Search Icon
    _searchIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"graySearchIcon"]];
    _searchIconImageView.frame = CGRectMake(76, 7, 14, 14);
    [_searchBar addSubview:_searchIconImageView];
    
    // Remove Clear Button on the right
    UITextField *textField = [_searchBar valueForKey:@"_searchField"];
    textField.clearButtonMode = UITextFieldViewModeNever;
    
    // Text when editing becomes orange
    for (UIView *subView in _searchBar.subviews) {
        for (UIView *secondLevelSubview in subView.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]])
            {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                searchBarTextField.textColor = grayColor;
                break;
            }
            else {
                [secondLevelSubview removeFromSuperview];
            }
        }
    }
}

- (UIView *)initializeSecondPart {
    if ([_currentTab isEqualToNumber:@2]) {
        UIView *secondPartSubview = [[UIView alloc] initWithFrame:CGRectMake(0, 59, self.view.frame.size.width, 292)];
        
        UILabel *contextLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, self.view.frame.size.width - 14, 21)];
        contextLabel.text = @"New on WiGo";
        contextLabel.font = [FontProperties mediumFont:17.0f];
        contextLabel.textAlignment = NSTextAlignmentLeft;
        [secondPartSubview addSubview:contextLabel];
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 180)];
        scrollView.showsHorizontalScrollIndicator = NO;
        [secondPartSubview addSubview:scrollView];
        int xPosition = 10;
        for (int i = 0; i < MIN(10,[[_suggestionsParty getObjectArray] count]); i++) {
            User *user = [[_suggestionsParty getObjectArray] objectAtIndex:i];
            [scrollView addSubview:[self cellOfUser:user atXPosition:xPosition]];
            xPosition += 130;
            scrollView.contentSize = CGSizeMake(xPosition + 110, 175);
        }
        
        UIButton *inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 0, 110, 110)];
        [inviteButton setBackgroundImage:[UIImage imageNamed:@"InviteButton"] forState:UIControlStateNormal];
        [inviteButton addTarget:self action:@selector(inviteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:inviteButton];
        
        UILabel *inviteMoreFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPosition, 120, 110, 30)];
        inviteMoreFriendsLabel.text = @"Invite more friends\nto WiGo";
        inviteMoreFriendsLabel.textAlignment = NSTextAlignmentCenter;
        inviteMoreFriendsLabel.font = [FontProperties mediumFont:12.0f];
        inviteMoreFriendsLabel.numberOfLines = 0;
        inviteMoreFriendsLabel.lineBreakMode = NSLineBreakByWordWrapping;
        inviteMoreFriendsLabel.textColor = [FontProperties getOrangeColor];
        [scrollView addSubview:inviteMoreFriendsLabel];
        
        xPosition += 130;
        scrollView.contentSize = CGSizeMake(xPosition + 110, 175);

        return secondPartSubview;
    }
    else {
        UIView *secondPartSubview = [[UIView alloc] initWithFrame:CGRectMake(0, 55, self.view.frame.size.width, 130)];
        
        UILabel *lateToThePartyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.view.frame.size.width - 30, 21)];
        lateToThePartyLabel.text = @"Some of your friends are late to the party";
        lateToThePartyLabel.textAlignment = NSTextAlignmentCenter;
        lateToThePartyLabel.font = [FontProperties mediumFont:16.0f];
        lateToThePartyLabel.textColor = RGB(102, 102, 102);
        [secondPartSubview addSubview:lateToThePartyLabel];
        
        UIButton *inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(45, 29, 229, 30)];
        [inviteButton addTarget:self action:@selector(inviteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        inviteButton.backgroundColor = [FontProperties getOrangeColor];
        [inviteButton setTitle:@"Invite more friends on WiGo" forState:UIControlStateNormal];
        [inviteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        inviteButton.titleLabel.font = [FontProperties scMediumFont:16.0f];
        inviteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        inviteButton.layer.borderWidth = 1.0f;
        inviteButton.layer.borderColor = [UIColor whiteColor].CGColor;
        inviteButton.layer.cornerRadius = 8.0f;
        [secondPartSubview addSubview:inviteButton];
        
        return secondPartSubview;
    }
 
}

- (void)inviteButtonPressed  {
    [self presentViewController:[MobileContactsViewController new] animated:YES completion:nil];
}

- (UIView *)cellOfUser:(User *)user atXPosition:(int)xPosition {
    UIView *cellOfUser = [[UIView alloc] initWithFrame:CGRectMake(xPosition, 0, 110, 175)];
    
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 110, 110)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
    [cellOfUser addSubview:profileImageView];
    
    UILabel *nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 110 - 25, 110, 25)];
    nameOfPersonLabel.textColor = [UIColor whiteColor];
    nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
    nameOfPersonLabel.text = [user firstName];
    nameOfPersonLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    nameOfPersonLabel.font = [FontProperties lightFont:16.0f];
    [cellOfUser addSubview:nameOfPersonLabel];
    
    if (![user isEqualToUser:[Profile user]]) {

        UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(30, 120, 49, 30)];
        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        followPersonButton.tag = -100;
        [followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cellOfUser addSubview:followPersonButton];
        if ([user getUserState] == BLOCKED_USER) {
            [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
            [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            followPersonButton.layer.borderWidth = 1;
            followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            followPersonButton.layer.cornerRadius = 3;
            followPersonButton.tag = 50;
        }
        else {
            if ([user isFollowing]) {
                [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                followPersonButton.tag = 100;
            }
            if ([user getUserState] == NOT_YET_ACCEPTED_PRIVATE_USER) {
                [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
                [followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
                [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
                followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
                followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                followPersonButton.layer.borderWidth = 1;
                followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
                followPersonButton.layer.cornerRadius = 3;
                followPersonButton.tag = 100;
            }
        }
        
        UILabel *mutualFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 152, 110, 15)];
        mutualFriendsLabel.text = @"25 mututal friends";
        mutualFriendsLabel.textAlignment = NSTextAlignmentCenter;
        mutualFriendsLabel.font = [FontProperties lightFont:12.0f];
        mutualFriendsLabel.textColor = RGB(102, 102, 102);
        [cellOfUser addSubview:mutualFriendsLabel];
        
        UILabel *dateJoined = [[UILabel alloc] initWithFrame:CGRectMake(0, 165, 110, 12)];
        dateJoined.text = [user joinedDate];
        dateJoined.textColor = RGB(201, 202, 204);
        dateJoined.textAlignment = NSTextAlignmentCenter;
        dateJoined.font = [FontProperties lightFont:10.0f];
        [cellOfUser addSubview:dateJoined];
    }
    return cellOfUser;
}


#pragma mark - Filter handlers


- (void)clearSearchBar {
    [self.view endEditing:YES];
    _isSearching = NO;
    _searchBar.text = @"";
    [self searchBarTextDidEndEditing:_searchBar];
}

- (void)loadTableView {
    if ([_currentTab isEqualToNumber:@2]) {
        [self fetchFirstPageEveryone];
        [self fetchFirstPageSuggestions];
        self.title = [[Profile user] groupName];
    }
    else if ([_currentTab isEqualToNumber:@3]) {
        [self fetchFirstPageFollowers];
        self.title = @"Followers";
    }
    else if ([_currentTab isEqualToNumber:@4]) {
        [self fetchFirstPageFollowing];
        self.title = @"Following";
    }
    _tableViewOfPeople.contentOffset = CGPointMake(0, 40);
}


#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_currentTab isEqualToNumber:@2]) {
        if ([indexPath row] == 0) return 320;
    }
    else if ([_currentTab isEqualToNumber:@4]) {
        if ([indexPath row] == 0) return 135;
    }
    else {
        if ([indexPath row] == 0) return 40;
    }
    return PEOPLEVIEW_HEIGHT_OF_CELLS + 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRowsWithNoShare];
}

- (int)numberOfRowsWithNoShare {
    if (_isSearching) {
        return (int)[[_filteredContentParty getObjectArray] count];
    }
    else {
        int hasNextPage = ([_contentParty hasNextPage] ? 1 : 0);
        return (int)[[_contentParty getObjectArray] count] + hasNextPage;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
    if ([indexPath row] == 0) {
        _searchBar.hidden = NO;
        [cell.contentView addSubview:_searchBar];
        if ([_currentTab isEqualToNumber:@2]) {
            [cell.contentView addSubview:secondPartSubview];
        }
        else if ([_currentTab isEqualToNumber:@4]) {
            [cell.contentView addSubview:secondPartSubview];
        }
        return cell;

    }
    int tag = (int)[indexPath row] - 1;
    
    if ([[_contentParty getObjectArray] count] == 0) return cell;
    if ([[_contentParty getObjectArray] count] > 5) {
        if ([_contentParty hasNextPage] && tag == [[_contentParty getObjectArray] count] - 5) {
            [self loadNextPage];
        }
    }
    else {
        if (tag == [[_contentParty getObjectArray] count]) {
            [self loadNextPage];
            return cell;
        }
    }
   
    User *user = [self getUserAtIndex:tag];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
    UIView *clickableView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 15 - 79, PEOPLEVIEW_HEIGHT_OF_CELLS - 5)];
    if (![user isEqualToUser:[Profile user]]) [clickableView addGestureRecognizer:tap];
    clickableView.userInteractionEnabled = YES;
    clickableView.tag = tag;
    [cell.contentView addSubview:clickableView];
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 30, 60, 60)];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
    [profileButton addSubview:profileImageView];
    profileButton.tag = tag;
    if (![user isEqualToUser:[Profile user]]) {
        [profileButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    [cell.contentView addSubview:profileButton];
    
    if ([user isFavorite]) {
        UIImageView *favoriteSmall = [[UIImageView alloc] initWithFrame:CGRectMake(6, profileButton.frame.size.height - 16, 10, 10)];
        favoriteSmall.image = [UIImage imageNamed:@"favoriteSmall"];
        [profileButton addSubview:favoriteSmall];
    }
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    labelName.font = [FontProperties mediumFont:18.0f];
    labelName.text = [user fullName];
    labelName.textAlignment = NSTextAlignmentLeft;
    labelName.userInteractionEnabled = YES;
    [clickableView addSubview:labelName];
    
    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 45, 150, 20)];
    goingOutLabel.font =  [FontProperties mediumFont:15.0f];
    goingOutLabel.textAlignment = NSTextAlignmentLeft;
    if ([user isGoingOut]) {
        goingOutLabel.text = @"Going Out";
        goingOutLabel.textColor = [FontProperties getOrangeColor];
    }
    [clickableView addSubview:goingOutLabel];
    
    if ([_currentTab isEqualToNumber:@2]) {
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140 - 15, PEOPLEVIEW_HEIGHT_OF_CELLS - 15, 140, 12)];
        timeLabel.text = [user joinedDate];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.font = [FontProperties getSmallPhotoFont];
        timeLabel.textColor = RGB(201, 202, 204);
        [cell.contentView addSubview:timeLabel];
    }
    
    if (![user isEqualToUser:[Profile user]]) {
        UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 15, 49, 30)];
        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        followPersonButton.tag = -100;
        [followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:followPersonButton];
        if ([user getUserState] == BLOCKED_USER) {
            [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
            [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            followPersonButton.layer.borderWidth = 1;
            followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            followPersonButton.layer.cornerRadius = 3;
            followPersonButton.tag = 50;
        }
        else {
            if ([user isFollowing]) {
                [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                followPersonButton.tag = 100;
            }
            if ([user getUserState] == NOT_YET_ACCEPTED_PRIVATE_USER) {
                [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
                [followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
                [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
                followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
                followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                followPersonButton.layer.borderWidth = 1;
                followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
                followPersonButton.layer.cornerRadius = 3;
                followPersonButton.tag = 100;
            }
        }
    }
    if ([(NSNumber *)[user objectForKey:@"id"] intValue] > [(NSNumber *)[[Profile user] lastUserRead] intValue]) {
        cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    }
    
    return cell;
}

//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 50)];
//    [label setFont:[UIFont boldSystemFontOfSize:12]];
//    NSString *string = @"lala";
//    [label setText:string];
//    [view addSubview:label];
//    [view setBackgroundColor:[UIColor blackColor]];
//    return view;
//}

- (void)loadNextPage {
    if ([_currentTab isEqualToNumber:@2]) {
        [self fetchEveryone];
    }
    else if ([_currentTab isEqualToNumber:@3]) {
        [self fetchFollowers];
    }
    else if ([_currentTab isEqualToNumber:@4]) {
        [self fetchFollowing];
    }
}


- (void) followedPersonPressed:(id)sender {
    //Get Index Path
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:_tableViewOfPeople];
    NSIndexPath *indexPath = [_tableViewOfPeople indexPathForRowAtPoint:buttonOriginInTableView];
    User *user = [self getUserAtIndex:(int)[indexPath row]];
    if (user) {
        UIButton *senderButton = (UIButton*)sender;
        if (senderButton.tag == 50) {
            [senderButton setTitle:nil forState:UIControlStateNormal];
            [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
            senderButton.tag = -100;
            [user setIsBlocked:NO];
            
            NSString *queryString = [NSString stringWithFormat:@"users/%@", [user objectForKey:@"id"]];
            NSDictionary *options = @{@"is_blocked": @NO};
            [Network sendAsynchronousHTTPMethod:POST
                                    withAPIName:queryString
                                    withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                                    withOptions:options];
        }
        else if (senderButton.tag == -100) {
            int num_following = [(NSNumber*)[self.user objectForKey:@"num_following"] intValue];
            
            if ([user isPrivate]) {
                [senderButton setBackgroundImage:nil forState:UIControlStateNormal];
                [senderButton setTitle:@"Pending" forState:UIControlStateNormal];
                [senderButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
                senderButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
                senderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                senderButton.layer.borderWidth = 1;
                senderButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
                senderButton.layer.cornerRadius = 3;
                [user setIsFollowingRequested:YES];
            }
            else {
                [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                [_followingParty addObject:user];
                num_following += 1;
                [user setIsFollowing:YES];
            }
            senderButton.tag = 100;
            [self updateFollowingUIAndCachedData:num_following];
            [Network followUser:user];
        }
        else {
            [senderButton setTitle:nil forState:UIControlStateNormal];
            [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
            senderButton.tag = -100;
            int num_following = [(NSNumber*)[self.user objectForKey:@"num_following"] intValue];
            [user setIsFollowing:NO];
            [user setIsFollowingRequested:NO];
            if (![user isPrivate] && user) {
                [_followingParty removeUser:user];
                num_following -= 1;
            }
            [self updateFollowingUIAndCachedData:num_following];
            [Network unfollowUser:user];
        }
        if ([indexPath row] < [[_contentParty getObjectArray] count]) {
            [_contentParty replaceObjectAtIndex:[indexPath row] withObject:user];
        }
    }
}

- (void) updateFollowingUIAndCachedData:(int)num_following {
    User *profileUser = [Profile user];
    if (profileUser == self.user) {
        [profileUser setObject:[NSNumber numberWithInt:num_following] forKey:@"num_following"];
        [Profile setFollowingParty:_followingParty];
    }
}

- (User *)getUserAtIndex:(int)index {
    User *user;
    if (_isSearching) {
        int sizeOfArray = (int)[[_filteredContentParty getObjectArray] count];
        if (sizeOfArray > 0 && sizeOfArray > index)
            user = [[_filteredContentParty getObjectArray] objectAtIndex:index];
    }
    else {
        int sizeOfArray = (int)[[_contentParty getObjectArray] count];
        if (sizeOfArray > 0 && sizeOfArray > index)
            user = [[_contentParty getObjectArray] objectAtIndex:index];
    }
    return user;
}

#pragma mark - Last User Read 
- (void)updateLastUserRead {
    User *profileUser = [Profile user];
    for (User *user in [_everyoneParty getObjectArray]) {
        if ([(NSNumber *)[user objectForKey:@"id"] intValue] > [(NSNumber *)[profileUser lastUserRead] intValue]) {
            [profileUser setLastUserRead:[user objectForKey:@"id"]];
            [profileUser saveKeyAsynchronously:@"last_user_read"];
        }
    }
}

#pragma mark - Update User Info
- (void)updateUserAtTable:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    User *user = [[User alloc] initWithDictionary:userInfo];
    if (user) {
        if (_isSearching) {
            int numberOfRows = (int)[_tableViewOfPeople numberOfRowsInSection:0];
            int sizeOfArray = (int)[[_filteredContentParty getObjectArray] count];
            if (numberOfRows > 0 && numberOfRows > userInt && userInt >= 0 && sizeOfArray > userInt) {
                [_filteredContentParty replaceObjectAtIndex:userInt withObject:user];
                [_tableViewOfPeople beginUpdates];
                [_tableViewOfPeople reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:userInt inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [_tableViewOfPeople endUpdates];
            }
            
        }
        else {
            int numberOfRows = (int)[_tableViewOfPeople numberOfRowsInSection:0];
            int sizeOfArray = (int)[[_contentParty getObjectArray] count];
            if (numberOfRows > 0 && numberOfRows > userInt  && userInt >= 0 && sizeOfArray > userInt) {
                [_contentParty replaceObjectAtIndex:userInt withObject:user];
                [_tableViewOfPeople beginUpdates];
                [_tableViewOfPeople reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:userInt inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [_tableViewOfPeople endUpdates];
            }
        }

    }
}

#pragma mark - Network functions

- (void)fetchFirstPageSuggestions {
    _suggestionsParty = [[Party alloc] initWithObjectType:USER_TYPE];
    [Network queryAsynchronousAPI:@"users/suggestions/" withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
            [_suggestionsParty addObjectsFromArray:arrayOfUsers];
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_suggestionsParty addMetaInfo:metaDictionary];
            secondPartSubview = [self initializeSecondPart];
            if ([_tableViewOfPeople numberOfRowsInSection:0] > 0) {
                [_tableViewOfPeople beginUpdates];
                [_tableViewOfPeople reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                [_tableViewOfPeople endUpdates];
            }
        });
    }];
}

- (void)fetchFirstPageEveryone {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    _page = @1;
    _everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    [self fetchEveryone];
}

- (void) fetchEveryone {
    if (!fetching) {
        fetching = YES;
        NSString *queryString = [NSString stringWithFormat:@"users/?ordering=-id&page=%@" ,[_page stringValue]];
        [Network queryAsynchronousAPI:queryString withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                fetching = NO;
                [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
                [_everyoneParty addObjectsFromArray:arrayOfUsers];
                NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
                [_everyoneParty addMetaInfo:metaDictionary];
                _page = @([_page intValue] + 1);
                _contentParty = _everyoneParty;
                [_tableViewOfPeople reloadData];
                secondPartSubview = [self initializeSecondPart];
            });
        }];
    }
}

- (void)fetchFirstPageFollowers {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    _page = @1;
    _followersParty = [[Party alloc] initWithObjectType:USER_TYPE];
    [self fetchFollowers];
}

- (void)fetchFollowers {
    if (!fetching) {
        fetching = YES;
        NSString *queryString = [NSString stringWithFormat:@"follows/?follow=%d&ordering=-id&page=%@", [[self.user objectForKey:@"id"] intValue], [_page stringValue]];
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                fetching = NO;
                [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
                NSMutableArray *arrayOfUsers = [[NSMutableArray alloc] initWithCapacity:[arrayOfFollowObjects count]];
                for (NSDictionary *object in arrayOfFollowObjects) {
                    NSDictionary *userDictionary = [object objectForKey:@"user"];
                    if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                        if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                            [arrayOfUsers addObject:[[Profile user] dictionary]];
                        }
                        else {
                            [arrayOfUsers addObject:userDictionary];
                        }
                    }
                }
                [_followersParty addObjectsFromArray:arrayOfUsers];
                NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
                [_followersParty addMetaInfo:metaDictionary];
                _page = @([_page intValue] + 1);
                _contentParty = _followersParty;
                [_tableViewOfPeople reloadData];
            });
        }];
    }
}

- (void)fetchFirstPageFollowing {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    _page = @1;
    _followingParty = [[Party alloc] initWithObjectType:USER_TYPE];
    [self fetchFollowing];
}

- (void)fetchFollowing {
    if (!fetching) {
        fetching = YES;
        NSString *queryString = [NSString stringWithFormat:@"follows/?user=%d&ordering=-id&page=%@", [[self.user objectForKey:@"id"] intValue], [_page stringValue]];
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                fetching = NO;
                [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
                NSMutableArray *arrayOfUsers = [[NSMutableArray alloc] initWithCapacity:[arrayOfFollowObjects count]];
                for (NSDictionary *object in arrayOfFollowObjects) {
                    NSDictionary *userDictionary = [object objectForKey:@"follow"];
                    if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                        if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                            [arrayOfUsers addObject:[[Profile user] dictionary]];
                        }
                        else {
                            [arrayOfUsers addObject:userDictionary];
                        }
                    }
                }
                [_followingParty addObjectsFromArray:arrayOfUsers];
                NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
                [_followingParty addMetaInfo:metaDictionary];
                _page = @([_page intValue] + 1);
                _contentParty = _followingParty;
                [_tableViewOfPeople reloadData];
                secondPartSubview = [self initializeSecondPart];
            });
        }];
    }

    
}



#pragma mark - UISearchBarDelegate 

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    _searchIconImageView.hidden = YES;
    _isSearching = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (![searchBar.text isEqualToString:@""]) {
        [UIView animateWithDuration:0.01 animations:^{
            _searchIconImageView.transform = CGAffineTransformMakeTranslation(-62,0);
        }  completion:^(BOOL finished){
            _searchIconImageView.hidden = NO;
        }];
    }
    else {
        [UIView animateWithDuration:0.01 animations:^{
            _searchIconImageView.transform = CGAffineTransformMakeTranslation(0,0);
        }  completion:^(BOOL finished){
            _searchIconImageView.hidden = NO;
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [_filteredContentParty removeAllObjects];
    
    if([searchText length] != 0) {
        _isSearching = YES;
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.25
     cancelPreviousRequest:YES];
    }
    else {
        _isSearching = NO;
    }
    [_tableViewOfPeople reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performBlock:^(void){[self searchTableList];}
            afterDelay:0.25
 cancelPreviousRequest:YES];
}


- (void)searchTableList {
    NSString *oldString = _searchBar.text;
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    _page = @1;
    if ([_currentTab isEqualToNumber:@2]) {
        NSString *queryString = [NSString stringWithFormat:@"users/?page=%@&text=%@" ,[_page stringValue], searchString];
        [self searchUsersWithString:queryString andObjectType:USER_TYPE];
    }
    else if ([_currentTab isEqualToNumber:@3]) {
        NSString *queryString = [NSString stringWithFormat:@"follows/?follow=%d&page=%@&text=%@" ,[[self.user objectForKey:@"id"] intValue], [_page stringValue], searchString];
        [self searchUsersWithString:queryString andObjectType:FOLLOW_TYPE];
    }
    else {
        NSString *queryString = [NSString stringWithFormat:@"follows/?user=%d&page=%@&text=%@", [[self.user objectForKey:@"id"] intValue], [_page stringValue], searchString];
        [self searchUsersWithString:queryString andObjectType:FOLLOW_TYPE];
    }
}

- (void)searchUsersWithString:(NSString *)queryString andObjectType:(OBJECT_TYPE)type {
    queryQueueInt += 1;
    NSDictionary *inputDictionary = @{@"queryInt": [NSNumber numberWithInt:queryQueueInt]};
    [Network queryAsynchronousAPI:queryString
              withInputDictionary:inputDictionary
                      withHandler: ^(NSDictionary *input, NSDictionary *jsonResponse, NSError *error) {
                          // If it's last query
                          if ([[input objectForKey:@"queryInt"] intValue] == queryQueueInt) {
                              if ([_page isEqualToNumber:@1]) _filteredContentParty = [[Party alloc] initWithObjectType:USER_TYPE];
                              NSMutableArray *arrayOfUsers;
                              if (type == FOLLOW_TYPE) {
                                  NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
                                  arrayOfUsers = [[NSMutableArray alloc] initWithCapacity:[arrayOfFollowObjects count]];
                                  for (NSDictionary *object in arrayOfFollowObjects) {
                                      NSDictionary *userDictionary;
                                      if ([_currentTab isEqualToNumber:@3]) userDictionary = [object objectForKey:@"user"];
                                      else userDictionary = [object objectForKey:@"follow"];
                                      if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                                          if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                                              [arrayOfUsers addObject:[[Profile user] dictionary]];
                                          }
                                          else {
                                              [arrayOfUsers addObject:userDictionary];
                                          }
                                      }
                                  }
                              }
                              else {
                                  arrayOfUsers = [jsonResponse objectForKey:@"objects"];
                              }
                              
                              [_filteredContentParty addObjectsFromArray:arrayOfUsers];
                              NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
                              [_filteredContentParty addMetaInfo:metaDictionary];
                              dispatch_async(dispatch_get_main_queue(), ^(void) {
                                  _page = @([_page intValue] + 1);
                                  [_tableViewOfPeople reloadData];
                              });
                          }
       
    }];
}

- (void)reloadTableExceptFirstRow {
    NSMutableArray *allIndexes = [[NSMutableArray alloc] init];
    for (int i = 1; i < [_tableViewOfPeople numberOfRowsInSection:0]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [allIndexes addObject:indexPath];
    }
    [_tableViewOfPeople beginUpdates];
    [_tableViewOfPeople reloadRowsAtIndexPaths:[NSArray arrayWithArray:allIndexes] withRowAnimation:UITableViewRowAnimationNone];
    [_tableViewOfPeople endUpdates];
}



@end
