//
//  PlacesViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PlacesViewController.h"
#import "Globals.h"
#import "RWBlurPopover.h"

//View Extensions
#import "UIButtonAligned.h"
#import "UIButtonUngoOut.h"


#define xSpacing 10
#define sizeOfEachCell 125
@interface PlacesViewController ()

@property UIView *whereAreYouGoingView;
@property UITextField *whereAreYouGoingTextField;
@property UIButton *clearButton;
@property UIButton *createButton;


@property int tagInteger;
@property Party *contentParty;
@property Party *filteredContentParty;
@property NSMutableArray *filteredPartyUserArray;

//@property NSMutableArray *filteredContentList;
@property BOOL isSearching;
@property NSMutableArray *placeSubviewArray;
@property UIImageView *searchIconImageView;
@property UIView *searchBarBorderView;

@property UIImageView *whereImageView;
@property UILabel *whereLabel;
@property int yPositionOfWhereSubview;
@property  UIButton *goingSomewhereButton;

@property UITableView *placesTableView;

//private pressed
@property UIScrollView *scrollViewSender;
@property CGPoint scrollViewPoint;

// Events Summary
@property Party *eventsParty;
@property NSMutableArray *partyUserArray;
@property Party *everyoneParty;

// Go OUT Button
@property UIButtonUngoOut *ungoOutButton;

@property NSNumber *page;

@property BOOL spinnerAtTop;

@end

@implementation PlacesViewController {
    int numberOfFetchedParties;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    _spinnerAtTop = YES;
    [self initializeNotificationObservers];
    [self initializeTapHandler];
    [self initializeWhereView];
    [self fetchEventsFirstPage];
}


- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whereTabIcon"];
    tabController.tabBar.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToBlue" object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [EventAnalytics tagEvent:@"Where View"];

    self.tabBarController.tabBar.hidden = NO;
    [self initializeNavigationBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};

}

- (void) initializeNavigationBar {
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 1, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGBAlpha(122, 193, 226, 0.1f);
    [self.navigationController.navigationBar addSubview:lineView];

    
    CGRect profileFrame = CGRectMake(0, 0, 30, 30);
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]]];
    [profileButton addSubview:profileImageView];
    [profileButton addTarget:self action:@selector(profileSegue) forControlEvents:UIControlEventTouchUpInside];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.leftBarButtonItem = profileBarButton;
    self.navigationItem.rightBarButtonItem = nil;
    
    [self updatedTitleView];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
}


- (void)initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViewNotGoingOut) name:@"updateViewNotGoingOut" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chooseEvent:) name:@"chooseEvent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchEventsFirstPage) name:@"fetchEvents" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchUserInfo) name:@"fetchUserInfo" object:nil];

}

- (void)updateTitleViewForNotGoingOut {
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Where";
}

- (void)scrollUp {
    [_placesTableView setContentOffset:CGPointZero animated:YES];
}

- (void) updateViewNotGoingOut {
    [[Profile user] setIsGoingOut:NO];
    [self updatedTitleView];
    [self fetchEventsFirstPage];
}

- (void) updatedTitleView {
    if ([[Profile user] isGoingOut]) {
        _ungoOutButton = [[UIButtonUngoOut alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
        [_ungoOutButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
        self.navigationItem.titleView = _ungoOutButton;
    }
    else {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = @"Where";
    }
}

- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = YES;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    _ungoOutButton.enabled = YES;
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.2 animations:^{
        _placesTableView.transform = CGAffineTransformMakeTranslation(0, 0);
        _whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0,-47);
        _goingSomewhereButton.hidden = NO;
    }];
    [self clearTextField];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == _whereAreYouGoingView) {
        return NO;
    }
    return YES;
}

- (void)initializeWhereView {
    _placesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49)];
    [self.view addSubview:_placesTableView];
    _placesTableView.dataSource = self;
    _placesTableView.delegate = self;
    [_placesTableView setSeparatorColor:[FontProperties getBlueColor]];
    _placesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    _yPositionOfWhereSubview = 280;
    [self addRefreshToScrollView];
    [self initializeGoingSomewhereElseButton];
}

- (void)chooseEvent:(NSNotification *)notification {
    NSNumber *eventID = [[notification userInfo] valueForKey:@"eventID"];
    [self goOutToEventNumber:eventID];
}


- (void) goOutHere:(id)sender {
    _whereAreYouGoingTextField.text = @"";
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    [self goOutToEventNumber:[NSNumber numberWithInt:(int)buttonSender.tag]];
}

