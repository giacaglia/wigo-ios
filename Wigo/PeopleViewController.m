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
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface PeopleViewController () <FBSDKAppInviteDialogDelegate>
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
    // Title setup
    [self initializeBackBarButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserAtTable:) name:@"updateUserAtTable" object:nil];
    [self initializeTableOfPeople];
}


-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    self.lastUserRead = WGProfile.currentUser.lastUserRead;
    if (!didProfileSegue) {
        if (!self.currentTab) self.currentTab = @2;
        [self loadTableView];
    }
    if ([self.currentTab isEqualToNumber:@2]) {
        [WGAnalytics tagView:@"school_people"];
    }
    else if ([self.currentTab isEqualToNumber:@3]) {
        [WGAnalytics tagView:@"friends"];
    }
    self.title = self.user.firstName;
    [self initializeRightBarButton];
    didProfileSegue = NO;
    userIndex = [NSIndexPath indexPathForRow:-1 inSection:1];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.title = self.user.firstName;
    [self initializeRightBarButton];

}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.currentTab isEqual:@2]) {
        for (WGUser *user in self.friendRequestUsers) {
            user.isFriendRequestRead = YES;
        }
    }
    [TabBarAuxiliar clearIndex:kIndexOfFriends];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.tabBarController.navigationItem.leftBarButtonItem = nil;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
}

- (void)initializeBackBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"whiteBackIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) initializeRightBarButton {
    if ([self.currentTab isEqual:@2]) {
        UIButtonAligned *inviteButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 40, 16) andType:@3];
        [inviteButton setTitle:@"Invite" forState:UIControlStateNormal];
        [inviteButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        inviteButton.titleLabel.textAlignment = NSTextAlignmentRight;
        [inviteButton addTarget:self action:@selector(invitePressed)
                forControlEvents:UIControlEventTouchUpInside];
        inviteButton.titleLabel.font = [FontProperties mediumFont:13.0f];
        self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:inviteButton];
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)followChoosePerson:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    if (tag >= self.friendRequestUsers.count) return;
    WGUser *user = (WGUser *)[self.friendRequestUsers objectAtIndex:tag];
    [self presentUser:user];
}

-(void) choosePerson:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGUser *user = [self getUserAtIndex:tag];
    if (!user) return;
    didProfileSegue = YES;
    userIndex = [NSIndexPath indexPathForRow:tag inSection:1];
    [self presentUser:user];
}

-(void) presentUser:(WGUser *)user {
    ProfileViewController *profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    profileViewController.user = user;
    [self.navigationController pushViewController:profileViewController animated:YES];
}


- (void)initializeTableOfPeople {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 20)];
    if ([self.currentTab isEqual:@2]) {
        self.tableViewOfPeople.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 108 + 44);
    }
    [self.tableViewOfPeople registerClass:[PeopleCell class] forCellReuseIdentifier:kPeopleCellName];
    [self.tableViewOfPeople registerClass:[FollowPeopleCell class] forCellReuseIdentifier:kFollowPeopleCell];
    [self.tableViewOfPeople registerClass:[SeeMoreCell class] forCellReuseIdentifier:kSeeMoreCellName];
    self.tableViewOfPeople.delegate = self;
    self.tableViewOfPeople.dataSource = self;
    self.tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableViewOfPeople.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableViewOfPeople.showsVerticalScrollIndicator = NO;
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, 50)];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"Search by Name";
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44 + 50)];
    [headerView addSubview:_searchBar];
    self.tableViewOfPeople.tableHeaderView = headerView;
    self.tableViewOfPeople.contentOffset = CGPointMake(0, 50);
    [self.view addSubview:self.tableViewOfPeople];
}


