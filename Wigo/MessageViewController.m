//
//  MessageViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MessageViewController.h"
#import "Globals.h"

#import "UIButtonAligned.h"

@interface MessageViewController ()

// Search Bar
@property UISearchBar *searchBar;
@property BOOL isSearching;
@property UIImageView *searchIconImageView;

// Table View
@property UITableView *tableView;
//@property NSArray *contentList;
@property NSNumber *page;
@property WGCollection *content;
@property WGCollection *filteredContent;

@end

int queryQueueInt;
BOOL isFetchingEveryone;

@implementation MessageViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    queryQueueInt = 0;
    _content = [[WGCollection alloc] initWithType:[WGUser class]];
    _filteredContent = [[WGCollection alloc] initWithType:[WGUser class]];
    isFetchingEveryone = NO;
    
    // Title setup
    [self initializeNavigationItem];
    [self initializeSearchBar];
    [self initializeTableListOfFriends];
    [self initializeTapHandler];
    [self fetchFirstPageEveryone];
}

- (void) initializeNavigationItem {
    self.navigationItem.titleView = nil;
    self.title = @"New Message";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};

    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 60, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;

    UIButtonAligned *searchButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 15, 16) andType:@2];
    [searchButton setBackgroundImage:[UIImage imageNamed:@"orangeSearchIcon"] forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(searchPressed)
           forControlEvents:UIControlEventTouchUpInside];
    [searchButton setShowsTouchWhenHighlighted:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"New Chat View"];
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

- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) initializeTableListOfFriends {
    self.automaticallyAdjustsScrollViewInsets = NO;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_tableView];
}

#pragma Network Functions

- (void) fetchFirstPageEveryone {
    [self fetchEveryone];
}

- (void) fetchEveryone {
    if (!isFetchingEveryone) {
        isFetchingEveryone = YES;
        __weak typeof(self) weakSelf = self;
        if (!_content || _content.hasNextPage == nil) {
            [WGUser getNotMe:^(WGCollection *collection, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong typeof(self) strongSelf = weakSelf;
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        return;
                    }
                    strongSelf.content = collection;
                    [strongSelf.tableView reloadData];
                    isFetchingEveryone = NO;
                });
            }];
        } else if ([_content.hasNextPage boolValue]) {
            [_content addNextPage:^(BOOL success, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong typeof(self) strongSelf = weakSelf;
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        return;
                    }
                    [strongSelf.tableView reloadData];
                    isFetchingEveryone = NO;
                });
            }];
        }
    }
}

#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isSearching) {
        return [_filteredContent count];
    }
    int hasNextPage = ([_content.hasNextPage boolValue] ? 1 : 0);
    return [_content count] + hasNextPage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if ([_content count] > 5) {
        if ([_content.hasNextPage boolValue] && [indexPath row] == [_content count] - 5) {
            [self fetchEveryone];
        }
    }
    if ([indexPath row] == [_content count] && [_content count] != 0) {
        [self fetchEveryone];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        spinner.center = cell.contentView.center;
        [cell.contentView addSubview:spinner];
        [spinner startAnimating];
        return cell;
    }
    
    WGUser *user;
    if (_isSearching) {
        if ([_filteredContent count] == 0) return cell;
        if ([indexPath row] < [_filteredContent count]) {
            user = (WGUser *)[_filteredContent objectAtIndex:[indexPath row]];
        }
        else return cell;
    } else {
        if ([_content count] == 0) return cell;
        if ([indexPath row] < [_content count]) {
            user = (WGUser *)[_content objectAtIndex:[indexPath row]];
        }
        else return cell;
    }
       
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:user.smallCoverImageURL imageArea:[user smallCoverImageArea]];
    [cell.contentView addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    textLabel.font = [FontProperties getSubtitleFont];
    [cell.contentView addSubview:textLabel];
    
    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 40, 150, 20)];
    goingOutLabel.font = [FontProperties mediumFont:13.0f];
    goingOutLabel.textAlignment = NSTextAlignmentLeft;
    if ([user.isGoingOut boolValue]) {
        goingOutLabel.text = @"Going Out";
        goingOutLabel.textColor = [FontProperties getOrangeColor];
    }
    [cell.contentView addSubview:goingOutLabel];
    
    return cell;
}

