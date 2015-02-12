//
//  ReferalViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/5/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "ReferalViewController.h"
#import "Globals.h"
@interface ReferalViewController ()
@property (nonatomic, strong) UIButton *continueButton;
@property (nonatomic, strong) UIImageView *rightArrowImageView;

@end

UISearchBar *searchBar;
UIImageView *searchIconImageView;

@implementation ReferalViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = UIColor.whiteColor;
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
    [self initializeContinueButton];
    [self initializeTableOfPeople];
    [self fetchFirstPageEveryone];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Referal View"];
}


- (void)initializeTitle {
    UILabel *whoReferredYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, self.view.frame.size.width, 28)];
    whoReferredYouLabel.text = @"Who Referred you?";
    whoReferredYouLabel.textColor = [FontProperties getOrangeColor];
    whoReferredYouLabel.font = [FontProperties getTitleFont];
    whoReferredYouLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:whoReferredYouLabel];
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
    int sizeOfContinueButton = (_continueButton.isHidden) ? 0 : 50;
    self.tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 104 - sizeOfContinueButton)];
    [self.tableViewOfPeople registerClass:[ReferalPeopleCell class] forCellReuseIdentifier:kReferalPeopleCellName];
    self.tableViewOfPeople.delegate = self;
    self.tableViewOfPeople.dataSource = self;
    self.tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableViewOfPeople];
    [self.view sendSubviewToBack:self.tableViewOfPeople];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [searchBar endEditing:YES];
    searchIconImageView.hidden = YES;
}

- (void)initializeContinueButton {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    _continueButton = [UIButton new];
    _continueButton.backgroundColor = RGB(252, 221, 187);
    [_continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [_continueButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _continueButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    [_continueButton addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventTouchUpInside];
    _continueButton.hidden = YES;
    [self.view addSubview:_continueButton];
    
    _continueButton.frame = CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50);
    _rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightArrow"]];
    _rightArrowImageView.frame = CGRectMake(_continueButton.frame.size.width - 35, _continueButton.frame.size.height/2 - 7, 7, 14);
    [_continueButton addSubview:_rightArrowImageView];
    
    UIButton *skipButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 40)];
    [skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    [skipButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    skipButton.titleLabel.font = [FontProperties getTitleFont];
    [skipButton addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:skipButton];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect kbFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _continueButton.frame = CGRectMake(0, kbFrame.origin.y - 50, self.view.frame.size.width, 50);
    int sizeOfContinueButton = (_continueButton.isHidden) ? 0 : 50;
    self.tableViewOfPeople.frame = CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 104 - sizeOfContinueButton);
}


- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect kbFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _continueButton.frame = CGRectMake(0, kbFrame.origin.y - 50, self.view.frame.size.width, 50);
    _rightArrowImageView.frame = CGRectMake(_continueButton.frame.size.width - 35, _continueButton.frame.size.height/2 - 7, 7, 14);
    int sizeOfContinueButton = (_continueButton.isHidden) ? 0 : 50;
    self.tableViewOfPeople.frame = CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 104 - kbFrame.size.height - sizeOfContinueButton);
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [ReferalPeopleCell height];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSearching) {
        int hasNextPage = ([self.filteredUsers.hasNextPage boolValue] ? 1 : 0);
        return self.filteredUsers.count + hasNextPage;
    } else {
        int hasNextPage = ([self.users.hasNextPage boolValue] ? 1 : 0);
        return self.users.count + hasNextPage;
    }
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.chosenIndexPath = indexPath;
    _continueButton.hidden = NO;
    _continueButton.backgroundColor = [FontProperties getOrangeColor];
    searchIconImageView.hidden = YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReferalPeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:kReferalPeopleCellName forIndexPath:indexPath];
    cell.profileImageView.image = nil;
    cell.labelName.text = @"";
    cell.groupName.text = @"";
    if (self.users.count == 0) return cell;
    if (self.isSearching) {
        if (indexPath.row == self.filteredUsers.count) {
            [self getNextPageForFilteredContent];
            return cell;
        }
    }
    else {
        if (indexPath.row == self.users.count) {
            [self fetchEveryone];
            return cell;
        }
    }
   
    WGUser *user = [self getUserAtIndex:(int)indexPath.row];
    [cell.profileImageView setSmallImageForUser:user completed:nil];
    cell.labelName.text = user.fullName;
    cell.groupName.text = user.group.name;
    return cell;
}

-(WGUser *) getUserAtIndex:(int)index {
    WGUser *user;
    if (self.isSearching) {
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


- (void)continuePressed {
    [self saveReferal];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void) saveReferal {
    WGUser *referredUser = [self getUserAtIndex:(int)self.chosenIndexPath.row];
    if (referredUser.id) {
        [WGProfile.currentUser setReferredBy:referredUser.id];
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                return;
            }
        }];
    }
}

#pragma mark - Network functions

- (void)fetchFirstPageEveryone {
    [self fetchEveryone];
}

- (void) fetchEveryone {
    __weak typeof(self) weakSelf = self;
    if (!self.users) {
        [WGSpinnerView addDancingGToCenterView: self.view];
        [WGUser getReferals:^(WGCollection *collection, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [WGSpinnerView removeDancingGFromCenterView: self.view];
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

- (void) getNextPageForFilteredContent {
    __weak typeof(self) weakSelf = self;
    if ([self.filteredUsers.hasNextPage boolValue]) {
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
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchIconImageView.hidden = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (![searchBar.text isEqualToString:@""]) {
        [UIView animateWithDuration:0.01 animations:^{
            searchIconImageView.transform = CGAffineTransformMakeTranslation(-62,0);
        }  completion:^(BOOL finished){
            searchIconImageView.hidden = NO;
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(searchText.length != 0) {
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.2
     cancelPreviousRequest:YES];
    } else {
        self.isSearching = NO;
        [self.tableViewOfPeople reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performBlock:^(void){[self searchTableList];}
            afterDelay:0.2
 cancelPreviousRequest:YES];
}

- (void)searchTableList {
    NSString *oldString = searchBar.text;
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    NSString *endpoint = [WGApi getStringWithEndpoint:@"users/" andArguments:@{ @"context": @"referral", @"text" : searchString, @"id__ne" : WGProfile.currentUser.id }];
    self.lastSearchString = [WGApi getUrlStringForEndpoint:endpoint];

    __weak typeof(self) weakSelf = self;
    [WGUser searchReferals:searchString withHandler:^(NSURL *urlSent, WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSearch retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionSearch];
                return;
            }
            if ([strongSelf.lastSearchString isEqual:urlSent.absoluteString]) {
                strongSelf.isSearching = YES;
                strongSelf.filteredUsers = collection;
                [strongSelf.tableViewOfPeople reloadData];
            }
        });
    }];
}


@end

@implementation ReferalPeopleCell

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
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [ReferalPeopleCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = [UIColor whiteColor];

    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, [ReferalPeopleCell height]/2 - 30, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.profileImageView];
    
    self.labelName = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, [UIScreen mainScreen].bounds.size.width - 85 - 15, 20)];
    self.labelName.font = [FontProperties mediumFont:18.0f];
    self.labelName.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.labelName];
    
    self.groupName = [[UILabel alloc] initWithFrame:CGRectMake(85, 30, [UIScreen mainScreen].bounds.size.width - 85 - 15, 20)];
    self.groupName.font = [FontProperties mediumFont:17.0f];
    self.groupName.textColor = RGB(200, 200, 200);
    self.groupName.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.groupName];
}



@end