- (void)invitePressed  {
    FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:@"https://fb.me/847330831988239"];
    //optionally set previewImageURL
    content.previewImageURL = [NSURL URLWithString:@"http://www.wigo.us/static/img/logo.png"];
    
    // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
    [FBSDKAppInviteDialog showWithContent:content
                                 delegate:self];
    
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog
 didCompleteWithResults:(NSDictionary *)result {
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog
       didFailWithError:(NSError *)error {
    
}
#pragma mark - Filter handlers


- (void)loadTableView {
    self.navigationItem.titleView = nil;
    if ([self.currentTab isEqualToNumber:@2]) {
        [self fetchFirstPageSuggestions];
        [self fetchFirstPageFriendRequests];
    }
    else if ([self.currentTab isEqualToNumber:@3]) {
        [self fetchFirstPageFriends];
    }
}

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.currentTab isEqualToNumber:@2])  {
            if (indexPath.row == self.friendRequestUsers.count) {
                return [SeeMoreCell height];
            }
            return [TablePersonCell height];
        }
        else if ([self.currentTab isEqualToNumber:@3]) return [TablePersonCell height];
    }
    return [TablePersonCell height];
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
        return self.friendRequestUsers.count;
    }
    else return (int)self.users.count + self.users.hasNextPage.intValue;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionFollowPeople && [self.currentTab isEqual:@2]) {
        if (indexPath.row == self.friendRequestUsers.count) {
            SeeMoreCell *seeMoreCell = [tableView dequeueReusableCellWithIdentifier:kSeeMoreCellName forIndexPath:indexPath];
            return seeMoreCell;
        }
        else {
            FollowPeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:kFollowPeopleCell forIndexPath:indexPath];
            WGUser *user = (WGUser *)[self.friendRequestUsers objectAtIndex:indexPath.item];
            if (!user) return cell;
            cell.user = user;
            [cell.acceptButton addTarget:self
                                              action:@selector(acceptPressed:)
                                    forControlEvents:UIControlEventTouchUpInside];
            [cell.rejectButton addTarget:self
                                              action:@selector(rejectPressed:)
                                    forControlEvents:UIControlEventTouchUpInside];
            cell.profileButton.tag = (int)indexPath.row;
            [cell.profileButton addTarget:self action:@selector(followChoosePerson:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
    }
    PeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:kPeopleCellName forIndexPath:indexPath];
    cell.contentView.frame = CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tableView heightForRowAtIndexPath:indexPath]);

    int tag = (int)indexPath.row;
    if (tag == self.users.count - 5) {
        [self fetchNextPage];
    }
    if (tag == self.users.count) {
        [self fetchNextPage];
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
   
    cell.followPersonButton.tag = tag;
    [cell.followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.profileButton.tag = tag;
    [cell.profileButton addTarget:self action:@selector(choosePerson:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.currentTab isEqual:@2]
        && indexPath.section == kSectionFollowPeople &&
        indexPath.row == self.friendRequestUsers.count) {
        self.friendRequestUsers.hasNextPage = @0;
        for (int i = 0; i < 2; i++) {
            [self.friendRequestUsers addObject:WGProfile.currentUser];
        }
        [self.tableViewOfPeople reloadData];
    }
    return;
}


-(CGFloat) tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    if (self.isSearching) return 0;
    if ([self.currentTab isEqual:@2]) {
        if (section == 0 && self.friendRequestUsers.count == 0) return 0;
        return 30.0f;
    }
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
//    CGRect frame = self.navigationController.navigationBar.frame;
//    frame = CGRectMake(frame.origin.x, frame.origin.y + 50, frame.size.width, frame.size.height);
//    CGFloat size = frame.size.height - 20;
//    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
//    CGFloat scrollOffset = scrollView.contentOffset.y;
//    CGFloat scrollDiff = scrollOffset - self.previousScrollViewYOffset;
//    CGFloat scrollHeight = scrollView.frame.size.height;
//    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;
//    
//    if (scrollOffset <= -scrollView.contentInset.top) {
//        frame.origin.y = 20;
//    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
//        frame.origin.y = -size;
//    } else {
//        // HACK to prevent the app to go up and down.
//        if (frame.origin.y == 20 && scrollOffset == - 60) {
//            frame.origin.y = 20;
//        }
//        else {
//            frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
//        }
//    }
//    
//    self.navigationController.navigationBar.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
//    
//    if (self.navigationController.navigationBar.frame.origin.y +
//        self.navigationController.navigationBar.frame.size.height <= 20 ||
//        self.navigationController.navigationBar.frame.origin.y >= 0) {
//        self.blueBannerView.hidden = NO;
//    }
//    else {
//        super.blueBannerView.hidden = YES;
//    }
//    
//    [super updateBarButtonItems:(1 - framePercentageHidden)];
//    self.previousScrollViewYOffset = scrollOffset;
//    if (scrollView.contentOffset.x != 0) {
//        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
//    }
}

