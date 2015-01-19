//
//  PeopleViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PeopleViewController.h"
#import "Globals.h"
#import "FancyProfileViewController.h"
#import "UIButtonAligned.h"
#import "UIImageCrop.h"
#import "MobileContactsViewController.h"

@interface PeopleViewController () {
    UIView *_lineView;
}

// Search Bar Content
@property WGCollection *users;
@property WGCollection *filteredUsers;

@property BOOL isSearching;
@property UISearchBar *searchBar;
@property UIImageView *searchIconImageView;

@property FancyProfileViewController *profileViewController;

@property WGCollection *everyone;
@property WGCollection *following;
@property WGCollection *followers;
@property WGCollection *suggestions;

@property NSNumber *page;

@end

BOOL didProfileSegue;
//int userInt;
NSIndexPath *userIndex;
int queryQueueInt;
UIView *secondPartSubview;
BOOL fetching;
UIScrollView *suggestedScrollView;
NSMutableArray *suggestedArrayView;

@implementation PeopleViewController

- (id)initWithUser:(WGUser *)user andTab:(NSNumber *)tab {
    self = [super init];
    if (self) {
        self.user = user;
        self.currentTab = tab;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)initWithUser:(WGUser *)user {
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
    userIndex = [NSIndexPath indexPathForRow:-1 inSection:1];
    suggestedArrayView = [NSMutableArray new];
    // Title setup
    [self initializeBackBarButton];
    [self initializeRightBarButton];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserAtTable:) name:@"updateUserAtTable" object:nil];

    [self initializeSearchBar];
    [self initializeTableOfPeople];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"People View"];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};

    if (!didProfileSegue) {
        if (!self.currentTab) self.currentTab = @2;
        _users = [[WGCollection alloc] initWithType:[WGUser class]];
        _filteredUsers = [[WGCollection alloc] initWithType:[WGUser class]];
        [self loadTableView];
    }
    didProfileSegue = NO;
    userIndex = [NSIndexPath indexPathForRow:-1 inSection:1];
    
    _lineView= [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 1, self.view.frame.size.width, 1)];
    _lineView.backgroundColor = RGBAlpha(122, 193, 226, 0.1f);

    [self.navigationController.navigationBar addSubview: _lineView];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    [_lineView removeFromSuperview];
}

- (void)initializeBackBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
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
    if (![self.user isCurrentUser]) {
        CGRect profileFrame = CGRectMake(0, 0, 30, 30);
        UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@3];
        profileButton.userInteractionEnabled = NO;
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        [profileImageView setImageWithURL:self.user.smallCoverImageURL imageArea:[self.user smallCoverImageArea]];
        [profileButton addSubview:profileImageView];
        [profileButton setShowsTouchWhenHighlighted:YES];
        UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
        self.navigationItem.rightBarButtonItem = profileBarButton;
    } else {
        UIButtonAligned *searchButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 15, 16) andType:@2];
        [searchButton setBackgroundImage:[UIImage imageNamed:@"orangeSearchIcon"] forState:UIControlStateNormal];
        [searchButton addTarget:self action:@selector(searchPressed)
                forControlEvents:UIControlEventTouchUpInside];
        [searchButton setShowsTouchWhenHighlighted:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
    }
}

- (void)searchPressed {
    self.navigationItem.leftBarButtonItem = nil;
    _searchBar.hidden = NO;
    self.navigationItem.titleView = _searchBar;
    [_searchBar becomeFirstResponder];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.tableViewOfPeople setContentOffset:self.tableViewOfPeople.contentOffset animated:NO];
    
    UIButtonAligned *cancelButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@3];
    [cancelButton setTitle:@"Done" forState:UIControlStateNormal];
    [cancelButton addTarget:self action: @selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.textAlignment = NSTextAlignmentRight;
    cancelButton.titleLabel.font = [FontProperties getSubtitleFont];
    [cancelButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:cancelButton];
    self.navigationItem.rightBarButtonItem = barItem;
}

- (void)cancelPressed {
    [self clearSearchBar];
    [self initializeBackBarButton];
    [self initializeRightBarButton];
    [self loadTableView];
}

- (void) goBack {
    [[WGProfile currentUser] setLastUserReadToLatest:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
        }
    }];
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
    WGUser *user = [self getUserAtIndex:tag];
    if (user) {
        didProfileSegue = YES;
        userIndex = [NSIndexPath indexPathForRow:tag inSection:1];
        
        self.profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
        [self.profileViewController setStateWithUser: user];
        self.profileViewController.user = user;
        [self.navigationController pushViewController:self.profileViewController animated:YES];
    }
}

