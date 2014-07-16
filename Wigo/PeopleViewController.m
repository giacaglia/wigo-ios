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
#import "SDWebImage/UIImageView+WebCache.h"

@interface PeopleViewController ()

@property int chosenFilter;
@property(atomic) UIButton *yourSchoolButton;
@property(atomic) UIButton *followersButton;
@property(atomic) UIButton *followingButton;

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
@property Party *notAcceptedFollowingParty;
@property Party *followersParty;

@property NSNumber *page;
@property NSNumber *currentTab;
@end

@implementation PeopleViewController

- (id)initWithUser:(User *)user {
    self = [super init];
    if (self) {
        self.user = user;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _chosenFilter = 1;
    _page = @1;
    _currentTab = @2;
    //Search Bar Setup
    _everyoneParty = [[Party alloc] initWithObjectName:@"User"];
    _followersParty = [[Party alloc] initWithObjectName:@"User"];
    _followingParty = [Profile followingParty];
    _notAcceptedFollowingParty = [Profile notAcceptedFollowingParty];

    _contentParty = _everyoneParty;
    _filteredContentParty = [_everyoneParty copy];
    
    // Title setup
    self.title = [self.user fullName];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self fetchEveryone];
    [self initializeYourSchoolButton];
    [self initializeFollowingButton];
    [self initializeFollowersButton];
    [self initializeSearchBar];
    [self initializeTableOfPeople];
    [self initializeTapHandler];
    if ([[self.user allKeys] containsObject:@"tabNumber"]) {
        _currentTab = [self.user objectForKey:@"tabNumber"];
        [self loadTableView];
    }
}

- (void) viewWillAppear:(BOOL)animated {
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

- (void) goBack {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
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
    [self.view endEditing:YES];
    if ([viewSender isKindOfClass:[UIImageView class]] || [viewSender isKindOfClass:[UITextView class]]) {
        int tag = viewSender.tag;
        User *user = [self getUserAtIndex:tag];
        self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.profileViewController animated:YES];
    }
}

- (void)initializeYourSchoolButton {
    _yourSchoolButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width/3, 60)];
    [_yourSchoolButton setTitle:@"School" forState:UIControlStateNormal];
    _yourSchoolButton.backgroundColor = [FontProperties getOrangeColor];
    _yourSchoolButton.titleLabel.font = [FontProperties getTitleFont];
    _yourSchoolButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _yourSchoolButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _yourSchoolButton.tag = 2;
    [_yourSchoolButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_yourSchoolButton];
}

- (void)initializeFollowersButton {
    _followersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/3, 64, self.view.frame.size.width/3, 60)];
    _followersButton.backgroundColor = [FontProperties getLightOrangeColor];
    [_followersButton setTitle:[NSString stringWithFormat:@"%d\nFollowers", [(NSNumber*)[self.user objectForKey:@"num_followers"] intValue]] forState:UIControlStateNormal];
    [_followersButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _followersButton.titleLabel.font = [FontProperties getTitleFont];
    _followersButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _followersButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _followersButton.tag = 3;
    [_followersButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_followersButton];
}

- (void)initializeFollowingButton {
    _followingButton = [[UIButton alloc] initWithFrame:CGRectMake(2*self.view.frame.size.width/3, 64, self.view.frame.size.width/3, 60)];
    _followingButton.backgroundColor = [FontProperties getLightOrangeColor];
    [_followingButton setTitle:[NSString stringWithFormat:@"%d\nFollowing", [(NSNumber*)[self.user objectForKey:@"num_following"] intValue]] forState:UIControlStateNormal];
    [_followingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _followingButton.titleLabel.font = [FontProperties getTitleFont];
    _followingButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _followingButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _followingButton.tag = 4;
    [_followingButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_followingButton];
}


- (void)initializeTableOfPeople {
    _tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 164, self.view.frame.size.width, self.view.frame.size.height - 160)];
    _tableViewOfPeople.delegate = self;
    _tableViewOfPeople.dataSource = self;
    _tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_tableViewOfPeople];
}


#pragma mark - Search Bar 