- (void)goOutToEventNumber:(NSNumber*)eventID {
    User *profileUser = [Profile user];
    [profileUser setIsGoingOut:YES];
    [profileUser setAttendingEventID:eventID];
    [self updatedTitleView];
    [[Profile user] setEventID:eventID];
    [Network postGoingToEventNumber:[eventID intValue]];
    [self fetchEventsFirstPage];
}

- (void)initializeGoingSomewhereElseButton {
    _goingSomewhereButton = [[UIButton alloc] initWithFrame:CGRectMake(xSpacing, 35 - 20, self.view.frame.size.width - 2*xSpacing, 40)];
    [_goingSomewhereButton addTarget:self action:@selector(goingSomewhereElsePressed) forControlEvents:UIControlEventTouchUpInside];
    _goingSomewhereButton.layer.cornerRadius = 10;
    _goingSomewhereButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    _goingSomewhereButton.layer.borderWidth = 1;
    
    UILabel *goingSomewhereLabel = [[UILabel alloc] initWithFrame:CGRectMake(67, _goingSomewhereButton.frame.size.height/2 - 7, 230, 15)];
    goingSomewhereLabel.text = @"GO SOMEWHERE ELSE";
    goingSomewhereLabel.font = [FontProperties scMediumFont:18.0f];
    goingSomewhereLabel.textColor = [FontProperties getBlueColor];
    [_goingSomewhereButton addSubview:goingSomewhereLabel];
    
    UIImageView *goingSomewhereImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"goingSomewhereElse"]];
    goingSomewhereImageView.frame = CGRectMake(35, _goingSomewhereButton.frame.size.height/2 - 10, 18, 21);
    [_goingSomewhereButton addSubview:goingSomewhereImageView];
}

- (void) goingSomewhereElsePressed {
    [self dismissKeyboard];
    [self showWhereAreYouGoingView];
    _goingSomewhereButton.hidden = YES;
    _ungoOutButton.enabled = NO;
    [_whereAreYouGoingTextField becomeFirstResponder];
    [self textFieldDidChange:_whereAreYouGoingTextField];
}

- (void)profileSegue {
    self.profileViewController = [[ProfileViewController alloc] initWithUser:[Profile user]];
    [self.navigationController pushViewController:self.profileViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)chooseUser:(id)sender {
    int tag = (int)((UIButton *)sender).tag;
    NSDictionary *eventAndUserIndex = [self getUserIndexAndEventIndexFromUniqueIndex:tag];
    int eventIndex = [(NSNumber *)[eventAndUserIndex objectForKey:@"eventIndex"] intValue];
    int userIndex = [(NSNumber *)[eventAndUserIndex objectForKey:@"userIndex"] intValue];
    Party *partyUser  = [_partyUserArray objectAtIndex:eventIndex];
    if ([[partyUser getObjectArray] count] != 0 ){
        User *user = [[partyUser getObjectArray] objectAtIndex:userIndex];
        self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.profileViewController animated:YES];
        self.tabBarController.tabBar.hidden = YES;
    }
}

- (void)choseProfile:(id)sender {
    _scrollViewPoint = _scrollViewSender.contentOffset;
    _scrollViewSender = (UIScrollView *)[sender superview];
    _scrollViewSender.contentOffset = CGPointMake(_scrollViewSender.contentSize.width - 245, 0);
    _scrollViewSender.scrollEnabled = NO;
    UITableViewCell *cellSender = (UITableViewCell *)[_scrollViewSender superview];

    UIViewController *newViewController = [[UIViewController alloc] init];
    newViewController.view = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:cellSender]];
    newViewController.view.backgroundColor = [UIColor whiteColor];

    UIImageView *privateLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 120, 300, 15)];
    privateLineImageView.image = [UIImage imageNamed:@"privateLine"];
    [newViewController.view addSubview:privateLineImageView];
    
    UILabel *privateExplanation = [[UILabel alloc] initWithFrame:CGRectMake(30, 130, newViewController.view.frame.size.width -  60, 80)];
    privateExplanation.text = @"These users are private.\n Go here to meet them in person!";
    privateExplanation.font = [FontProperties getTitleFont];
    privateExplanation.textAlignment = NSTextAlignmentCenter;
    privateExplanation.numberOfLines = 0;
    privateExplanation.lineBreakMode = NSLineBreakByWordWrapping;
    [newViewController.view addSubview:privateExplanation];
    
    UIButton *gotItButton = [[UIButton alloc] initWithFrame:CGRectMake(108, 210, 100, 30)];
    [gotItButton setTitle:@"Got It" forState:UIControlStateNormal];
    [gotItButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    gotItButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    gotItButton.titleLabel.font = [FontProperties getTitleFont];
    gotItButton.backgroundColor = RGB(56, 56, 56);
    gotItButton.layer.cornerRadius = 5;
    gotItButton.layer.borderWidth = 1;
    [gotItButton addTarget:self action:@selector(gotItPressed) forControlEvents:UIControlEventTouchUpInside];
    [newViewController.view addSubview:gotItButton];
    
    [[RWBlurPopover instance] presentViewController:newViewController withOrigin:200 andHeight:250];
}