- (void)tappedButton:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGUser *user = [self getUserAtIndex:tag];
    if (user) {
        didProfileSegue = YES;
        userIndex = [NSIndexPath indexPathForRow:tag inSection:1];

        self.profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
        [self.profileViewController setStateWithUser: user];
        self.profileViewController.user = user;
        [self.navigationController pushViewController:self.profileViewController animated:YES];
    }
}


- (void)initializeTableOfPeople {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    self.tableViewOfPeople.delegate = self;
    self.tableViewOfPeople.dataSource = self;
    self.tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableViewOfPeople.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableViewOfPeople];
}


#pragma mark - UISearchBar 

- (void)initializeSearchBar {
    UIColor *grayColor = RGB(184, 184, 184);
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 30)];
    _searchBar.barTintColor = [UIColor whiteColor];
    _searchBar.tintColor = grayColor;
    _searchBar.placeholder = @"Search By Name";
    _searchBar.delegate = self;
    _searchBar.hidden = YES;
    UITextField *searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:grayColor forKeyPath:@"_placeholderLabel.textColor"];
    
    // Search Icon Clear
    UITextField *txfSearchField = [_searchBar valueForKey:@"_searchField"];
    [txfSearchField setLeftViewMode:UITextFieldViewModeNever];

    // Add Custom Search Icon
    _searchIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"graySearchIcon"]];
    _searchIconImageView.frame = CGRectMake(40, 14, 14, 14);
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
    if ([self.currentTab isEqualToNumber:@2]) {
        UIView *secondPartSubview = [[UIView alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, 223)];
        
        UILabel *contextLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 14, 21)];
        contextLabel.text = @"Suggested friends";
        contextLabel.font = [FontProperties mediumFont:17.0f];
        contextLabel.textAlignment = NSTextAlignmentLeft;
        [secondPartSubview addSubview:contextLabel];
        
        suggestedScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 180)];
        suggestedScrollView.showsHorizontalScrollIndicator = NO;
        [secondPartSubview addSubview:suggestedScrollView];
        int xPosition = 10;
        for (int i = 0; i < MIN(10,[_suggestions count]); i++) {
            WGUser *user = (WGUser *)[_suggestions objectAtIndex:i];
            UIView *cellView = [self cellOfUser:user atXPosition:xPosition];
            [suggestedScrollView addSubview:cellView];
            [suggestedArrayView addObject:cellView];
            xPosition += 130;
            suggestedScrollView.contentSize = CGSizeMake(xPosition + 110, 175);
        }
        
        UIButton *inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 0, 110, 110)];
        [inviteButton setBackgroundImage:[UIImage imageNamed:@"InviteButton"] forState:UIControlStateNormal];
        [inviteButton addTarget:self action:@selector(inviteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [suggestedScrollView addSubview:inviteButton];
        
        UILabel *inviteMoreFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPosition, 120, 110, 30)];
        inviteMoreFriendsLabel.text = @"Invite more friends\nto Wigo";
        inviteMoreFriendsLabel.textAlignment = NSTextAlignmentCenter;
        inviteMoreFriendsLabel.font = [FontProperties mediumFont:12.0f];
        inviteMoreFriendsLabel.numberOfLines = 0;
        inviteMoreFriendsLabel.lineBreakMode = NSLineBreakByWordWrapping;
        inviteMoreFriendsLabel.textColor = [FontProperties getOrangeColor];
        [suggestedScrollView addSubview:inviteMoreFriendsLabel];
        
        xPosition += 130;
        suggestedScrollView.contentSize = CGSizeMake(xPosition + 110, 175);

        UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(15, secondPartSubview.frame.size.height - 1, secondPartSubview.frame.size.width, 1)];
        line.backgroundColor = RGBAlpha(184, 184, 184, 0.3f);
        [secondPartSubview addSubview:line];

        return secondPartSubview;
    } else {
        UIView *secondPartSubview = [[UIView alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, 90)];
        
        UILabel *lateToThePartyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.view.frame.size.width - 30, 21)];
        lateToThePartyLabel.text = @"Some of your friends are late to the party";
        lateToThePartyLabel.textAlignment = NSTextAlignmentCenter;
        lateToThePartyLabel.font = [FontProperties mediumFont:16.0f];
        lateToThePartyLabel.textColor = RGB(102, 102, 102);
        [secondPartSubview addSubview:lateToThePartyLabel];
        
        UIButton *inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(45, 29, self.view.frame.size.width - 90, 30)];
        [inviteButton addTarget:self action:@selector(inviteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        inviteButton.backgroundColor = [FontProperties getOrangeColor];
        [inviteButton setTitle:@"Invite More Friends To Wigo" forState:UIControlStateNormal];
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

- (UIView *)cellOfUser:(WGUser *)user atXPosition:(int)xPosition {
    UIView *cellOfUser = [[UIView alloc] initWithFrame:CGRectMake(xPosition, 0, 110, 175)];
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 110, 110)];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 110, 110)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setCoverImageForUser:user completed:nil];
    [profileButton addSubview:profileImageView];
    profileButton.tag = (int)((xPosition - 10)/130);
    if (![user isCurrentUser]) {
        [profileButton addTarget:self action:@selector(suggestedProfileSegue:) forControlEvents:UIControlEventTouchUpInside];
    }
    [cellOfUser addSubview:profileButton];
    
    UILabel *nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 110 - 25, 110, 25)];
    nameOfPersonLabel.textColor = [UIColor whiteColor];
    nameOfPersonLabel.textAlignment = NSTextAlignmentCenter;
    nameOfPersonLabel.text = [user firstName];
    nameOfPersonLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    nameOfPersonLabel.font = [FontProperties lightFont:16.0f];
    [cellOfUser addSubview:nameOfPersonLabel];
    
    if (![user isCurrentUser]) {
        UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(30, 120, 49, 30)];
        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        followPersonButton.tag = -100;
        [followPersonButton addTarget:self action:@selector(suggestedFollowedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cellOfUser addSubview:followPersonButton];
        if ([user state] == BLOCKED_USER_STATE) {
            [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
            [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            followPersonButton.layer.borderWidth = 1;
            followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            followPersonButton.layer.cornerRadius = 3;
            followPersonButton.tag = 50;
        } else {
            if ([user.isFollowing boolValue]) {
                [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                followPersonButton.tag = 100;
            }
            if ([user state] == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
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
        
        UILabel *dateJoined = [[UILabel alloc] init];
        if ([user.id intValue] > [[WGProfile currentUser].lastUserRead intValue]) {
            UILabel *mutualFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 152, 110, 15)];
            mutualFriendsLabel.text = @"New on Wigo";
            mutualFriendsLabel.textAlignment = NSTextAlignmentCenter;
            mutualFriendsLabel.font = [FontProperties lightFont:12.0f];
            mutualFriendsLabel.textColor = RGB(102, 102, 102);
            [cellOfUser addSubview:mutualFriendsLabel];
            
            dateJoined.frame = CGRectMake(0, 165, 110, 12);
        } else {
            dateJoined.frame = CGRectMake(0, 152, 110, 12);
        }
    
        dateJoined.text = [user.created joinedString];
        dateJoined.textColor = RGB(201, 202, 204);
        dateJoined.textAlignment = NSTextAlignmentCenter;
        dateJoined.font = [FontProperties lightFont:10.0f];
        [cellOfUser addSubview:dateJoined];
    }
    return cellOfUser;
}

- (void)suggestedFollowedPersonPressed:(id)sender {
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:suggestedScrollView];
    int indexOfPerson = (buttonOriginInTableView.x - 40)/130 ;
    WGUser *user;
    int sizeOfArray = (int)[_suggestions count];
    if (sizeOfArray > 0 && sizeOfArray > indexOfPerson) {
        user = (WGUser *)[_suggestions objectAtIndex:indexOfPerson];
    }
    if (user) [self updateButton:sender withUser:user];
}

- (void)suggestedProfileSegue:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGUser *user = [self getSuggestedUser:tag];
    if (user) {
        didProfileSegue = YES;
        userIndex = [NSIndexPath indexPathForRow:tag inSection:0];
        
        self.profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
        [self.profileViewController setStateWithUser: user];
        self.profileViewController.user = user;

        [self.navigationController pushViewController:self.profileViewController animated:YES];
    }
}