- (void)initializeSearchBar {
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 124, self.view.frame.size.width, 40)];
    _searchBar.barTintColor = [FontProperties getOrangeColor];
    _searchBar.tintColor = [FontProperties getOrangeColor];
    _searchBar.placeholder = @"Search By Name";
    _searchBar.delegate = self;
    _searchBar.layer.borderWidth = 1.0f;
    _searchBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    UITextField *searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:[FontProperties getOrangeColor] forKeyPath:@"_placeholderLabel.textColor"];
    [self.view addSubview:_searchBar];
    
    // Search Icon Clear
    UITextField *txfSearchField = [_searchBar valueForKey:@"_searchField"];
    [txfSearchField setLeftViewMode:UITextFieldViewModeNever];

    // Add Custom Search Icon
    _searchIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeSearchIcon"]];
    _searchIconImageView.frame = CGRectMake(85, 13, 14, 14);
    [_searchBar addSubview:_searchIconImageView];
    [self.view addSubview:_searchBar];
    [self.view bringSubviewToFront:_searchBar];
    
    // Remove Clear Button on the right
    UITextField *textField = [_searchBar valueForKey:@"_searchField"];
    textField.clearButtonMode = UITextFieldViewModeNever;
    
    // Text when editing becomes orange
    for (UIView *subView in _searchBar.subviews) {
        for (UIView *secondLevelSubview in subView.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]])
            {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                searchBarTextField.textColor = [FontProperties getOrangeColor];
                break;
            }
        }
    }
    

}

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
        [self searchTableList];
    }
    else {
        _isSearching = NO;
    }
    [_tableViewOfPeople reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchTableList];
}

- (void)searchTableList {
    NSString *searchString = _searchBar.text;
    
    NSArray *contentNameArray = [_contentParty getFullNameArray];
    for (int i = 0; i < [contentNameArray count]; i++) {
        NSString *tempStr = [contentNameArray objectAtIndex:i];
        NSArray *firstAndLastNameArray = [tempStr componentsSeparatedByString:@" "];
        for (NSString *firstOrLastName in firstAndLastNameArray) {
            NSComparisonResult result = [firstOrLastName compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
            if (result == NSOrderedSame && ![[_filteredContentParty getFullNameArray] containsObject:tempStr]) {
                [_filteredContentParty addObject: [[_contentParty getObjectArray] objectAtIndex:i]];
            }
        }
    }
}

#pragma mark - Filter handlers

- (void) changeFilter:(id)sender {
    UIButton *chosenButton = (UIButton *)sender;
    int tag = chosenButton.tag;
    if (tag >= 2) {
        _currentTab = [NSNumber numberWithInt:tag];
        [self loadTableView];
    }
}

- (void)loadTableView {
    UIButton *filterButton;
    for (int i = 2; i < 5; i++) {
        filterButton = (UIButton *)[self.view viewWithTag:i];
        filterButton.backgroundColor = [FontProperties getLightOrangeColor];
        [filterButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    UIButton *chosenButton = (UIButton *)[self.view viewWithTag:[_currentTab intValue]];
    chosenButton.backgroundColor = [FontProperties getOrangeColor];
    [chosenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    if ([_currentTab isEqualToNumber:@2]) {
        _contentParty = _everyoneParty;
        [_tableViewOfPeople reloadData];
    }
    else if ([_currentTab isEqualToNumber:@3]) {
        _page = @1;
        [self fetchFollowers];
    }
    else if ([_currentTab isEqualToNumber:@4]) {
        if ([[Profile user] isEqualToUser:self.user]) {
            _followingParty = [Profile followingParty];
            _contentParty = _followingParty;
            [_tableViewOfPeople reloadData];
        }
        else {
            _page = @1;
            _followingParty = [[Party alloc] initWithObjectName:@"User"];
            [self fetchFollowing];
        }
    }
}

#pragma mark - Network functions

- (void) fetchEveryone {
    NSString *queryString = [NSString stringWithFormat:@"users/?ordering=goingout&page=%@" ,[_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
        [_everyoneParty addObjectsFromArray:arrayOfUsers];
        NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
        [_everyoneParty addMetaInfo:metaDictionary];
        [Profile setEveryoneParty:_everyoneParty];
        [_everyoneParty removeUser:[Profile user]];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            _page = @([_page intValue] + 1);
            _contentParty = _everyoneParty;
            [_tableViewOfPeople reloadData];
        });
    }];
}

- (void)fetchFollowers {
    NSString *queryString = [NSString stringWithFormat:@"follows/?follow=%d&page=%@", [[self.user objectForKey:@"id"] intValue], [_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
        [_followersButton setTitle:[NSString stringWithFormat:@"%d\nFollowers", [arrayOfFollowObjects count]] forState:UIControlStateNormal];
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
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            _page = @([_page intValue] + 1);
            _contentParty = _followersParty;
            [_tableViewOfPeople reloadData];
        });
    }];
}

