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
@property UISearchBar *searchBar;
@end

BOOL didProfileSegue;
NSIndexPath *userIndex;

@implementation PeopleViewController

- (id)initWithUser:(WGUser *)user andTab:(NSNumber *)tab {
    self = [super init];
    if (self) {
        self.user = user;
        self.currentTab = tab;
        self.view.backgroundColor = UIColor.whiteColor;
    }
    return self;
}

- (id)initWithUser:(WGUser *)user {
    self = [super init];
    if (self) {
        self.user = user;
        self.view.backgroundColor = UIColor.whiteColor;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    didProfileSegue = NO;
    if (!self.currentTab) self.currentTab = @2;
    userIndex = [NSIndexPath indexPathForRow:-1 inSection:1];
    self.users = [[WGCollection alloc] initWithType:[WGUser class]];
    // Title setup
    [self initializeBackBarButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserAtTable:) name:@"updateUserAtTable" object:nil];

    [self initializeTableOfPeople];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.currentTab isEqualToNumber:@2]) {
        [WGAnalytics tagView:@"school_people"];
    }
    else if ([self.currentTab isEqualToNumber:@3]) {
        [WGAnalytics tagView:@"friends"];
    }
    [self initializeRightBarButton];

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    if (!didProfileSegue) {
        if (!self.currentTab) self.currentTab = @2;
        self.users = [[WGCollection alloc] initWithType:[WGUser class]];
        self.filteredUsers = [[WGCollection alloc] initWithType:[WGUser class]];
        [self loadTableView];
    }
    didProfileSegue = NO;
    userIndex = [NSIndexPath indexPathForRow:-1 inSection:1];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
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
    if ([self.currentTab isEqual:@2]) {
        UIButtonAligned *inviteButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 40, 16) andType:@3];
        [inviteButton setTitle:@"INVITE" forState:UIControlStateNormal];
        [inviteButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        inviteButton.titleLabel.textAlignment = NSTextAlignmentRight;
        [inviteButton addTarget:self action:@selector(invitePressed)
                forControlEvents:UIControlEventTouchUpInside];
        inviteButton.titleLabel.font = [FontProperties mediumFont:13.0f];
        self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:inviteButton];
    }
    else {
        CGRect profileFrame = CGRectMake(0, 0, 30, 30);
        UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@3];
        profileButton.userInteractionEnabled = NO;
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
        profileImageView.layer.borderWidth = 1.0f;
        profileImageView.layer.cornerRadius = profileFrame.size.width/2;
        [profileImageView setSmallImageForUser:self.user completed:nil];
        [profileButton addSubview:profileImageView];
        [profileButton setShowsTouchWhenHighlighted:YES];
        UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
        self.navigationItem.rightBarButtonItem = profileBarButton;
    }
}

- (void) goBack {
    [[WGProfile currentUser] setLastUserReadToLatest:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
        }
    }];
    [self.navigationController popViewControllerAnimated:YES];

}

- (void)tappedButton:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGUser *user = [self getUserAtIndex:tag];
    if (user) {
        didProfileSegue = YES;
        userIndex = [NSIndexPath indexPathForRow:tag inSection:1];
        [self presentUser:user];
    }
}

- (void)presentUser:(WGUser *)user {
    ProfileViewController *profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = user;
    [self.navigationController pushViewController:profileViewController animated:YES];
}


- (void)initializeTableOfPeople {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    if ([self.currentTab isEqual:@2]) {
        self.tableViewOfPeople.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 108);
    }
    [self.tableViewOfPeople registerClass:[PeopleCell class] forCellReuseIdentifier:kPeopleCellName];
    [self.tableViewOfPeople registerClass:[FollowPeopleCell class] forCellReuseIdentifier:kFollowPeopleCell];
    self.tableViewOfPeople.delegate = self;
    self.tableViewOfPeople.dataSource = self;
    self.tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableViewOfPeople.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableViewOfPeople.showsVerticalScrollIndicator = NO;
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(40, 0, self.view.frame.size.width - 80, 50)];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"Search by Name";
    self.tableViewOfPeople.tableHeaderView = _searchBar;
    self.tableViewOfPeople.contentOffset = CGPointMake(0, 50);
    [self.view addSubview:self.tableViewOfPeople];
}


- (void)invitePressed  {
    [self presentViewController:[MobileContactsViewController new] animated:YES completion:nil];
}

#pragma mark - Filter handlers