- (void) gotItPressed {
    _scrollViewSender.contentOffset = _scrollViewPoint;
    _scrollViewSender.scrollEnabled = YES;
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void){}];
}

#pragma mark - Where Are You Going? View and Delegate

- (void)showWhereAreYouGoingView {
    [UIView animateWithDuration:0.3 animations:^{
        _placesTableView.transform = CGAffineTransformMakeTranslation(0, 47);
    }];
    
    _whereAreYouGoingView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 47)];
    [self.view addSubview:_whereAreYouGoingView];
    
    _whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 18 - 100 - 10, 47)];
    _whereAreYouGoingTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"WHERE ARE YOU GOING?" attributes:@{NSForegroundColorAttributeName:RGBAlpha(122, 193, 226, 0.5)}];
    _whereAreYouGoingTextField.font = [FontProperties scMediumFont:15.0f];
    _whereAreYouGoingTextField.textColor = [FontProperties getBlueColor];
    [[UITextField appearance] setTintColor:[FontProperties getBlueColor]];
    _whereAreYouGoingTextField.delegate = self;
    [_whereAreYouGoingTextField addTarget:self
                                   action:@selector(textFieldDidChange:)
                         forControlEvents:UIControlEventEditingChanged];
    [_whereAreYouGoingView addSubview:_whereAreYouGoingTextField];
    
    [self addCreateButtonToTextField];
    
    _clearButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 25 - 100, _whereAreYouGoingView.frame.size.height/2 - 9, 25, 25)];
    [_clearButton addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clearButton"]]];
    [_clearButton addTarget:self action:@selector(clearTextField) forControlEvents:UIControlEventTouchUpInside];
    [_whereAreYouGoingView addSubview:_clearButton];
}

- (void)clearTextField {
    _whereAreYouGoingTextField.text = @"";
    [self textFieldDidChange:_whereAreYouGoingTextField];
}

- (void) addCreateButtonToTextField {
    _createButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 90, _whereAreYouGoingView.frame.size.height/2 - 12, 80, 25)];
    [_createButton setTitle:@"CREATE" forState:UIControlStateNormal];
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _createButton.backgroundColor = [FontProperties getBlueColor];
    [_createButton addTarget:self action:@selector(createPressed) forControlEvents:UIControlEventTouchUpInside];
    _createButton.titleLabel.font = [FontProperties scMediumFont:12.0f];
    _createButton.layer.cornerRadius = 5;
    _createButton.layer.borderWidth = 1;
    _createButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [_whereAreYouGoingView addSubview:_createButton];
    [_whereAreYouGoingView bringSubviewToFront:_createButton];
}