- (WGUser *)getSuggestedUser:(int)tag {
    WGUser *user;
    int sizeOfArray = (int)[_suggestions count];
    if (sizeOfArray > 0 && sizeOfArray > tag)
        user = (WGUser *)[_suggestions objectAtIndex:tag];
    return user;
}


#pragma mark - Filter handlers

- (void)clearSearchBar {
    [self.view endEditing:YES];
    _isSearching = NO;
    _searchBar.text = @"";
    [self searchBarTextDidEndEditing:_searchBar];
}

- (void)loadTableView {
    self.navigationItem.titleView = nil;
    if ([self.currentTab isEqualToNumber:@2]) {
        [self fetchFirstPageSuggestions];
        self.title = [WGProfile currentUser].group.name;
    }
    else if ([self.currentTab isEqualToNumber:@3]) {
        [self fetchFirstPageFollowers];
        self.title = @"Followers";
    }
    else if ([self.currentTab isEqualToNumber:@4]) {
        [self fetchFirstPageFollowing];
        self.title = @"Following";
    }
}

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        if ([self.currentTab isEqualToNumber:@2]) return 233;
        else if ([self.currentTab isEqualToNumber:@4]) return 95;
        else if ([self.currentTab isEqualToNumber:@3]) return 0;
        // else return 0;
    }
    return PEOPLEVIEW_HEIGHT_OF_CELLS + 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (_isSearching) return 0;
        else return 1;
    }
    return [self numberOfRowsWithNoShare];
}