- (void)loadTableView {
    self.navigationItem.titleView = nil;
    if ([self.currentTab isEqualToNumber:@2]) {
        [self fetchFirstPageSuggestions];
    }
    else if ([self.currentTab isEqualToNumber:@3]) {
        [self fetchFirstPageFollowers];
    }
}

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.currentTab isEqualToNumber:@2]) return 90;
        else if ([self.currentTab isEqualToNumber:@3]) return 95;
    }
    return PEOPLEVIEW_HEIGHT_OF_CELLS + 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.currentTab isEqual:@2]) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionFollowPeople && [self.currentTab isEqual:@2]) {
        if (self.isSearching) return 0;
        return 2;
    }
    else return (int)self.users.count + self.users.hasNextPage.intValue;
}


- (BOOL)isThereANextPage {
    if ([self.currentTab isEqual:@2]) {
        return self.users.hasNextPage.boolValue;
    }
    else if ([self.currentTab isEqual:@3]) {
       return self.followers.hasNextPage.boolValue;
    }
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionFollowPeople && [self.currentTab isEqual:@2]) {
        FollowPeopleCell *followPeopleCell = [tableView dequeueReusableCellWithIdentifier:kFollowPeopleCell forIndexPath:indexPath];
        followPeopleCell.user = WGProfile.currentUser;
        return followPeopleCell;
    }
    PeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:kPeopleCellName forIndexPath:indexPath];
    cell.contentView.frame = CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tableView heightForRowAtIndexPath:indexPath]);

    int tag = (int)[indexPath row];
    if ([self isThereANextPage] && tag == self.users.count - 5) {
        [self loadNextPage];
    }
     if (tag == self.users.count) {
        [self loadNextPage];
        return cell;
    }
    
    WGUser *user = [self getUserAtIndex:tag];
    if (!user) {
        if (self.users.hasNextPage.boolValue) {
          [cell.spinnerView startAnimating];
        }
        cell.profileImageView.image = nil;
        cell.nameLabel.text =  nil;
        cell.mutualFriendsLabel.text = nil;
        [cell.followPersonButton setImage:nil forState:UIControlStateNormal];
        return cell;
    }
    
    cell.user = user;
   
    cell.profileButton.tag = tag;
    cell.followPersonButton.tag = tag;
    [cell.followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    if (!user.isCurrentUser) {
        [cell.profileButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if ([self.currentTab isEqualToNumber:@2] &&
        user.id.intValue > WGProfile.currentUser.lastUserRead.intValue) {
        cell.orangeNewView.hidden = NO;
    }
    else {
        cell.orangeNewView.hidden = YES;
    }
    
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    if (self.isSearching) return 0;
    if ([self.currentTab isEqual:@2]) return 30.0f;
    return 0;
}

-(UIView *) tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    sectionHeaderView.backgroundColor = RGB(248, 248, 248);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.view.frame.size.width - 15, 30)];
    if (section == kSectionFollowPeople) {
        titleLabel.text= @"Friend Requests";
    }
    else {
        titleLabel.text = @"Suggested Friends";
    }
    titleLabel.font = [FontProperties lightFont:14.0f];
    titleLabel.textColor = RGB(150, 150, 150);
    [sectionHeaderView addSubview:titleLabel];
    return sectionHeaderView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_searchBar endEditing:YES];
}

- (void) followedPersonPressed:(id)sender {
///TODO: UPDATE THE NUMBER OF USERS BEING FOLLOWED BY THE PROFILE.USER
    UIButton *buttonSender = (UIButton *)sender;
    int row = buttonSender.tag;
    WGUser *user = (WGUser *)[self.users objectAtIndex:buttonSender.tag];
    [user followUser];
    [self.users replaceObjectAtIndex:row withObject:user];
    [self.tableViewOfPeople reloadData];
}


- (WGUser *)getUserAtIndex:(int)index {
    WGUser *user;
    int sizeOfArray = (int)self.users.count;
    if (sizeOfArray > 0 && sizeOfArray > index)
        user = (WGUser *)[self.users objectAtIndex:index];
    return user;
}

#pragma mark - Update User Info
- (void)updateUserAtTable:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    WGUser *user = [WGUser serialize:userInfo];
    if (!user) return;
    int userInt = (int)userIndex.row;
    
    if (userIndex.section == 0) {
        int numberOfRows = (int)[self.tableViewOfPeople numberOfRowsInSection:0];
        int sizeOfArray = (int)self.suggestions.count;
        if (numberOfRows > 0 && userInt >= 0 && sizeOfArray > userInt) {
            [self.users replaceObjectAtIndex:userInt withObject:user];
            [self.suggestions replaceObjectAtIndex:userInt withObject:user];
            [self.tableViewOfPeople reloadData];
        }
    } else {
        int numberOfRows = (int)[self.tableViewOfPeople numberOfRowsInSection:1];
        int sizeOfArray = (int)self.users.count;
        if (numberOfRows > 0 && numberOfRows > userInt  && userInt >= 0 && sizeOfArray > userInt) {
            [self.users replaceObjectAtIndex:userInt withObject:user];
            [self.tableViewOfPeople reloadData];
        }
    }
}