- (void)createPressed {
    if ([_whereAreYouGoingTextField.text length] != 0) {
        NSNumber *eventID = [Network createEventWithName:_whereAreYouGoingTextField.text];
        [Network postGoingToEventNumber:[eventID intValue]];
        User *profileUser = [Profile user];
        [profileUser setIsGoingOut:YES];
        [profileUser setAttendingEventID:eventID];
        [self updatedTitleView];
        [self fetchEventsFirstPage];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    [_filteredContentParty removeAllObjects];
    _filteredPartyUserArray = [[NSMutableArray alloc] init];
    if([textField.text length] != 0) {
        _isSearching = YES;
        _createButton.hidden = NO;
        _clearButton.hidden = NO;
        [self searchTableList:textField.text];
    }
    else {
        _isSearching = NO;
        _createButton.hidden = YES;
        _clearButton.hidden = YES;
    }
    [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}


- (void)searchTableList:(NSString *)searchString {
    NSArray *contentNameArray = [_contentParty getNameArray];
    for (int i = 0; i < [contentNameArray count]; i++) {
        NSString *tempStr = [contentNameArray objectAtIndex:i];
        NSArray *firstAndLastNameArray = [tempStr componentsSeparatedByString:@" "];
        for (NSString *firstOrLastName in firstAndLastNameArray) {
            NSComparisonResult result = [firstOrLastName compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
            if (result == NSOrderedSame && ![[_filteredContentParty getNameArray] containsObject:tempStr]) {
                [_filteredContentParty addObject: [[[_contentParty getObjectArray] objectAtIndex:i] dictionary]];
                [_filteredPartyUserArray addObject:[_partyUserArray objectAtIndex:i]];
            }
        }
    }
}


#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == [[_contentParty getObjectArray] count]) {
        return 70;
    }
    return sizeOfEachCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (_isSearching) {
        return [[_filteredContentParty getObjectArray] count];
    }
    else {
        int hasNextPage = ([_eventsParty hasNextPage] ? 1 : 0);
        return [[_contentParty getObjectArray] count] + 1 + hasNextPage;
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.contentView.backgroundColor = [UIColor whiteColor];

    if (_isSearching) {
        if (indexPath.row == [[_filteredContentParty getObjectArray] count]) {
            [cell.contentView addSubview:_goingSomewhereButton];
            return cell;
        }
    }
    else {
        if (indexPath.row == [[_contentParty getObjectArray] count]) {
            [cell.contentView addSubview:_goingSomewhereButton];
            return cell;
        }
        else if (indexPath.row == [[_contentParty getObjectArray] count] + 1) {
            [self fetchEvents];
            return cell;
        }
    }
  
    Party *partyUser;
    Event *event;
    if (_isSearching) {
        int sizeOfArray = (int)[[_filteredContentParty getObjectArray] count];
        if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
        event = [[Event alloc] initWithDictionary:[[_filteredContentParty getObjectArray] objectAtIndex:[indexPath row]]];
        sizeOfArray = (int)[_filteredPartyUserArray count];
        if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) {
            partyUser = [[Party alloc] initWithObjectType:USER_TYPE];
        }
        else partyUser = [_filteredPartyUserArray objectAtIndex:[indexPath row]];
    }
    else {
        int sizeOfArray = (int)[[_contentParty getObjectArray] count];
        if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
        event = [[_contentParty getObjectArray] objectAtIndex:[indexPath row]];
        sizeOfArray = (int)[_partyUserArray count];
        if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) partyUser = [[Party alloc] initWithObjectType:USER_TYPE];
        else partyUser  = [_partyUserArray objectAtIndex:[indexPath row]];
    }
    
    NSNumber *totalUsers = [event numberAttending];
    
    UIView *placeSubView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, sizeOfEachCell)];
    placeSubView.tag = _tagInteger;
    _tagInteger += 1;
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(xSpacing, 5, self.view.frame.size.width - 100, 30)];
    if (_isSearching) {
        if (indexPath.row < [[_filteredContentParty getObjectArray] count]) {
            labelName.text = [[_filteredContentParty getNameArray] objectAtIndex:indexPath.row];
        }
    }
    else {
        if (indexPath.row < [[_contentParty getObjectArray] count]) {
            labelName.text = [[_contentParty getNameArray] objectAtIndex:indexPath.row];
        }
    }
    labelName.font = [FontProperties getTitleFont];
    [placeSubView addSubview:labelName];

    UILabel *numberOfPeopleGoingOut = [[UILabel alloc] initWithFrame:CGRectMake(xSpacing, 30, self.view.frame.size.width, 20)];
    if ([totalUsers intValue] == 1) {
        numberOfPeopleGoingOut.text = [NSString stringWithFormat: @"%@%@",[totalUsers stringValue], @" is going"];
    }
    else {
        numberOfPeopleGoingOut.text = [NSString stringWithFormat: @"%@%@",[totalUsers stringValue], @" are going"];
    }
    numberOfPeopleGoingOut.font = [FontProperties getSubtitleFont];
    numberOfPeopleGoingOut.textColor = RGB(204, 204, 204);
    [placeSubView addSubview:numberOfPeopleGoingOut];
    
    // Variables to add images
    int xPosition = xSpacing;
    int sizeOfEachImage = 60;
    
    UIScrollView *imagesScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, placeSubView.frame.size.width, placeSubView.frame.size.height)];
    imagesScrollView.contentSize = CGSizeMake(xPosition, placeSubView.frame.size.height);
    imagesScrollView.showsHorizontalScrollIndicator = NO;
    [placeSubView addSubview:imagesScrollView];
   
    if ([[Profile user] isGoingOut] && [[Profile user] isAttending] && [[[Profile user] attendingEventID] isEqualToNumber:[event eventID]]) {
        placeSubView.backgroundColor = [FontProperties getLightBlueColor];
        UILabel *goingHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(183, 8, 125, 30)];
        goingHereLabel.textColor = [FontProperties getBlueColor];
        goingHereLabel.textAlignment = NSTextAlignmentRight;
        goingHereLabel.font = [FontProperties scMediumFont:12.0f];
        goingHereLabel.text = @"GOING HERE";
        [placeSubView addSubview:goingHereLabel];
    }
    else {
        UIButton *aroundGoOutButton = [[UIButton alloc] initWithFrame:CGRectMake(placeSubView.frame.size.width - 90 - 5, 10 - 5, 80 + 10, 17 + 25)];
        aroundGoOutButton.tag = [(NSNumber *)[event eventID] intValue];
        [aroundGoOutButton addTarget:self action:@selector(goOutHere:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *goOutButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 80, 25)];
        goOutButton.enabled = NO;
        [goOutButton setTitle:@"GO HERE" forState:UIControlStateNormal];
        [goOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        goOutButton.backgroundColor = [FontProperties getBlueColor];
        goOutButton.titleLabel.font = [FontProperties scMediumFont:12.0f];
        goOutButton.layer.cornerRadius = 5;
        goOutButton.layer.borderWidth = 1;
        goOutButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
        [placeSubView addSubview:aroundGoOutButton];
        [aroundGoOutButton addSubview:goOutButton];
    }

    for (int i = 0; i < [[partyUser getObjectArray] count]; i++) {
        User *user = [[partyUser getObjectArray] objectAtIndex:i];
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 55, sizeOfEachImage, sizeOfEachImage)];
        xPosition += sizeOfEachImage + 3;
        imageButton.tag = [self createUniqueIndexFromUserIndex:i andEventIndex:(int)[indexPath row]];
        [imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
        [imagesScrollView addSubview:imageButton];
        imagesScrollView.contentSize = CGSizeMake(xPosition, placeSubView.frame.size.height);
        
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.frame = CGRectMake(0, 0, sizeOfEachImage, sizeOfEachImage);
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        [imgView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
        [imageButton addSubview:imgView];
        
        UILabel *profileName = [[UILabel alloc] init];
        profileName.text = [user firstName];
        profileName.textColor = [UIColor whiteColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.frame = CGRectMake(0, sizeOfEachImage - 20, sizeOfEachImage, 20);
        profileName.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
        profileName.font = [FontProperties getSmallPhotoFont];
        [imgView addSubview:profileName];
    }
    
    int usersCantSee = (int)[totalUsers intValue] - (int)[[partyUser getObjectArray] count];
    if (usersCantSee  > 0) {
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 55, sizeOfEachImage, sizeOfEachImage)];
        xPosition += sizeOfEachImage;
        [imagesScrollView addSubview:imageButton];
        imagesScrollView.contentSize = CGSizeMake(xPosition, placeSubView.frame.size.height);
        
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"privacyLogo"]];
        
        imgView.frame = CGRectMake(0, 0, sizeOfEachImage, sizeOfEachImage);
        [imageButton addSubview:imgView];
        
        UILabel *profileName = [[UILabel alloc] init];
        profileName.text = [NSString stringWithFormat:@"+ %d more", usersCantSee ];;
        profileName.textColor = [UIColor whiteColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.frame = CGRectMake(0, sizeOfEachImage - 20, sizeOfEachImage, 20);
        profileName.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
        profileName.font = [FontProperties getSmallPhotoFont];
        [imgView addSubview:profileName];
    }
    [cell.contentView addSubview:placeSubView];
    
    return cell;
}

