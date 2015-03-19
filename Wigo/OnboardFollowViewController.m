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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    self.continueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 54, self.view.frame.size.width, 54)];
    [self.continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [self.continueButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    self.continueButton.titleLabel.font = [FontProperties getBigButtonFont];
    self.continueButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    self.continueButton.layer.borderWidth = 1.0f;
    [self.continueButton addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventTouchDown];
    
    self.rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeRightArrow"]];
    self.rightArrowImageView.frame = CGRectMake(self.continueButton.frame.size.width - 35, 27 - 9, 11, 18);
    [self.continueButton addSubview:self.rightArrowImageView];
    [self.view addSubview:self.continueButton];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return PEOPLEVIEW_HEIGHT_OF_CELLS;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.presentedUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OnboardCell *cell = [tableView dequeueReusableCellWithIdentifier:kOnboardCellName forIndexPath:indexPath];
    cell.labelName.text = @"";
    cell.profileImageView.image = nil;
    if (self.presentedUsers.count == 0) return cell;
    
    if (indexPath.row == self.presentedUsers.count - 1) [self getNextPage];
    
    WGUser *user = [self getUserAtIndex:(int)indexPath.row];
    cell.user = user;
    cell.followPersonButton.tag = indexPath.row;
    [cell.followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

-(WGUser *) getUserAtIndex:(int)index {
    WGUser *user;
    int sizeOfArray = (int)self.presentedUsers.count;
    if (sizeOfArray > 0 && sizeOfArray > index)
        user = (WGUser *)[self.presentedUsers objectAtIndex:index];
    return user;
}



- (void) followedPersonPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int row = buttonSender.tag;
    WGUser *user = (WGUser *)[self.presentedUsers objectAtIndex:buttonSender.tag];
    
    // If it's blocked
    if (user.isBlocked.boolValue) {
        user.isBlocked = @NO;
        [WGProfile.currentUser unblock:user withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionDelete];
            }
        }];
    }
    else {
        if (user.isFollowing.boolValue || user.isFollowingRequested.boolValue) {
            // If it's following user
            user.isFollowing = @NO;
            user.isFollowingRequested = @NO;
            [WGProfile.currentUser unfollow:user withHandler:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] logError:error forAction:WGActionDelete];
                }
            }];
            
        }
        else  {
            if (user.privacy == PRIVATE) {
                // If it's not following and it's private
                user.isFollowingRequested = @YES;
            } else {
                // If it's not following and it's public
                user.isFollowing = @YES;
            }
            [WGProfile.currentUser follow:user withHandler:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] logError:error forAction:WGActionPost];
                }
            }];
        }
    }
    
    [self.presentedUsers replaceObjectAtIndex:row withObject:user];
    [self.tableViewOfPeople reloadData];
}

- (void)continuePressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Keyboad notification handlers

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [searchBar endEditing:YES];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect kbFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.continueButton.frame = CGRectMake(0, kbFrame.origin.y - 50, self.view.frame.size.width, 50);
    int sizeOfContinueButton = (self.continueButton.isHidden) ? 0 : 50;
    self.tableViewOfPeople.frame = CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 104 - sizeOfContinueButton);
}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect kbFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.continueButton.frame = CGRectMake(0, kbFrame.origin.y - 50, self.view.frame.size.width, 50);
    self.rightArrowImageView.frame = CGRectMake(self.continueButton.frame.size.width - 35, self.continueButton.frame.size.height/2 - 7, 7, 14);
    int sizeOfContinueButton = (self.continueButton.isHidden) ? 0 : 50;
    self.tableViewOfPeople.frame = CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 104 - kbFrame.size.height - sizeOfContinueButton);
}

#pragma mark - Network functions

- (void)fetchFirstPageEveryone {
    [WGSpinnerView addDancingGToCenterView:self.view];
    [self fetchEveryone];
}

- (void) fetchEveryone {
    __weak typeof(self) weakSelf = self;
    [WGUser getOnboarding:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [WGSpinnerView removeDancingGFromCenterView:self.view];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.users = collection;
            strongSelf.presentedUsers = strongSelf.users;
            [strongSelf.tableViewOfPeople reloadData];
        });
    }];
}

- (void) getNextPage {
    if (!self.isFetching) {
        self.isFetching = YES;
        __weak typeof(self) weakSelf = self;
        if (self.presentedUsers.hasNextPage.boolValue) {
            [self.presentedUsers addNextPage:^(BOOL success, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong typeof(self) strongSelf = weakSelf;
                    strongSelf.isFetching = NO;
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
    
}


#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchIconImageView.hidden = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if ([searchBar.text isEqualToString:@""]) {
        [UIView animateWithDuration:0.01 animations:^{
        }  completion:^(BOOL finished){
            searchIconImageView.hidden = NO;
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if([searchText length] != 0) {
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.25
     cancelPreviousRequest:YES];
    } else {
        self.presentedUsers = self.users;
        [self.tableViewOfPeople reloadData];
        [self fetchEveryone];
    }
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
            strongSelf.presentedUsers = collection;
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
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
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

-(void) setUser:(WGUser *)user {
    _user = user;
    
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.labelName.text = user.fullName;
    [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
    
    if (user.isCurrentUser) {
        [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
        return;
    }
    
    if (user.state == BLOCKED_USER_STATE) {
        [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
        [self.followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
        self.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
        self.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.followPersonButton.layer.borderWidth = 1;
        self.followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
        self.followPersonButton.layer.cornerRadius = 3;
    } else {
        if (user.isFollowing.boolValue) {
            [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
            [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
        }
        else if (user.state == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
            [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [self.followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
            [self.followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
            self.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            self.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.followPersonButton.layer.borderWidth = 1;
            self.followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            self.followPersonButton.layer.cornerRadius = 3;
        }
    }

}
@end