- (int)numberOfRowsWithNoShare {
    if (_isSearching) {
        return (int)[_filteredUsers count];
    } else {
        int hasNextPage = [self isThereANextPage] ? 1 : 0;
        return (int)[_users count] + hasNextPage;
    }
}

- (BOOL)isThereANextPage {
    if ([self.currentTab isEqual:@2]) {
        return [_users.hasNextPage boolValue];
    }
    else if ([self.currentTab isEqual:@3]) {
       return [_followers.hasNextPage boolValue];
    }
    else {
       return [_following.hasNextPage boolValue];
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
    cell.contentView.frame = CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tableView heightForRowAtIndexPath:indexPath]);
    
    if ([indexPath section] == 0) {
        if ([self.currentTab isEqualToNumber:@2])
            [cell.contentView addSubview:secondPartSubview];
        else if ([self.currentTab isEqualToNumber:@4])
            [cell.contentView addSubview:secondPartSubview];
        return cell;
    }
    
    UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(15, PEOPLEVIEW_HEIGHT_OF_CELLS + 9 - 1, cell.contentView.frame.size.width, 1)];
    line.backgroundColor = RGBAlpha(184, 184, 184, 0.3f);
    [cell.contentView addSubview:line];
    
    int tag = (int)[indexPath row];
    if (!_isSearching) {
        if ([_users count] == 0) return cell;
        if ([_users count] > 5) {
            if ([self isThereANextPage] && tag == [_users count] - 5) {
                [self loadNextPage];
            }
        } else if (tag == [_users count]) {
            [self loadNextPage];
            return cell;
        }
    }
    else {
        if ([_filteredUsers count] == 0) return cell;
        if ([_filteredUsers count] > 5) {
            if ([_filteredUsers.hasNextPage boolValue] && tag == [_filteredUsers count] - 5) {
                [self getNextPageForFilteredContent];
            }
        } else if (tag == [_filteredUsers count]) {
            [self getNextPageForFilteredContent];
            return cell;
        }
    }
    
    WGUser *user = [self getUserAtIndex:tag];
    if (!user) {
        BOOL loading = NO;
        if (_isSearching && [_filteredUsers.hasNextPage boolValue]) loading = YES;
        if (!_isSearching && [_users.hasNextPage boolValue]) loading = YES;
        if (loading) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
            spinner.center = cell.contentView.center;
            [cell.contentView addSubview:spinner];
            [spinner startAnimating];
        }
        return cell;
    }
    
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 30, self.view.frame.size.width - 15 - 79 - 15, 60)];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setCoverImageForUser:user completed:nil];
    [profileButton addSubview:profileImageView];
    profileButton.tag = tag;
    if (![user isCurrentUser]) {
        [profileButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    [cell.contentView addSubview:profileButton];
    
    if ([user.isFavorite boolValue]) {
        UIImageView *favoriteSmall = [[UIImageView alloc] initWithFrame:CGRectMake(6, profileButton.frame.size.height - 16, 10, 10)];
        favoriteSmall.image = [UIImage imageNamed:@"favoriteSmall"];
        [profileButton addSubview:favoriteSmall];
    }
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    labelName.font = [FontProperties mediumFont:18.0f];
    labelName.text = [user fullName];
    labelName.textAlignment = NSTextAlignmentLeft;
    labelName.userInteractionEnabled = YES;
    [cell.contentView addSubview:labelName];
    
    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 45, 150, 20)];
    goingOutLabel.font =  [FontProperties mediumFont:15.0f];
    goingOutLabel.textAlignment = NSTextAlignmentLeft;
    if ([user.isGoingOut boolValue]) {
        goingOutLabel.text = @"Going Out";
        goingOutLabel.textColor = [FontProperties getOrangeColor];
    }
    [cell.contentView addSubview:goingOutLabel];
    
    if ([self.currentTab isEqualToNumber:@2]) {
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140 - 15, PEOPLEVIEW_HEIGHT_OF_CELLS - 15, 140, 12)];
        timeLabel.text = [user.created joinedString];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.font = [FontProperties getSmallPhotoFont];
        timeLabel.textColor = RGB(201, 202, 204);
        [cell.contentView addSubview:timeLabel];
    }
    
    if (![user isCurrentUser]) {
        UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, PEOPLEVIEW_HEIGHT_OF_CELLS / 2 - 15, 49, 30)];
        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        followPersonButton.tag = -100;
        [followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:followPersonButton];
        if ([user state] == BLOCKED_USER_STATE) {
            [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
            [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            followPersonButton.layer.borderWidth = 1;
            followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            followPersonButton.layer.cornerRadius = 3;
            followPersonButton.tag = 50;
        } else {
            if ([user.isFollowing boolValue]) {
                [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                followPersonButton.tag = 100;
            }
            if ([user state] == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
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
    if ([self.currentTab isEqualToNumber:@2] &&
        [user.id intValue] > [[WGProfile currentUser].lastUserRead intValue]) {
        cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    }
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_searchBar endEditing:YES];
}

- (void) followedPersonPressed:(id)sender {
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.tableViewOfPeople];
    NSIndexPath *indexPath = [self.tableViewOfPeople indexPathForRowAtPoint:buttonOriginInTableView];
    WGUser *user = [self getUserAtIndex:(int)[indexPath row]];
    if (user) [self updateButton:sender withUser:user];
    if ([indexPath row] < [_users count]) {
        [_users replaceObjectAtIndex:[indexPath row] withObject:user];
    }
}

- (void)updateButton:(id)sender withUser:(WGUser *)user {
    UIButton *senderButton = (UIButton*)sender;
    if (senderButton.tag == 50) {
        [senderButton setTitle:nil forState:UIControlStateNormal];
        [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        senderButton.tag = -100;
        user.isBlocked = @NO;
        
        [[WGProfile currentUser] unblock:user withHandler:^(BOOL success, NSError *error) {
            // Do nothing
        }];
    }
    else if (senderButton.tag == -100) {
        int numFollowing = [self.user.numFollowing intValue];
        
        if (user.privacy == PRIVATE) {
            [senderButton setBackgroundImage:nil forState:UIControlStateNormal];
            [senderButton setTitle:@"Pending" forState:UIControlStateNormal];
            [senderButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            senderButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            senderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            senderButton.layer.borderWidth = 1;
            senderButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            senderButton.layer.cornerRadius = 3;
            user.isFollowingRequested = @YES;
        } else {
            [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
            [_users addObject:user];
            numFollowing += 1;
            user.isFollowing = @YES;
        }
        senderButton.tag = 100;
        [self updatedCachedProfileUser:numFollowing];
        [[WGProfile currentUser] follow:user withHandler:^(BOOL success, NSError *error) {
            // Do nothing
        }];
    } else {
        [senderButton setTitle:nil forState:UIControlStateNormal];
        [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        senderButton.tag = -100;
        int numFollowing = [self.user.numFollowing intValue];
        user.isFollowing = @NO;
        user.isFollowingRequested = @NO;
        if (user.privacy != PRIVATE && user) {
            [_users removeObject:user];
            numFollowing -= 1;
        }
        [self updatedCachedProfileUser:numFollowing];
        [[WGProfile currentUser] unfollow:user withHandler:^(BOOL success, NSError *error) {
            // Do nothing
        }];
    }
    

}

- (void) updatedCachedProfileUser:(int)numFollowing {
    if ([self.user isCurrentUser]) {
        [WGProfile currentUser].numFollowing = [NSNumber numberWithInt:numFollowing];
    }
}

- (WGUser *)getUserAtIndex:(int)index {
    WGUser *user;
    if (_isSearching) {
        int sizeOfArray = (int)[_filteredUsers count];
        if (sizeOfArray > 0 && sizeOfArray > index)
            user = (WGUser *)[_filteredUsers objectAtIndex:index];
    } else {
        int sizeOfArray = (int)[_users count];
        if (sizeOfArray > 0 && sizeOfArray > index)
            user = (WGUser *)[_users objectAtIndex:index];
    }
    return user;
}

#pragma mark - Update User Info
- (void)updateUserAtTable:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    WGUser *user = [WGUser serialize:userInfo];
    int userInt = (int)[userIndex row];

    if (user) {
        if ([userIndex section] == 0) {
            int numberOfRows = (int)[self.tableViewOfPeople numberOfRowsInSection:0];
            int sizeOfArray = (int)[_suggestions count];
            if (numberOfRows > 0 && userInt >= 0 && sizeOfArray > userInt) {
                [_suggestions replaceObjectAtIndex:userInt withObject:user];
                secondPartSubview = [self initializeSecondPart];
                [self.tableViewOfPeople beginUpdates];
                [self.tableViewOfPeople reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableViewOfPeople endUpdates];
            }
        } else {
            if (_isSearching) {
                int numberOfRows = (int)[self.tableViewOfPeople numberOfRowsInSection:1];
                int sizeOfArray = (int)[_filteredUsers count];
                if (numberOfRows > 0 && numberOfRows > userInt && userInt >= 0 && sizeOfArray > userInt) {
                    [_filteredUsers replaceObjectAtIndex:userInt withObject:user];
                    [self.tableViewOfPeople beginUpdates];
                    [self.tableViewOfPeople reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:userInt inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableViewOfPeople endUpdates];
                }
            }
            else {
                int numberOfRows = (int)[self.tableViewOfPeople numberOfRowsInSection:1];
                int sizeOfArray = (int)[_users count];
                if (numberOfRows > 0 && numberOfRows > userInt  && userInt >= 0 && sizeOfArray > userInt) {
                    [_users replaceObjectAtIndex:userInt withObject:user];
                    [self.tableViewOfPeople beginUpdates];
                    [self.tableViewOfPeople reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:userInt inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableViewOfPeople endUpdates];
                }
            }

        }
       
    }
}

#pragma mark - Network functions

- (void)loadNextPage {
    if ([self.currentTab isEqualToNumber:@2]) {
        [self fetchEveryone];
    }
    else if ([self.currentTab isEqualToNumber:@3]) {
        [self fetchFollowers];
    }
    else if ([self.currentTab isEqualToNumber:@4]) {
        [self fetchFollowing];
    }
}

- (void)fetchFirstPageSuggestions {
    [WGUser getSuggestions:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                return;
            }
            _suggestions = collection;
            [_suggestions getNextPage:^(WGCollection *collection, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        return;
                    }
                    _everyone = collection;
                    _users = _everyone;
                    secondPartSubview = [self initializeSecondPart];
                    [self.tableViewOfPeople reloadData];
                });
            }];
        });
    }];
}