-(int)createUniqueIndexFromUserIndex:(int)userIndex andEventIndex:(int)eventIndex {
    int numberOfEvents = (int)[[_eventsParty getObjectArray] count];
    return numberOfEvents * userIndex + eventIndex;
}

- (NSDictionary *)getUserIndexAndEventIndexFromUniqueIndex:(int)uniqueIndex {
    int userIndex, eventIndex;
    int numberOfEvents = (int)[[_eventsParty getObjectArray] count];
    userIndex = uniqueIndex/numberOfEvents;
    eventIndex = uniqueIndex - userIndex * numberOfEvents;
    return @{@"userIndex": [NSNumber numberWithInt:userIndex], @"eventIndex":[NSNumber numberWithInt:eventIndex]};
}

#pragma mark - Network Asynchronous Functions


- (void) fetchEventsFirstPage {
    _page = @1;
    numberOfFetchedParties = 0;
    _eventsParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
    _contentParty = _eventsParty;
    _filteredContentParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
    [self fetchEvents];
}

- (void) fetchEvents {
    _everyoneParty = [Profile everyoneParty];
    if (_spinnerAtTop) [WiGoSpinnerView addDancingGToCenterView:self.view];
    NSString *queryString = [NSString stringWithFormat:@"events/?date=tonight&page=%@", [_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *events = [jsonResponse objectForKey:@"objects"];
        [_eventsParty addObjectsFromArray:events];
        NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
        [_eventsParty addMetaInfo:metaDictionary];
        
        [self fetchEventAttendeesAsynchronous];
        _page = @([_page intValue] + 1);
        if ([events count] == 0) {
            [self fetchedOneParty];
        }
    }];
}