- (void) followedPersonPressed:(id)sender {
///TODO: UPDATE THE NUMBER OF USERS BEING FOLLOWED BY THE PROFILE.USER
    UIButton *buttonSender = (UIButton *)sender;
    int row = (int)buttonSender.tag;
    WGUser *user = (WGUser *)[self.users objectAtIndex:buttonSender.tag];
    [user followUser];
    [self.users replaceObjectAtIndex:row withObject:user];
    [self.tableViewOfPeople reloadData];
}

- (void)acceptPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    WGUser *user = (WGUser *)[self.friendRequestUsers objectAtIndex:buttonSender.tag];
    user.isFriend = @YES;
    [WGProfile.currentUser acceptFriendRequestFromUser:user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            user.isFriend = nil;
            user.friendRequest = kFriendRequestReceived;
        }
    }];
    [self.friendRequestUsers replaceObjectAtIndex:buttonSender.tag withObject:user];
    [self.tableViewOfPeople reloadData];
}
//

- (void)rejectPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    WGUser *user = (WGUser *)[self.friendRequestUsers objectAtIndex:buttonSender.tag];
    user.isFriend = @NO;
    user.friendRequest = nil;
    [WGProfile.currentUser rejectFriendRequestForUser:user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            user.isFriend = nil;
            user.friendRequest = kFriendRequestReceived;
        }
    }];
    [self.friendRequestUsers replaceObjectAtIndex:buttonSender.tag withObject:user];
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

- (void)fetchFirstPageSuggestions {
    if (self.fetching) return;
    self.fetching = YES;
    __weak typeof(self) weakSelf = self;
    [WGSpinnerView addDancingGToCenterView:self.view];
    [WGUser getSuggestions:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        strongSelf.fetching = NO;
        if (error) return;
        strongSelf.users = collection;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.tableViewOfPeople reloadData];
        });
    }];
}

- (void)fetchNextPage {
    if (!self.users) return;
    if (!self.users.nextPage) return;
    self.fetching = YES;
    __weak typeof(self) weakSelf = self;
    [self.users addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (error) return;
        strongSelf.fetching = NO;
        [strongSelf.tableViewOfPeople reloadData];
    }];
}

-(void) fetchFirstPageFriends {
    if (self.fetching) return;
    self.fetching = YES;
    [WGSpinnerView addDancingGToCenterView:self.view];
    __weak typeof(self) weakSelf = self;
    [self.user getFriends:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.fetching = NO;
            [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.users = collection;
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}

-(void) fetchFirstPageFriendRequests {
    __weak typeof(self) weakSelf = self;
    [WGProfile.currentUser getFriendRequests:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.friendRequestUsers = collection;
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
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [TablePersonCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.lineView = [[UIImageView alloc] initWithFrame:CGRectMake(0, [TablePersonCell height] - 0.5, self.contentView.frame.size.width, 0.5)];
    self.lineView.backgroundColor = RGBAlpha(184, 184, 184, 0.3f);
    [self.contentView addSubview:self.lineView];
    
    self.spinnerView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinnerView.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    self.spinnerView.center = self.contentView.center;
    [self.contentView addSubview:self.spinnerView];
    
    self.profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, self.contentView.frame.size.width - 15 - 79 - 15, 60)];
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    [self.profileButton addSubview:self.profileImageView];
    self.profileButton.center = CGPointMake(self.profileButton.center.x, self.center.y);
    [self.contentView addSubview:self.profileButton];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 15, 150, 20)];
    self.nameLabel.font = [FontProperties mediumFont:15.0f];
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.userInteractionEnabled = NO;
    [self.profileButton addSubview:self.nameLabel];
    
    self.mutualFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 38, 150, 20)];
    self.mutualFriendsLabel.font = [FontProperties lightFont:13.0f];
    self.mutualFriendsLabel.textColor = RGB(181, 181, 181);
    [self.profileButton addSubview:self.mutualFriendsLabel];
    
    self.orangeNewView = [[UIView alloc] initWithFrame:CGRectMake(6, 6, 12, 12)];
    self.orangeNewView.backgroundColor = [FontProperties getOrangeColor];
    self.orangeNewView.layer.cornerRadius = self.orangeNewView.frame.size.width/2;
    self.orangeNewView.layer.borderColor = UIColor.clearColor.CGColor;
    self.orangeNewView.layer.borderWidth = 1.0f;
    [self.contentView addSubview:self.orangeNewView];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text =  user.fullName;
    if (user.numMutualFriends) {
        self.mutualFriendsLabel.text = [NSString stringWithFormat:@"%@ mutual friends", user.numMutualFriends];
    }
    
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
    self.followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.contentView.frame.size.width - 15 - 52, [TablePersonCell height] / 2 - 19, 52, 38)];
    self.orangeNewView.hidden = YES;
    [self.contentView addSubview:self.followPersonButton];
}