- (void) followedPerson:(id)sender {
    UIButton *senderButton = (UIButton*)sender;
    [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WGUser *user;
    if (_isSearching) {
        int sizeOfArray = (int)[_filteredContent count];
        if (sizeOfArray > 0 && sizeOfArray > [indexPath row])
            user = (WGUser *)[_filteredContent objectAtIndex:[indexPath row]];
    } else {
        int sizeOfArray = (int)[_content count];
        if (sizeOfArray > 0 && sizeOfArray > [indexPath row])
            user = (WGUser *)[_content objectAtIndex:[indexPath row]];
    }
    if (user) {
        self.conversationViewController = [[ConversationViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.conversationViewController animated:YES];
    }
}


#pragma mark - UISearchBar
- (void)initializeSearchBar {
    UIColor *grayColor = RGB(184, 184, 184);
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(11, 70, self.view.frame.size.width - 22, 30)];
    _searchBar.barTintColor = [UIColor whiteColor];
    _searchBar.tintColor = grayColor;
    _searchBar.placeholder = @"Search By Name";
    _searchBar.delegate = self;
    UITextField *searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:grayColor forKeyPath:@"_placeholderLabel.textColor"];
    
    // Search Icon Clear
    UITextField *txtSearchField = [_searchBar valueForKey:@"_searchField"];
    [txtSearchField setLeftViewMode:UITextFieldViewModeNever];
    
    // Add Custom Search Icon
    _searchIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"graySearchIcon"]];
    _searchIconImageView.frame = CGRectMake(40, 14, 14, 14);
    [_searchBar addSubview:_searchIconImageView];
    
    // Text when editing becomes orange
    for (UIView *subView in _searchBar.subviews) {
        for (UIView *secondLevelSubview in subView.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]])
            {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                searchBarTextField.textColor = grayColor;
            }
            else {
                [secondLevelSubview removeFromSuperview];
            }
        }
    }
}

- (void)searchPressed {
    self.navigationItem.leftBarButtonItem = nil;
    _searchBar.hidden = NO;
    self.navigationItem.titleView = _searchBar;
    [_searchBar becomeFirstResponder];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    UIButtonAligned *cancelButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@3];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action: @selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.textAlignment = NSTextAlignmentRight;
    cancelButton.titleLabel.font = [FontProperties getSubtitleFont];
    [cancelButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:cancelButton];
    self.navigationItem.rightBarButtonItem = barItem;
}

- (void)cancelPressed {
    [self.view endEditing:YES];
    _isSearching = NO;
    _searchBar.text = @"";
    [self searchBarTextDidEndEditing:_searchBar];
    [_tableView reloadData];
    [self initializeNavigationItem];
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
    [_filteredContent removeAllObjects];
    if([searchText length] != 0) {
        _isSearching = YES;
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.25
     cancelPreviousRequest:YES];
    } else {
        _isSearching = NO;
    }
    [_tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performBlock:^(void){[self searchTableList];}
            afterDelay:0.25
 cancelPreviousRequest:YES];
}

- (void)searchTableList {
    NSString *oldString = _searchBar.text;
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    __weak typeof(self) weakSelf = self;
    /* if ([oldString isEqualToString:@"Initiate meltdown"]) {
        [self showMeltdown];
    } */
    if (!_filteredContent || _filteredContent.hasNextPage == nil) {
        [WGUser searchNotMe:searchString withHandler:^(WGCollection *collection, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                strongSelf.filteredContent = collection;
                [strongSelf.tableView reloadData];
                isFetchingEveryone = NO;
            });
        }];
    } else if ([_filteredContent.hasNextPage boolValue]) {
        [_filteredContent addNextPage:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                [strongSelf.tableView reloadData];
                isFetchingEveryone = NO;
            });
        }];
    }
}
/*
- (void)showMeltdown {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Meltdown"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"api.wigo.us";
    }];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              UITextField *textField = alert.textFields[0];
                                                              NSString *text = textField.text;
                                                              if ([text isEqualToString:@"dev"] || [text isEqualToString:@"dev-api.wigo.us"]) {
                                                                  [Query setBaseURLString:@"https://dev-api.wigo.us"];
                                                              }
                                                              else if ([text isEqualToString:@"stage"] || [text isEqualToString:@"stage-api.wigo.us"]) {
                                                                  [Query setBaseURLString:@"https://stage-api.wigo.us"];
                                                              }
                                                              else if ([text isEqualToString:@"prod"] || [text isEqualToString:@"api.wigo.us"]) {
                                                                  [Query setBaseURLString:@"https://api.wigo.us"];
                                                              }
                                                              else {
                                                                  [Query setBaseURLString:text];
                                                              }
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}
*/
@end
