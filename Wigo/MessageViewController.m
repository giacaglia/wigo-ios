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
#import "SDWebImage/UIImageView+WebCache.h"

@interface MessageViewController ()

// Search Bar
@property UISearchBar *searchBar;
@property BOOL isSearching;
@property UIImageView *searchIconImageView;

// Table View
@property UITableView *tableView;
@property NSArray *contentList;
@property NSNumber *page;
@property Party *everyoneParty;

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
    // Do any additional setup after loading the view.
    
    // Title setup
    self.title = @"NEW MESSAGE";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self initializeLeftBarButton];
    [self initializeSearchBar];
    [self initializeTableListOfFriends];
    [self initializeTapHandler];
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
    _everyoneParty = [[Party alloc] initWithObjectName:@"User"];
    _page = @1;
    [self fetchEveryone];

    _contentList = [_everyoneParty getObjectArray];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 108, self.view.frame.size.width, self.view.frame.size.height - 108)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_tableView];
}

#pragma Network Functions

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
            _contentList = [_everyoneParty getObjectArray];
            [_tableView reloadData];
        });
    }];
}

#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int hasNextPage = ([_everyoneParty hasNextPage] ? 1 : 0);
    return [_contentList count] + hasNextPage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if ([indexPath row] == [_contentList count]) {
        [self fetchEveryone];
        return cell;
    }
    
    User *user = [_contentList objectAtIndex:[indexPath row]];
   
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    [cell.contentView addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    textLabel.font = [FontProperties getSubtitleFont];
    [cell.contentView addSubview:textLabel];
    UILabel *lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 40, 150, 20)];
    lastMessageLabel.font = [UIFont fontWithName:@"Whitney-Medium" size:13.0f];
    lastMessageLabel.textAlignment = NSTextAlignmentLeft;

    if ([user isGoingOut]) {
        lastMessageLabel.text = @"Going Out";
        lastMessageLabel.textColor = [FontProperties getOrangeColor];
    }
    
    [cell.contentView addSubview:lastMessageLabel];
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
    User *user = [_contentList objectAtIndex:[indexPath row]];
    self.conversationViewController = [[ConversationViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:self.conversationViewController animated:YES];
}


#pragma mark - Search Bar
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

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    _searchIconImageView.hidden = YES;
    _isSearching = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    _searchIconImageView.hidden = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    //Remove all objects first.
//    [_filteredContentList removeAllObjects];
//    
//    if([searchText length] != 0) {
//        _isSearching = YES;
//        [self searchTableList];
//    }
//    else {
//        _isSearching = NO;
//    }
//    [_tableViewOfPeople reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchTableList];
}

- (void)searchTableList {
//    NSString *searchString = _searchBar.text;
//    
//    for (NSString *tempStr in _contentList) {
//        NSComparisonResult result = [tempStr compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchString length])];
//        if (result == NSOrderedSame) {
//            [_filteredContentList addObject:tempStr];
//        }
//    }
}


@end