- (void)fetchFollowing {
    NSString *queryString = [NSString stringWithFormat:@"follows/?user=%d&page=%@", [[self.user objectForKey:@"id"] intValue], [_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
        dispatch_async(dispatch_get_main_queue(), ^(void){
            _page = @([_page intValue] + 1);
            _contentParty = _followingParty;
            [_tableViewOfPeople reloadData];
        });
    }];
 
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isSearching) {
        return [[_filteredContentParty getObjectArray] count];
    }
    else {
        int hasNextPage = ([_contentParty hasNextPage] ? 1 : 0);
        return [[_contentParty getObjectArray] count] + hasNextPage;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if ([indexPath row] == [[_contentParty getObjectArray] count]) {
        [self loadNextPage];
        return cell;
    }
    
    User *user = [self getUserAtIndex:[indexPath row]];
    
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    profileImageView.tag = [indexPath row];
    profileImageView.userInteractionEnabled = YES;
    [cell.contentView addSubview:profileImageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    tap.cancelsTouchesInView = NO;
    [profileImageView addGestureRecognizer:tap];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(85, 20, 150, 28)];
    textView.font = [FontProperties getSmallFont];
    textView.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
    textView.tag = [indexPath row];
    textView.textAlignment = NSTextAlignmentLeft;
    textView.scrollEnabled = NO;
    [textView addGestureRecognizer:tap];
    [cell.contentView addSubview:textView];
    
    UIButton *favoriteButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, 24, 49, 30)];
    [favoriteButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    favoriteButton.tag = -100;
    [favoriteButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:favoriteButton];
    
    if ([[_followingParty getObjectArray] count] > 0 ) {
        if ([_followingParty containsObject:user]) {
            [favoriteButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
            favoriteButton.tag = 100;
        }
    }
    
    if ([[_notAcceptedFollowingParty getObjectArray] count] > 0 ) {
        if ([_notAcceptedFollowingParty containsObject:user]) {
            [favoriteButton setBackgroundImage:nil forState:UIControlStateNormal];
            [favoriteButton setTitle:@"Pending" forState:UIControlStateNormal];
            [favoriteButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            favoriteButton.titleLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:12.0f];
            favoriteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            favoriteButton.layer.borderWidth = 1;
            favoriteButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            favoriteButton.layer.cornerRadius = 3;
            favoriteButton.tag = 100;
        }
    }
    
    return cell;
}

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
    User *user = [self getUserAtIndex:[indexPath row]];
    
    UIButton *senderButton = (UIButton*)sender;
    if (senderButton.tag == -100) {
        int num_following = [(NSNumber*)[self.user objectForKey:@"num_following"] intValue];

        if ([user private]) {
            [senderButton setBackgroundImage:nil forState:UIControlStateNormal];
            [senderButton setTitle:@"Pending" forState:UIControlStateNormal];
            [senderButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            senderButton.titleLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:12.0f];
            senderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            senderButton.layer.borderWidth = 1;
            senderButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            senderButton.layer.cornerRadius = 3;
            [_notAcceptedFollowingParty addObject:user];
        }
        else {
            [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
            [_followingParty addObject:user];
            num_following += 1;
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
        if ([user private]) {
            [_notAcceptedFollowingParty removeUser:user];
        }
        else {
            [_followingParty removeUser:user];
            num_following -= 1;
        }
        [self updateFollowingUIAndCachedData:num_following];
        [Network unfollowUser:user];

    }
}

- (void) updateFollowingUIAndCachedData:(int)num_following {
    [_followingButton setTitle:[NSString stringWithFormat:@"%d\nFollowing", num_following]  forState:UIControlStateNormal];
    User *profileUser = [Profile user];
    [profileUser setObject:[NSNumber numberWithInt:num_following] forKey:@"num_following"];
    [Profile setFollowingParty:_followingParty];
    [Profile setNotAcceptedFollowingParty:_notAcceptedFollowingParty];
    [Profile setUser:profileUser];
}

- (User *)getUserAtIndex:(int)index {
    User *user;
    if (_isSearching) {
        user = [[_filteredContentParty getObjectArray] objectAtIndex:index];
    }
    else {
        user = [[_contentParty getObjectArray] objectAtIndex:index];
    }
    return user;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

@end