- (void)fetchFirstPageEveryone {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    _everyone = nil;
    fetching = NO;
    [self fetchEveryone];
}

- (void) fetchEveryone {
    if (!fetching) {
        fetching = YES;
        __weak typeof(self) weakSelf = self;
        if (!_everyone) {
            [WGUser get:^(WGCollection *collection, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        fetching = NO;
                        return;
                    }
                    _everyone = collection;
                    _users = _everyone;
                    [strongSelf.tableViewOfPeople reloadData];
                    fetching = NO;
                });
            }];
        } else if ([_everyone.hasNextPage boolValue]) {
            [_everyone getNextPage:^(WGCollection *collection, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        fetching = NO;
                        return;
                    }
                    
                    if (_suggestions) {
                        [_everyone addObjectsFromCollection:collection notInCollection:_suggestions];
                    } else {
                        [_everyone addObjectsFromCollection:collection];
                    }
                    _everyone.hasNextPage = collection.hasNextPage;
                    _everyone.nextPage = collection.nextPage;
                    
                    _users = _everyone;
                    [strongSelf.tableViewOfPeople reloadData];
                    secondPartSubview = [self initializeSecondPart];
                    fetching = NO;
                });
            }];
        } else {
            fetching = NO;
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
        }
    }
}

-(void) fetchFirstPageFollowers {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    fetching = NO;
    _followers = nil;
    [self fetchFollowers];
}