- (void)setUser:(WGUser *)user {
    super.user = user;
    self.followPersonButton.backgroundColor = UIColor.clearColor;
    [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
    if (user.isCurrentUser) {
        self.followPersonButton.hidden = YES;
        return;
    }
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
        return;
    }
    if (user.state == FRIEND_USER_STATE) {
        [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
        [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
        return;
    }
    if (user.state == SENT_OR_RECEIVED_REQUEST_USER_STATE) {
        [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
        [self.followPersonButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
        self.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.followPersonButton.backgroundColor = RGB(223, 223, 223);
        self.followPersonButton.layer.borderWidth = 1;
        self.followPersonButton.layer.borderColor = UIColor.clearColor.CGColor;
        self.followPersonButton.layer.cornerRadius = 8;
        return;
    }
}

@end

@implementation SeeMoreCell

+(CGFloat) height {
    return 30;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [SeeMoreCell height]);
    self.contentView.frame = self.frame;
    
    UILabel *seeMoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
    seeMoreLabel.text = @"See More";
    seeMoreLabel.textColor = [FontProperties getBlueColor];
    seeMoreLabel.font = [FontProperties mediumFont:16.0f];
    seeMoreLabel.center = self.center;
    seeMoreLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:seeMoreLabel];
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
    
    self.acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 74 - 15, 0, 37, 37)];
    UIImageView *acceptImgView = [[UIImageView alloc] initWithFrame:CGRectMake(8.5, 8.5, 20, 20)];
    acceptImgView.image = [UIImage imageNamed:@"acceptButton"];
    [self.acceptButton addSubview:acceptImgView];
    self.acceptButton.center = CGPointMake(self.acceptButton.center.x, self.contentView.center.y);
    [self.contentView addSubview:self.acceptButton];
    
    self.rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 37 - 10, 0, 37, 37)];
    UIImageView *rejectImgView = [[UIImageView alloc] initWithFrame:CGRectMake(8.5, 8.5, 20, 20)];
    rejectImgView.image = [UIImage imageNamed:@"rejectButton"];
    [self.rejectButton addSubview:rejectImgView];
    self.rejectButton.center = CGPointMake(self.rejectButton.center.x, self.contentView.center.y);
    [self.contentView addSubview:self.rejectButton];
    
    self.followPersonButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 15 - 52, [TablePersonCell height] / 2 - 19, 52, 38)];
    self.followPersonButton.hidden = YES;
    [self.contentView addSubview:self.followPersonButton];
}



- (void)setUser:(WGUser *)user {
    super.user = user;
    self.orangeNewView.hidden = user.isFriendRequestRead;
    self.acceptButton.hidden = YES;
    self.rejectButton.hidden = YES;
    self.followPersonButton.hidden = YES;

    if (!user.isFriend) {
        self.acceptButton.hidden = NO;
        self.rejectButton.hidden = NO;
        return;
    }
    if (!user.isFriend.boolValue) {
        [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"]
                                           forState:UIControlStateNormal];
        self.followPersonButton.hidden = NO;
        return;
    }
    if (user.isFriend.boolValue) {
        [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"]
                                           forState:UIControlStateNormal];
        self.followPersonButton.hidden = NO;
        return;
    }
    
}

@end