#pragma mark - Network functions

- (void)loadNextPage {
    if ([self.currentTab isEqualToNumber:@2]) {
        [self fetchNextPageSuggestions];
    }
    else if ([self.currentTab isEqualToNumber:@3]) {
        [self fetchFollowers];
    }
}

- (void)fetchFirstPageSuggestions {
    self.users = NetworkFetcher.defaultGetter.suggestions;
    [self.tableViewOfPeople reloadData];
}

- (void)fetchNextPageSuggestions {
    if (self.fetching) return;
    if (!self.users.hasNextPage.boolValue) return;
    self.fetching = YES;
    __weak typeof(self) weakSelf = self;
    [self.users addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.fetching = NO;
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        [strongSelf.tableViewOfPeople reloadData];

    }];
}

- (void)fetchFirstPageEveryone {
    if (self.fetching) return;
    self.fetching = YES;
    [WGSpinnerView addDancingGToCenterView:self.view];
    self.everyone = [[WGCollection alloc] initWithType:[WGUser class]];
    __weak typeof(self) weakSelf = self;
    [WGUser get:^(WGCollection *collection, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [WGSpinnerView removeDancingGFromCenterView:self.view];
            strongSelf.fetching = NO;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            if (strongSelf.suggestions) {
                [strongSelf.everyone addObjectsFromCollection:collection notInCollection:strongSelf.suggestions];
            }
            strongSelf.everyone = collection;
            strongSelf.users = strongSelf.everyone;
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}

- (void) fetchEveryone {
    if (self.fetching) return;
    if (!self.everyone.hasNextPage.boolValue) return;
    self.fetching = YES;
    __weak typeof(self) weakSelf = self;
    [self.everyone getNextPage:^(WGCollection *collection, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            strongSelf.fetching = NO;
            [WGSpinnerView removeDancingGFromCenterView:self.view];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            if (strongSelf.suggestions) {
                [strongSelf.everyone addObjectsFromCollection:collection notInCollection:strongSelf.suggestions];
            } else {
                [strongSelf.everyone addObjectsFromCollection:collection notInCollection:strongSelf.everyone];
            }
            strongSelf.everyone.hasNextPage = collection.hasNextPage;
            strongSelf.everyone.nextPage = collection.nextPage;
            strongSelf.users = strongSelf.everyone;
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}

-(void) fetchFirstPageFollowers {
    if (self.fetching) return;
    self.fetching = YES;
    [WGSpinnerView addDancingGToCenterView:self.view];
    __weak typeof(self) weakSelf = self;
    [WGFollow getFollowsForFollow:self.user withHandler:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.fetching = NO;
            [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.followers = collection;
            strongSelf.users = [[WGCollection alloc] initWithType:[WGUser class]];
            for (WGFollow *follow in strongSelf.followers) {
                [strongSelf.users addObject:follow.user];
            }
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}

-(void) fetchFollowers {
    if (self.fetching) return;
    if (!self.followers.hasNextPage.boolValue) return;
    self.fetching = YES;
    __weak typeof(self) weakSelf = self;
    [self.followers addNextPage:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.fetching = NO;
            [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.users = [[WGCollection alloc] initWithType:[WGUser class]];
            for (WGFollow *follow in strongSelf.followers) {
                [strongSelf.users addObject:follow.user];
            }
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];

}


#pragma mark - UISearchBarDelegate 

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(searchText.length != 0) {
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.3
     cancelPreviousRequest:YES];
    } else {
        self.isSearching = NO;
        self.users = NetworkFetcher.defaultGetter.suggestions;
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
                strongSelf.fetching = NO;
                [WGSpinnerView removeDancingGFromCenterView:self.view];
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    return;
                }
                strongSelf.isSearching = YES;
                strongSelf.users = collection;
                [strongSelf.tableViewOfPeople reloadData];
            });
        }];
    }
}