-(void) fetchFollowers {
    __weak typeof(self) weakSelf = self;
    if (!fetching) {
        fetching = YES;
        if (!_followers) {
            [WGFollow getFollowsForFollow:self.user withHandler:^(WGCollection *collection, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong typeof(self) strongSelf = weakSelf;
                    [WiGoSpinnerView removeDancingGFromCenterView:strongSelf.view];
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        fetching = NO;
                        return;
                    }
                    strongSelf.followers = collection;
                    strongSelf.users = [[WGCollection alloc] initWithType:[WGUser class]];
                    for (WGFollow *follow in strongSelf.followers) {
                        [strongSelf.users addObject:follow.user];
                    }
                    [strongSelf.tableViewOfPeople reloadData];
                    fetching = NO;
                });
            }];
        } else if ([_followers.hasNextPage boolValue]) {
            [_followers addNextPage:^(BOOL success, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong typeof(self) strongSelf = weakSelf;
                    [WiGoSpinnerView removeDancingGFromCenterView:strongSelf.view];
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        fetching = NO;
                        return;
                    }
                    strongSelf.users = [[WGCollection alloc] initWithType:[WGUser class]];
                    for (WGFollow *follow in strongSelf.followers) {
                        [strongSelf.users addObject:follow.user];
                    }
                    [strongSelf.tableViewOfPeople reloadData];
                    fetching = NO;
                });
            }];
        } else {
            fetching = NO;
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
        }
    }
}