- (void)fetchEventAttendeesAsynchronous {
    _partyUserArray =  [[NSMutableArray alloc] initWithCapacity:[[_eventsParty getObjectArray] count]];
    for (int j = 0; j < [[_eventsParty getObjectArray] count]; j++) {
        [_partyUserArray addObject:[[Party alloc] init]];
    }
    for (int i = 0; i < [[_eventsParty getObjectArray] count]; i++) {
        Event *event = [[_eventsParty getObjectArray] objectAtIndex:i];
        NSNumber *eventId = [event eventID];
        NSString *queryString = [NSString stringWithFormat:@"eventattendees/?event=%@", [eventId stringValue]];
        NSDictionary *inputDictionary = @{@"i": [NSNumber numberWithInt:i]};
        [Network queryAsynchronousAPI:queryString
                  withInputDictionary:(NSDictionary *)inputDictionary
                          withHandler:^(NSDictionary *resultInputDictionary ,NSDictionary *jsonResponse, NSError *error) {
                              NSArray *eventAttendeesArray = [jsonResponse objectForKey:@"objects"];
                              Party *partyUser = [[Party alloc] init];
                              for (int j = 0; j < [eventAttendeesArray count]; j++) {
                                  NSDictionary *eventAttendee = [eventAttendeesArray objectAtIndex:j];
                                  NSDictionary *userDictionary = [eventAttendee objectForKey:@"user"];
                                  User *user;
                                  if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                                      if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                                          user = [Profile user];
                                      }
                                      else {
                                          user = [[User alloc] initWithDictionary:userDictionary];
                                      }
                                  }
                                  if ([user isEqualToUser:[Profile user]]) {
                                      User *profileUser = [Profile user];
                                      [profileUser setIsGoingOut:YES];
                                      [[Profile user] setEventID:eventId];
                                  }
                                  [partyUser addObject:user];
                              }
                              NSInteger indexOfEvent = [[resultInputDictionary objectForKey:@"i"] integerValue];
                              [_partyUserArray insertObject:partyUser atIndex:indexOfEvent];
                              if (indexOfEvent + 1 < [_partyUserArray count]) [_partyUserArray removeObjectAtIndex:(indexOfEvent+1)];
                              [self fetchedOneParty];
        }];
    }
}

- (void)fetchedOneParty {
    numberOfFetchedParties += 1;
    if (numberOfFetchedParties >= [[_eventsParty getObjectArray] count]) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            _spinnerAtTop ? [WiGoSpinnerView removeDancingGFromCenterView:self.view] : [_placesTableView didFinishPullToRefresh];
            _contentParty = _eventsParty;
            _filteredContentParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
            [self dismissKeyboard];
            if ([_page isEqualToNumber:@2]) [_placesTableView setContentOffset:CGPointZero animated:YES];
        });
    }
}

- (void) fetchUserInfo {
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        User *user = [[User alloc] initWithDictionary:jsonResponse];
        User *profileUser = [Profile user];
        [profileUser setIsGoingOut:[user isGoingOut]];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updatedTitleView];
        });
    }];
}


#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    [WiGoSpinnerView addDancingGToUIScrollView:_placesTableView withHandler:^{
        _spinnerAtTop = NO;
        [self fetchEventsFirstPage];
    }];
}


@end
