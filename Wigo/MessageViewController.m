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
@property Party *everyoneParty;
@property Party *contentParty;
@property Party *filteredContentParty;

@end

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
    
    _everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    _contentParty = [[Party alloc] initWithObjectType:USER_TYPE];
    _filteredContentParty = [[Party alloc] initWithObjectType:USER_TYPE];
//    _contentList = [_everyoneParty getObjectArray];

    
    // Title setup
    self.title = @"NEW MESSAGE";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self initializeLeftBarButton];
    [self initializeSearchBar];
    [self initializeTableListOfFriends];
    [self initializeTapHandler];
    
    [self fetchFirstPageEveryone];
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


- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 60, 44) andType:@0];
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

- (void) initializeTableListOfFriends {
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 108, self.view.frame.size.width, self.view.frame.size.height - 108)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_tableView];
}

#pragma Network Functions

- (void) fetchFirstPageEveryone {
    _everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    _page = @1;
    [self fetchEveryone];
}

- (void) fetchEveryone {
    NSString *queryString = [NSString stringWithFormat:@"users/?ordering=is_goingout&page=%@" ,[_page stringValue]];
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
            [_tableView reloadData];
        });
    }];
}

#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isSearching) {
        return [[_filteredContentParty getObjectArray] count];
    }
    int hasNextPage = ([_everyoneParty hasNextPage] ? 1 : 0);
    return [[_contentParty getObjectArray] count] + hasNextPage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if ([indexPath row] == [[_contentParty getObjectArray] count]) {
        [self fetchEveryone];
        return cell;
    }
    User *user;
    if (_isSearching) {
        if ([[_filteredContentParty getObjectArray] count] == 0) return cell;
        user = [[_filteredContentParty getObjectArray] objectAtIndex:[indexPath row]];
    }
    else {
        if ([[_contentParty getObjectArray] count] == 0) return cell;
        user = [[_contentParty getObjectArray] objectAtIndex:[indexPath row]];
    }
       
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    [cell.contentView addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    textLabel.font = [FontProperties getSubtitleFont];
    [cell.contentView addSubview:textLabel];
    
    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 40, 150, 20)];
    goingOutLabel.font = MEDIUM_FONT(13.0f);
    goingOutLabel.textAlignment = NSTextAlignmentLeft;
    if ([user isGoingOut]) {
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
    User *user;
    if (_isSearching) user = [[_filteredContentParty getObjectArray] objectAtIndex:[indexPath row]];
    else user = [[_contentParty getObjectArray] objectAtIndex:[indexPath row]];
    self.conversationViewController = [[ConversationViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:self.conversationViewController animated:YES];
}


#pragma mark - UISearchBar
- (void)initializeSearchBar {
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(11, 70, self.view.frame.size.width - 22, 30)];
    _searchBar.barTintColor = [UIColor whiteColor];
    _searchBar.tintColor = [FontProperties getOrangeColor];
    _searchBar.placeholder = @"SEARCH BY NAME";
    _searchBar.delegate = self;
    UITextField *searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:[FontProperties getOrangeColor] forKeyPath:@"_placeholderLabel.textColor"];
    [self.view addSubview:_searchBar];
    
    // Search Icon Clear
    UITextField *txfSearchField = [_searchBar valueForKey:@"_searchField"];
    [txfSearchField setLeftViewMode:UITextFieldViewModeNever];
    
    // Add Custom Search Icon
    _searchIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orangeSearchIcon"]];
    _searchIconImageView.frame = CGRectMake(65, 8, 14, 14);
    [_searchBar addSubview:_searchIconImageView];
    [self.view addSubview:_searchBar];
    
    // Add orange border
    UIView *searchBarView  = [[UIView alloc] initWithFrame:CGRectMake(_searchBar.frame.origin.x - 4, _searchBar.frame.origin.y, _searchBar.frame.size.width + 8, _searchBar.frame.size.height)];
    searchBarView.layer.borderWidth = 1.0f;
    searchBarView.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    searchBarView.layer.cornerRadius = 5;
    [self.view addSubview:searchBarView];
    
    [self.view bringSubviewToFront:_searchBar];
    
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
    [_tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchTableList];
}

- (void)searchTableList {
    NSString *searchString = _searchBar.text;
    _page = @1;
    NSString *queryString = [NSString stringWithFormat:@"users/?ordering=-id&page=%@&text=%@" ,[_page stringValue], searchString];
    [self searchUsersWithString:queryString ];
    
}


- (void)searchUsersWithString:(NSString *)queryString {
    [Network queryAsynchronousAPI:queryString withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        if ([_page isEqualToNumber:@1]) _filteredContentParty = [[Party alloc] initWithObjectType:USER_TYPE];
        NSMutableArray *arrayOfUsers;
        arrayOfUsers = [jsonResponse objectForKey:@"objects"];
        
        [_filteredContentParty addObjectsFromArray:arrayOfUsers];
        NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
        [_filteredContentParty addMetaInfo:metaDictionary];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            _page = @([_page intValue] + 1);
            [_tableView reloadData];
        });
    }];
}

@end