-(void) fetchFirstPageFollowing {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    _following = nil;
    fetching = NO;
    [self fetchFollowing];
}

-(void) fetchFollowing {
    if (!fetching) {
        fetching = YES;
        __weak typeof(self) weakSelf = self;
        if (!_following) {
            [WGFollow getFollowsForUser:self.user withHandler:^(WGCollection *collection, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong typeof(self) strongSelf = weakSelf;
                    [WiGoSpinnerView removeDancingGFromCenterView:strongSelf.view];
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        fetching = NO;
                        return;
                    }
                    strongSelf.following = collection;
                    strongSelf.users = [[WGCollection alloc] initWithType:[WGUser class]];
                    for (WGFollow *follow in strongSelf.following) {
                        [strongSelf.users addObject:follow.follow];
                    }
                    [strongSelf.tableViewOfPeople reloadData];
                    secondPartSubview = [strongSelf initializeSecondPart];
                    fetching = NO;
                });
            }];
        } else if ([_following.hasNextPage boolValue]) {
            [_following addNextPage:^(BOOL success, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong typeof(self) strongSelf = weakSelf;
                    [WiGoSpinnerView removeDancingGFromCenterView:strongSelf.view];
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        fetching = NO;
                        return;
                    }
                    strongSelf.users = [[WGCollection alloc] initWithType:[WGUser class]];
                    for (WGFollow *follow in strongSelf.following) {
                        [strongSelf.users addObject:follow.follow];
                    }
                    [strongSelf.tableViewOfPeople reloadData];
                    secondPartSubview = [strongSelf initializeSecondPart];
                    fetching = NO;
                });
            }];
        } else {
            fetching = NO;
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
        }
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
    } else {
        [UIView animateWithDuration:0.01 animations:^{
            _searchIconImageView.transform = CGAffineTransformMakeTranslation(0,0);
        }  completion:^(BOOL finished){
            _searchIconImageView.hidden = NO;
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if([searchText length] != 0) {
        _isSearching = YES;
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.3
     cancelPreviousRequest:YES];
    } else {
        _isSearching = NO;
        [self.tableViewOfPeople reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performBlock:^(void){[self searchTableList];}
            afterDelay:0.3
 cancelPreviousRequest:YES];
}


- (void)searchTableList {
    NSString *oldString = _searchBar.text;
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    if ([self.currentTab isEqualToNumber:@2]) {
        __weak typeof(self) weakSelf = self;
        [WGUser searchUsers:searchString withHandler:^(WGCollection *collection, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    fetching = NO;
                    return;
                }
                _filteredUsers = collection;
                [strongSelf.tableViewOfPeople reloadData];
                fetching = NO;
            });
        }];
    }
}

- (void) getNextPageForFilteredContent {
    __weak typeof(self) weakSelf = self;
    [_filteredUsers addNextPage:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                return;
            }
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}


@end
