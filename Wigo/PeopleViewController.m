//
//  PeopleViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PeopleViewController.h"
#import "FontProperties.h"
#import "ProfileViewController.h"
#import "UIButtonAligned.h"
#import "Profile.h"
#import "Network.h"

#import "SDWebImage/UIImageView+WebCache.h"

@interface PeopleViewController ()

@property int chosenFilter;
@property(atomic) UIButton *yourSchoolButton;
@property(atomic) UIButton *followersButton;
@property(atomic) UIButton *followingButton;

//Table View of people
@property UITableView *tableViewOfPeople;

// Search Bar Content
@property NSArray *contentList;
@property NSMutableArray *filteredContentList;
@property BOOL isSearching;
@property  UISearchBar *searchBar;
@property UIImageView *searchIconImageView;

@property ProfileViewController *profileViewController;

@property Party *everyoneParty;
@property Party *followingParty;

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
    
    //Search Bar Setup
    _everyoneParty = [Profile everyoneParty];
    [_everyoneParty removeUserFromParty:[Profile user]];
    _contentList = [_everyoneParty getObjectArray];
    _filteredContentList = [[NSMutableArray alloc] initWithArray:_contentList];
    _followingParty = [[Party alloc] init];
    
    // Title setup
    self.title = [self.user fullName];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self initializeYourSchoolButton];
    [self initializeFollowingButton];
    [self initializeFollowersButton];
    [self initializeSearchBar];
    [self initializeTableOfPeople];
    [self initializeTapHandler];
    if ([[self.user allKeys] containsObject:@"tabNumber"]) {
        [self loadTableViewForTag:[self.user objectForKey:@"tabNumber"]];
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
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)initializeYourSchoolButton {
    _yourSchoolButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width/3, 60)];
    [_yourSchoolButton setTitle:[NSString stringWithFormat:@"%d\nSchool", [_contentList count]] forState:UIControlStateNormal];
    _yourSchoolButton.backgroundColor = [FontProperties getOrangeColor];
    _yourSchoolButton.titleLabel.font = [FontProperties getTitleFont];
    _yourSchoolButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _yourSchoolButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _yourSchoolButton.tag = 2;
    [_yourSchoolButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchDown];
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
    [_followersButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchDown];
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
    [_followingButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:_followingButton];
}


- (void)initializeTableOfPeople {
    _tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 170, self.view.frame.size.width, self.view.frame.size.height - 160)];
    _tableViewOfPeople.delegate = self;
    _tableViewOfPeople.dataSource = self;
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
        NSLog(@"subview %@",  subView);
        for (UIView *secondLevelSubview in subView.subviews){
            NSLog(@"subview %@ ",secondLevelSubview );
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
    [_filteredContentList removeAllObjects];
    
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
    
    for (NSString *tempStr in _contentList) {
        NSArray *firstAndLastNameArray = [tempStr componentsSeparatedByString:@" "];
        for (NSString *firstOrLastName in firstAndLastNameArray) {
            NSComparisonResult result = [firstOrLastName compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
            if (result == NSOrderedSame && ![_filteredContentList containsObject:tempStr]) {
                [_filteredContentList addObject:tempStr];
            }
        }
    }
}

#pragma mark - Filter handlers

- (void) changeFilter:(id)sender {
    UIButton *chosenButton = (UIButton *)sender;
    int tag = chosenButton.tag;
    if (tag >= 2) {
        [self loadTableViewForTag:[NSNumber numberWithInt:tag]];
    }
}

- (void)loadTableViewForTag:(NSNumber *)tag {
    UIButton *filterButton;
    for (int i = 2; i < 5; i++) {
        filterButton = (UIButton *)[self.view viewWithTag:i];
        filterButton.backgroundColor = [FontProperties getLightOrangeColor];
        [filterButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    UIButton *chosenButton = (UIButton *)[self.view viewWithTag:[tag intValue]];
    chosenButton.backgroundColor = [FontProperties getOrangeColor];
    [chosenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    if ([tag isEqualToNumber:@2]) {
        _contentList = [_everyoneParty getObjectArray];
        [_tableViewOfPeople reloadData];
    }
    else if ([tag isEqualToNumber:@3]) {
        NSString *queryString = [NSString stringWithFormat:@"follows/?follow=%d", [[self.user objectForKey:@"id"] intValue]];
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
            NSMutableArray *arrayOfUsers = [[NSMutableArray alloc] initWithCapacity:[arrayOfFollowObjects count]];
            for (NSDictionary *object in arrayOfFollowObjects) {
                [arrayOfUsers addObject:[object objectForKey:@"follow"]];
            }
            Party *party = [[Party alloc] initWithObjectName:@"User"];
            [party addObjectsFromArray:arrayOfUsers];
            _contentList = [party getObjectArray];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_followersButton setTitle:[NSString stringWithFormat:@"%d\nFollowers", [_contentList count]] forState:UIControlStateNormal];
                [_tableViewOfPeople reloadData];
            });
        }];
    }
    else if ([tag isEqualToNumber:@4]) {
        NSString *queryString = [NSString stringWithFormat:@"follows/?user=%d", [[self.user objectForKey:@"id"] intValue]];
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
            NSMutableArray *arrayOfUsers = [[NSMutableArray alloc] initWithCapacity:[arrayOfFollowObjects count]];
            for (NSDictionary *object in arrayOfFollowObjects) {
                [arrayOfUsers addObject:[object objectForKey:@"follow"]];
            }
            _followingParty = [[Party alloc] initWithObjectName:@"User"];
            [_followingParty addObjectsFromArray:arrayOfUsers];
            _contentList = [_followingParty getObjectArray];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_followingButton setTitle:[NSString stringWithFormat:@"%d\nFollowing", [_contentList count]] forState:UIControlStateNormal];
                [_tableViewOfPeople reloadData];
            });
        }];
    }
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isSearching) {
        return [_filteredContentList count];
    }
    else {
        return [_contentList count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user = [self getUserForIndexPath:indexPath];

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 7, 150, 60)];
       textLabel.font = [FontProperties getSmallFont];
    textLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
    [cell.contentView addSubview:textLabel];
    
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    [profileImageView setImageWithURL:[[user imagesURL] objectAtIndex:0]];
    [cell.contentView addSubview:profileImageView];
    
    UIButton *favoriteButton = [[UIButton alloc]initWithFrame:CGRectMake(250, 24, 49, 30)];
    favoriteButton.tag = -100;
    [favoriteButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    [favoriteButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchDown];
    [cell.contentView addSubview:favoriteButton];
    
    if ([[_followingParty getObjectArray] count] > 0 ) {
        if ([_followingParty containsObject:user]) {
            [favoriteButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
        }
    }
    
    return cell;
}



- (void) followedPersonPressed:(id)sender {
    //Get Index Path
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:_tableViewOfPeople];
    NSIndexPath *indexPath = [_tableViewOfPeople indexPathForRowAtPoint:buttonOriginInTableView];
    User *user = [self getUserForIndexPath:indexPath];
    
    UIButton *senderButton = (UIButton*)sender;
    if (senderButton.tag == -100) {
        [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
        senderButton.tag = 100;
        [Network followUser:user];
    }
    else {
        [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        senderButton.tag = -100;
//        [Network unfollowUser:user];
    }
}

- (User *)getUserForIndexPath:(NSIndexPath *)indexPath {
    User *user;
    if (_isSearching) {
        user = [_contentList objectAtIndex:[indexPath row]];
    }
    else {
        user = [_filteredContentList objectAtIndex:[indexPath row]];
    }
    return user;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}




@end