- (void) getNextPageForFilteredContent {
    __weak typeof(self) weakSelf = self;
    [self.filteredUsers addNextPage:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}

@end

@implementation TablePersonCell

+ (CGFloat) height {
    return PEOPLEVIEW_HEIGHT_OF_CELLS + 10;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [PeopleCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.lineView = [[UIImageView alloc] initWithFrame:CGRectMake(0, PEOPLEVIEW_HEIGHT_OF_CELLS + 9 - 1, self.contentView.frame.size.width, 1)];
    self.lineView.backgroundColor = RGBAlpha(184, 184, 184, 0.3f);
    [self.contentView addSubview:self.lineView];
    
    self.spinnerView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinnerView.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    self.spinnerView.center = self.contentView.center;
    [self.contentView addSubview:self.spinnerView];
    
    self.profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 30, self.contentView.frame.size.width - 15 - 79 - 15, 60)];
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    [self.profileButton addSubview:self.profileImageView];
    [self.contentView addSubview:self.profileButton];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 15, 150, 20)];
    self.nameLabel.font = [FontProperties mediumFont:15.0f];
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.userInteractionEnabled = YES;
    [self.contentView addSubview:self.nameLabel];
    
    self.mutualFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 38, 150, 20)];
    self.mutualFriendsLabel.font = [FontProperties lightFont:13.0f];
    self.mutualFriendsLabel.textColor = RGB(181, 181, 181);
    [self.contentView addSubview:self.mutualFriendsLabel];
    
    self.orangeNewView = [[UIView alloc] initWithFrame:CGRectMake(6, 6, 12, 12)];
    self.orangeNewView.backgroundColor = [FontProperties getOrangeColor];
    self.orangeNewView.layer.cornerRadius = self.orangeNewView.frame.size.width/2;
    self.orangeNewView.layer.borderColor = UIColor.clearColor.CGColor;
    self.orangeNewView.layer.borderWidth = 1.0f;
    self.orangeNewView.hidden = YES;
    [self.contentView addSubview:self.orangeNewView];
}

- (void)setUser:(WGUser *)user {
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text =  user.fullName;
    self.mutualFriendsLabel.text = @"37 mutual friends";
}

@end

@implementation PeopleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    [super setup];
    self.followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.contentView.frame.size.width - 15 - 75, PEOPLEVIEW_HEIGHT_OF_CELLS / 2 - 23, 75, 47)];
    [self.contentView addSubview:self.followPersonButton];
}

- (void)setUser:(WGUser *)user {
    super.user = user;
    self.followPersonButton.backgroundColor = UIColor.clearColor;
    if (user.gender == FEMALE) {
        [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"womanFollowPersonIcon"] forState:UIControlStateNormal];
    }
    else {
        [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    }    [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
    
    if (!user.isCurrentUser) {
        self.followPersonButton.hidden = NO;
        if (user.state == BLOCKED_USER_STATE) {
            [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [self.followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
            [self.followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            self.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            self.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.followPersonButton.layer.borderWidth = 1;
            self.followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            self.followPersonButton.layer.cornerRadius = 8;
        } else {
            if ([user.isFollowing boolValue]) {
                [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
            }
            if (user.state == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
                [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
                [self.followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
                [self.followPersonButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
                self.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
                self.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                self.followPersonButton.backgroundColor = RGB(223, 223, 223);
                self.followPersonButton.layer.borderWidth = 1;
                self.followPersonButton.layer.borderColor = UIColor.clearColor.CGColor;
                self.followPersonButton.layer.cornerRadius = 8;
            }
        }
    }
    else {
        self.followPersonButton.hidden = YES;
    }
}

@end

@implementation FollowPeopleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setup {
    [super setup];
    
    self.acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 74 - 20, 0, 37, 37)];
    [self.acceptButton setImage:[UIImage imageNamed:@"acceptButton"] forState:UIControlStateNormal];
    self.acceptButton.center = CGPointMake(self.acceptButton.center.x, self.contentView.center.y);
    [self.acceptButton addTarget:self action:@selector(acceptPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.acceptButton];
    
    self.rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 37 - 10, 0, 37, 37)];
    [self.rejectButton setImage:[UIImage imageNamed:@"rejectButton"] forState:UIControlStateNormal];
    self.rejectButton.center = CGPointMake(self.rejectButton.center.x, self.contentView.center.y);
    [self.rejectButton addTarget:self action:@selector(rejectPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.rejectButton];
}

- (void)acceptPressed {
    [WGProfile.currentUser acceptFollowRequestForUser:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
        }
    }];
}

- (void)rejectPressed {
    [WGProfile.currentUser rejectFollowRequestForUser:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionDelete];
        }
    }];
}

- (void)setUser:(WGUser *)user {
    super.user = user;
    if (user.id.intValue > WGProfile.currentUser.lastUserRead.intValue) {
        self.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    }
}

@end
