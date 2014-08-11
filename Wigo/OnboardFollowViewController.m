//
//  OnboardFollowViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 8/11/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "OnboardFollowViewController.h"
#import "Globals.h"

BOOL pushed;
UISearchBar *searchBar;
UITableView *tableViewOfPeople;
NSNumber *page;
Party *contentParty;
Party *filteredContentParty;
BOOL isSearching;
UIImageView *searchIconImageView;

@implementation OnboardFollowViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.hidden = YES;
        self.navigationItem.hidesBackButton = YES;
        [self.navigationController setNavigationBarHidden: YES animated:YES];
        pushed = NO;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Follow Your Classmates";
    [self initializeTapHandler];
    [self initializeSearchBar];
    [self initializeTableOfPeople];
    [self initializeContinueButton];
    [self fetchFirstPageEveryone];
}

- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tappedView:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)tappedView:(UITapGestureRecognizer*)tapSender {
    [self.view endEditing:YES];
//    if (user) {
//        self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
//        [self.navigationController pushViewController:self.profileViewController animated:YES];
//    }
}


- (void)initializeSearchBar {
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 40)];
    searchBar.barTintColor = [FontProperties getOrangeColor];
    searchBar.tintColor = [FontProperties getOrangeColor];
    searchBar.placeholder = @"Search By Name";
    searchBar.delegate = self;
    searchBar.layer.borderWidth = 1.0f;
    searchBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    UITextField *searchField = [searchBar valueForKey:@"_searchField"];
    [searchField setValue:[FontProperties getOrangeColor] forKeyPath:@"_placeholderLabel.textColor"];
    [self.view addSubview:searchBar];
    
    // Search Icon Clear
    UITextField *txfSearchField = [searchBar valueForKey:@"_searchField"];
    [txfSearchField setLeftViewMode:UITextFieldViewModeNever];
    
    // Add Custom Search Icon
    searchIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeSearchIcon"]];
    searchIconImageView.frame = CGRectMake(85, 13, 14, 14);
    [searchBar addSubview:searchIconImageView];
    [self.view addSubview:searchBar];
    [self.view bringSubviewToFront:searchBar];
    
    // Remove Clear Button on the right
    UITextField *textField = [searchBar valueForKey:@"_searchField"];
    textField.clearButtonMode = UITextFieldViewModeNever;
    
    // Text when editing becomes orange
    for (UIView *subView in searchBar.subviews) {
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

- (void)initializeTableOfPeople {
    tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 158)];
    tableViewOfPeople.delegate = self;
    tableViewOfPeople.dataSource = self;
    tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:tableViewOfPeople];
}

- (void)initializeContinueButton {
    UIButton *continueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 54, self.view.frame.size.width, 54)];
    [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [continueButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    continueButton.titleLabel.font = [FontProperties getBigButtonFont];
    continueButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    continueButton.layer.borderWidth = 1.0f;
    [continueButton addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventTouchDown];
    
    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeRightArrow"]];
    rightArrowImageView.frame = CGRectMake(continueButton.frame.size.width - 35, 27 - 9, 11, 18);
    [continueButton addSubview:rightArrowImageView];
    [self.view addSubview:continueButton];
}




- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return PEOPLEVIEW_HEIGHT_OF_CELLS;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (isSearching) {
        return [[filteredContentParty getObjectArray] count];
    }
    else {
        int hasNextPage = ([contentParty hasNextPage] ? 1 : 0);
        return [[contentParty getObjectArray] count] + hasNextPage;
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
    
    if ([[contentParty getObjectArray] count] == 0) return cell;
    if ([indexPath row] == [[contentParty getObjectArray] count]) {
        [self fetchEveryone];
        return cell;
    }
    
    User *user = [self getUserAtIndex:(int)[indexPath row]];
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 30, 60, 60)];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    [profileButton addSubview:profileImageView];
    [profileButton setShowsTouchWhenHighlighted:YES];
    profileButton.tag = [indexPath row];
    [cell.contentView addSubview:profileButton];
    
    if ([user isFavorite]) {
        UIImageView *favoriteSmall = [[UIImageView alloc] initWithFrame:CGRectMake(6, profileButton.frame.size.height - 16, 10, 10)];
        favoriteSmall.image = [UIImage imageNamed:@"favoriteSmall"];
        [profileButton addSubview:favoriteSmall];
    }
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    labelName.font = [FontProperties mediumFont:18.0f];
    labelName.text = [user fullName];
    labelName.tag = [indexPath row];
    labelName.textAlignment = NSTextAlignmentLeft;
    labelName.userInteractionEnabled = YES;
    [cell.contentView addSubview:labelName];
    
    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 45, 150, 20)];
    goingOutLabel.font =  [FontProperties mediumFont:15.0f];
    goingOutLabel.textAlignment = NSTextAlignmentLeft;
    if ([user isGoingOut]) {
        goingOutLabel.text = @"Going Out";
        goingOutLabel.textColor = [FontProperties getOrangeColor];
    }
    [cell.contentView addSubview:goingOutLabel];
    
    
    if (![user isEqualToUser:[Profile user]]) {
        UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 15, 49, 30)];
        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        followPersonButton.tag = -100;
        [followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:followPersonButton];
        
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
    
    return cell;
}

- (User *)getUserAtIndex:(int)index {
    User *user;
    if (isSearching) {
        if ([[filteredContentParty getObjectArray] count] != 0)
            user = [[filteredContentParty getObjectArray] objectAtIndex:index];
    }
    else {
        if ([[contentParty getObjectArray] count] != 0)
            user = [[contentParty getObjectArray] objectAtIndex:index];
    }
    return user;
}

- (void) followedPersonPressed:(id)sender {
    //Get Index Path
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:tableViewOfPeople];
    NSIndexPath *indexPath = [tableViewOfPeople indexPathForRowAtPoint:buttonOriginInTableView];
    User *user = [self getUserAtIndex:(int)[indexPath row]];
    
    UIButton *senderButton = (UIButton*)sender;
    if (senderButton.tag == -100) {
        if ([user isPrivate]) {
            [senderButton setBackgroundImage:nil forState:UIControlStateNormal];
            [senderButton setTitle:@"Pending" forState:UIControlStateNormal];
            [senderButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            senderButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            senderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            senderButton.layer.borderWidth = 1;
            senderButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            senderButton.layer.cornerRadius = 3;
        }
        else {
            [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
        }
        senderButton.tag = 100;
        [Network followUser:user];
    }
    else {
        [senderButton setTitle:nil forState:UIControlStateNormal];
        [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        senderButton.tag = -100;
        [Network unfollowUser:user];
    }
}

- (void)continuePressed {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
}

#pragma mark - Network functions

- (void)fetchFirstPageEveryone {
    page = @1;
    contentParty = [[Party alloc] initWithObjectType:USER_TYPE];
    [self fetchEveryone];
}

- (void) fetchEveryone {
    NSString *queryString = [NSString stringWithFormat:@"users/?ordering=-id&page=%@" ,[page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
        [contentParty addObjectsFromArray:arrayOfUsers];
        NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
        [contentParty addMetaInfo:metaDictionary];
        [Profile setEveryoneParty:contentParty];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            page = @([page intValue] + 1);
            [tableViewOfPeople reloadData];
        });
    }];
}



@end
