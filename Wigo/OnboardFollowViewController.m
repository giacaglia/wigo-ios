//
//  OnboardFollowViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 8/11/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "OnboardFollowViewController.h"
#import "Globals.h"
#import "RWBlurPopover.h"

UISearchBar *searchBar;
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
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeTitle];
    [self initializeTapHandler];
    [self initializeSearchBar];
    [self initializeTableOfPeople];
    [self initializeContinueButton];
    [self fetchFirstPageEveryone];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Onboard Follow View"];
}

- (void)initializeTitle {
    UILabel *emailConfirmationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, self.view.frame.size.width, 28)];
    emailConfirmationLabel.text = @"Follow Your Classmates";
    emailConfirmationLabel.textColor = [FontProperties getOrangeColor];
    emailConfirmationLabel.font = [FontProperties getTitleFont];
    emailConfirmationLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:emailConfirmationLabel];
}

- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tappedView:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)tappedView:(UITapGestureRecognizer*)tapSender {
    searchIconImageView.hidden = YES;
    [self.view endEditing:YES];
    [self searchBarTextDidEndEditing:searchBar];
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
    searchIconImageView.frame = CGRectMake(85, 13, 15, 16);
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
    self.tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 158)];
    [self.tableViewOfPeople registerClass:[OnboardCell class] forCellReuseIdentifier:kOnboardCellName];
    self.tableViewOfPeople.delegate = self;
    self.tableViewOfPeople.dataSource = self;
    self.tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableViewOfPeople];
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
        return [self.filteredUsers count];
    } else {
        int hasNextPage = ([self.users.hasNextPage boolValue] ? 1 : 0);
        return [self.users count] + hasNextPage;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OnboardCell *cell = [tableView dequeueReusableCellWithIdentifier:kOnboardCellName forIndexPath:indexPath];
    
    if (self.users.count == 0) return cell;
    if (indexPath.row == self.users.count) {
        [self fetchEveryone];
        return cell;
    }
    
    WGUser *user = [self getUserAtIndex:indexPath.row];
    
    [cell.profileImageView setSmallImageForUser:user completed:nil];
    cell.labelName.text = user.fullName;
    cell.labelName.tag = indexPath.row;
    
    if (![user isCurrentUser]) {
       
        [cell.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        cell.followPersonButton.tag = -100;
        [cell.followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([user.isFollowing boolValue]) {
            [cell.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
            cell.followPersonButton.tag = 100;
        }
        if (user.state == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
            [cell.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [cell.followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
            [cell.followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            cell.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            cell.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            cell.followPersonButton.layer.borderWidth = 1;
            cell.followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            cell.followPersonButton.layer.cornerRadius = 3;
            cell.followPersonButton.tag = 100;
        }
    }
    
    return cell;
}

-(WGUser *) getUserAtIndex:(int)index {
    WGUser *user;
    if (isSearching) {
        int sizeOfArray = (int)self.filteredUsers.count;
        if (sizeOfArray > 0 && sizeOfArray > index)
            user = (WGUser *)[self.filteredUsers objectAtIndex:index];
    } else {
        int sizeOfArray = (int)self.users.count;
        if (sizeOfArray > 0 && sizeOfArray > index)
            user = (WGUser *)[self.users objectAtIndex:index];
    }
    return user;
}

- (void) followedPersonPressed:(id)sender {
    //Get Index Path
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.tableViewOfPeople];
    NSIndexPath *indexPath = [self.tableViewOfPeople indexPathForRowAtPoint:buttonOriginInTableView];
    WGUser *user = [self getUserAtIndex:(int)indexPath.row];
    
    UIButton *senderButton = (UIButton*)sender;
    if (senderButton.tag == -100) {
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
            user.isFollowing = @YES;
        }
        senderButton.tag = 100;
        [[WGProfile currentUser] follow:user withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionPost];
            }
        }];
        [self.users replaceObjectAtIndex:[indexPath row] withObject:user];
    } else {
        [senderButton setTitle:nil forState:UIControlStateNormal];
        [senderButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
        senderButton.tag = -100;
        
        [[WGProfile currentUser] unfollow:user withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionDelete];
            }
        }];
        
        user.isFollowing = @NO;
        user.isFollowingRequested = @NO;
        [self.users replaceObjectAtIndex:[indexPath row] withObject:user];
    }
}

- (void)continuePressed {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
}

#pragma mark - Network functions

- (void)fetchFirstPageEveryone {
    [self fetchEveryone];
}

- (void) fetchEveryone {
    __weak typeof(self) weakSelf = self;
    if (!self.users) {
        [WGUser getOnboarding:^(WGCollection *collection, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    return;
                }
                strongSelf.users = collection;
                [strongSelf.tableViewOfPeople reloadData];
            });
        }];
    } else if ([self.users.hasNextPage boolValue]) {
        [self.users addNextPage:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    return;
                }
                [strongSelf.tableViewOfPeople reloadData];
            });
        }];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchIconImageView.hidden = YES;
    isSearching = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (![searchBar.text isEqualToString:@""]) {
        [UIView animateWithDuration:0.01 animations:^{
            searchIconImageView.transform = CGAffineTransformMakeTranslation(-62,0);
        }  completion:^(BOOL finished){
            searchIconImageView.hidden = NO;
        }];
    } else {
        [UIView animateWithDuration:0.01 animations:^{
            searchIconImageView.transform = CGAffineTransformMakeTranslation(0,0);
        }  completion:^(BOOL finished){
            searchIconImageView.hidden = NO;
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.filteredUsers removeAllObjects];
    
    if([searchText length] != 0) {
        isSearching = YES;
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.25
     cancelPreviousRequest:YES];
    } else {
        isSearching = NO;
    }
    [self.tableViewOfPeople reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performBlock:^(void){[self searchTableList];}
            afterDelay:0.25
 cancelPreviousRequest:YES];
}

- (void)searchTableList {
    NSString *oldString = searchBar.text;
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    __weak typeof(self) weakSelf = self;
    [WGUser searchUsers:searchString withHandler:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSearch retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionSearch];
                return;
            }
            strongSelf.filteredUsers = collection;
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}

@end


@implementation OnboardCell

+ (CGFloat) height {
    return  80;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [OnboardCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, [OnboardCell height]/2 - 30, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.profileImageView];
    
    self.labelName = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    self.labelName.font = [FontProperties mediumFont:18.0f];
    self.labelName.textAlignment = NSTextAlignmentLeft;
    self.labelName.userInteractionEnabled = YES;
    [self.contentView addSubview:self.labelName];
    
   self.followPersonButton = [[UIButton alloc]
                              initWithFrame:CGRectMake([UIScreen mainScreen
                                                                        ].bounds.size.width - 15 - 49, [OnboardCell height]/2 - 15, 49, 30)];
    [self.contentView addSubview:self.followPersonButton];
}

@end