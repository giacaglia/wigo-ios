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
#import "WigoConfirmationViewController.h"
#import "MobileContactsViewController.h"
#import "InviteViewController.h"

#define xSpacing 12
#import "EventStoryViewController.h"

#define sizeOfEachCell 210
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

// Go OUT Button
@property UIButtonUngoOut *ungoOutButton;
@property BOOL spinnerAtCenter;

@end

BOOL fetchingEventAttendees;
BOOL shouldAnimate;
BOOL presentedMobileContacts;
NSNumber *page;
NSMutableArray *eventPageArray;
int eventOffset;
int sizeOfEachImage;
BOOL shouldReloadEvents;
int firstIndexOfNegativeEvent;

@implementation PlacesViewController {
    int numberOfFetchedParties;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    eventPageArray = [[NSMutableArray alloc] init];
    fetchingEventAttendees = NO;
    shouldAnimate = NO;
    presentedMobileContacts = NO;
    shouldReloadEvents = YES;
    eventOffset = 0;
    firstIndexOfNegativeEvent = -1;
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
    
    _spinnerAtCenter = YES;
    [self initializeTapHandler];
    [self initializeWhereView];

}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initializeNotificationObservers];
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whereTabIcon"];
    tabController.tabBar.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToBlue" object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [EventAnalytics tagEvent:@"Where View"];

    [self.view endEditing:YES];
    self.tabBarController.tabBar.hidden = NO;
    [self initializeNavigationBar];
    if (shouldReloadEvents) {
        [self fetchEventsFirstPage];
    }
    else {
        shouldReloadEvents = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};

}

- (void) initializeNavigationBar {
//    CGRect profileFrame = CGRectMake(0, 0, 30, 30);
//    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
//    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
//    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
//    profileImageView.clipsToBounds = YES;
//    [profileImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]] imageArea:[[Profile user] coverImageArea]];
//    [profileButton addSubview:profileImageView];
//    [profileButton addTarget:self action:@selector(profileSegue) forControlEvents:UIControlEventTouchUpInside];
//    [profileButton setShowsTouchWhenHighlighted:YES];
//    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
//    self.navigationItem.leftBarButtonItem = profileBarButton;
    self.navigationItem.rightBarButtonItem = nil;
    
    [self updatedTitleView];
}


- (void)initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateViewNotGoingOut)
                                                 name:@"updateViewNotGoingOut"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollUp)
                                                 name:@"scrollUp"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chooseEvent:)
                                                 name:@"chooseEvent"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchEventsFirstPage)
                                                 name:@"fetchEvents"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchUserInfo)
                                                 name:@"fetchUserInfo"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentContactsView)
                                                 name:@"presentContactsView"
                                               object:nil];

}

- (void)updateTitleViewForNotGoingOut {
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Where are you going?";
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
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Where are you going?";
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
    if ([[Profile user] key]) {
        NSNumber *eventID = [[notification userInfo] valueForKey:@"eventID"];
        [self goOutToEventNumber:eventID];
    }
}

- (void)invitePressed {
    if ([[Profile user] attendingEventID]) {
        [self presentViewController:[[InviteViewController alloc] initWithEventName:[[Profile user] attendingEventName] andID:[[Profile user] attendingEventID]] animated:YES completion:nil];
    }

}

- (void) goHerePressed:(id)sender {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Places", @"Go Here Source", nil];
    [EventAnalytics tagEvent:@"Go Here" withDetails:options];
    shouldAnimate = YES;
    _whereAreYouGoingTextField.text = @"";
    [self.view endEditing:YES];
    UIButton *buttonSender = (UIButton *)sender;
    [self addProfileUserToEventWithNumber:(int)buttonSender.tag];
    [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self goOutToEventNumber:[NSNumber numberWithInt:(int)buttonSender.tag]];
    if ([self shouldPresentGrowthHack]) [self presentGrowthHack];
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
   
}

- (void)updateGoingSomewhereSubviewsWithTitle:(NSString *)title {
    [[_goingSomewhereButton subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UILabel *goingSomewhereLabel = [[UILabel alloc] init];
    if ([title isEqualToString:@"GO SOMEWHERE"]) {
        goingSomewhereLabel.frame = CGRectMake(100, _goingSomewhereButton.frame.size.height/2 - 7, 150, 15);
    }
    else {
        goingSomewhereLabel.frame = CGRectMake(67, _goingSomewhereButton.frame.size.height/2 - 7, 230, 15);
    }
    goingSomewhereLabel.text = title;
    goingSomewhereLabel.font = [FontProperties scMediumFont:18.0f];
    goingSomewhereLabel.textColor = [FontProperties getBlueColor];
    [_goingSomewhereButton addSubview:goingSomewhereLabel];
    
    UIImageView *goingSomewhereImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"goingSomewhereElse"]];
    goingSomewhereImageView.frame = CGRectMake(35, _goingSomewhereButton.frame.size.height/2 - 10, 18, 21);
    [_goingSomewhereButton addSubview:goingSomewhereImageView];
}

- (void) goingSomewhereElsePressed {
    [self scrollUp];
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
    if (eventIndex < [_partyUserArray count]) {
        Party *partyUser  = [_partyUserArray objectAtIndex:eventIndex];
        Event *event = [[_eventsParty getObjectArray] objectAtIndex:eventIndex];
        if ([[partyUser getObjectArray] count] != 0 && userIndex < [[partyUser getObjectArray] count]){
            User *user = [[partyUser getObjectArray] objectAtIndex:userIndex];
            if (user && event) {
                [user setIsAttending:YES];
                [user setAttendingEventID:[event eventID]];
                [user setAttendingEventName:[event name]];
                shouldReloadEvents = NO;
                self.profileViewController = [[ProfileViewController alloc] initWithUser:user];
                [self.navigationController pushViewController:self.profileViewController animated:YES];
                self.tabBarController.tabBar.hidden = YES;
            }
        }
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
        [self createEventWithName:_whereAreYouGoingTextField.text];
        [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        NSNumber *eventID = [Network createEventWithName:_whereAreYouGoingTextField.text];
        [self updatedTitleView];
        [self fetchEventsFirstPage];
        [Network postGoingToEventNumber:[eventID intValue]];
        User *profileUser = [Profile user];
        [profileUser setIsAttending:YES];
        [profileUser setIsGoingOut:YES];
        [profileUser setAttendingEventID:eventID];
        if ([self shouldPresentGrowthHack]) [self presentGrowthHack];
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
//    if (shouldAnimate) {
//        [_placesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
//        shouldAnimate = NO;
//    }
//    else {
        [_placesTableView reloadData];
//    }
}


- (void)searchTableList:(NSString *)searchString {
    NSArray *contentNameArray = [_contentParty getNameArray];
    NSArray *searchArray = [searchString componentsSeparatedByString:@" "];
    if ([searchArray count] > 1) {
        for (int i = 0; i < [contentNameArray count]; i++) {
            NSString *tempStr = [contentNameArray objectAtIndex:i];
            NSComparisonResult result = [tempStr compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
            if (result == NSOrderedSame && ![[_filteredContentParty getNameArray] containsObject:tempStr]) {
                [_filteredContentParty addObject: [[[_contentParty getObjectArray] objectAtIndex:i] dictionary]];
                [_filteredPartyUserArray addObject:[_partyUserArray objectAtIndex:i]];
            }
        }
    }
    else {
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

}


#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == [[_contentParty getObjectArray] count]) {
        return 70;
    }
    if (firstIndexOfNegativeEvent >= 0 && [indexPath row] >= firstIndexOfNegativeEvent) {
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
            if (indexPath.row == 0)
                [self updateGoingSomewhereSubviewsWithTitle:@"GO SOMEWHERE"];
            else
                [self updateGoingSomewhereSubviewsWithTitle:@"GO SOMEWHERE ELSE"];
                
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
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(xSpacing, 5, self.view.frame.size.width - 30, 60)];
    labelName.numberOfLines = 0;
    labelName.lineBreakMode = NSLineBreakByWordWrapping;
    NSString *numberOfPeopleGoing;
    NSString *text;
    if ([[event eventID] intValue] < 0) {
        placeSubView.frame = CGRectMake(0, 0, self.view.frame.size.width, 70);
        text = [NSString stringWithFormat: @"%@ \nBe the first", [event name]];
    }
    else if ([totalUsers intValue] == 1) {
        numberOfPeopleGoing = [NSString stringWithFormat:@"%@ is going", [totalUsers stringValue]];
        text = [NSString stringWithFormat: @"%@ \n%@", [event name], numberOfPeopleGoing];
    }
    else {
        numberOfPeopleGoing = [NSString stringWithFormat:@"%@ are going", [totalUsers stringValue]];
        text = [NSString stringWithFormat: @"%@ \n%@", [event name], numberOfPeopleGoing];
    }
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttribute:NSFontAttributeName value:[FontProperties getTitleFont] range:NSMakeRange(0,[[event name] length])];
//    [attributedString addAttribute:NSForegroundColorAttributeName value:RGB(104, 174, 215) range:NSMakeRange(0,[[event name] length])];
    [attributedString addAttribute:NSFontAttributeName value:[FontProperties getSubtitleFont] range:NSMakeRange([[event name] length],[text length] - [[event name] length])];
    [attributedString addAttribute:NSForegroundColorAttributeName value:RGB(204, 204, 204) range:NSMakeRange([[event name] length],[text length] - [[event name] length])];
    labelName.attributedText = attributedString;
    [labelName sizeToFit];
    labelName.frame = CGRectMake(xSpacing, 5, self.view.frame.size.width - 50, 60);
    [placeSubView addSubview:labelName];

    NSNumber *numberOfMessages = [event numberOfMessages];
    CGSize size = [numberOfPeopleGoing sizeWithAttributes:
                   @{NSFontAttributeName:
                         [FontProperties getSubtitleFont]}];

    if ([numberOfMessages intValue] > 0) {
        UIImageView *chatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(xSpacing + size.width + 10, 40, 20, 20)];
        chatBubbleImageView.image = [UIImage imageNamed:@"chatBubble"];
        [placeSubView addSubview:chatBubbleImageView];
        UILabel *chatNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 15)];
        chatNumberLabel.text = [NSString stringWithFormat:@"%@", [numberOfMessages stringValue]];
        chatNumberLabel.textAlignment = NSTextAlignmentCenter;
        chatNumberLabel.font = [FontProperties mediumFont:12.0f];
        chatNumberLabel.textColor = [UIColor whiteColor];
        [chatBubbleImageView addSubview:chatNumberLabel];
    }
    
    UIImageView *postStoryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 30, 26, 13, 22)];
    postStoryImageView.image = [UIImage imageNamed:@"postStory"];
    [placeSubView addSubview:postStoryImageView];

    // Variables to add images
    int xPosition = xSpacing;
    sizeOfEachImage = 80;
    
    UIScrollView *imagesScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, placeSubView.frame.size.width, placeSubView.frame.size.height)];
    imagesScrollView.contentSize = CGSizeMake(xPosition, placeSubView.frame.size.height);
    imagesScrollView.showsHorizontalScrollIndicator = NO;
    imagesScrollView.delegate = self;
    imagesScrollView.tag = (int)[indexPath row];
    [placeSubView addSubview:imagesScrollView];
   
    // If attending event ID is negative OR if attending event is positive and the user is attending
    // the event.
    if ( ([[[Profile user] attendingEventID] intValue] < 0 && [indexPath row] == 0) ||
        ([[Profile user] isGoingOut] && [[Profile user] isAttending] && [[[Profile user] attendingEventID] isEqualToNumber:[event eventID]])
        ) {
        placeSubView.backgroundColor = [FontProperties getLightBlueColor];
        
//        UIButton *aroundInviteButton = [[UIButton alloc] initWithFrame:CGRectMake(placeSubView.frame.size.width - 105 - 5, 10 - 5, 90 + 10, 17 + 25)];
        UIButton *aroundInviteButton = [[UIButton alloc] initWithFrame:CGRectMake(placeSubView.frame.size.width/2 - 50, 168, 90 + 10, 17 + 25)];
        aroundInviteButton.tag = [(NSNumber *)[event eventID] intValue];
        [aroundInviteButton addTarget:self action:@selector(invitePressed) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 95, 25)];
        inviteButton.enabled = NO;
        [inviteButton setTitle:@"INVITE PEOPLE" forState:UIControlStateNormal];
        [inviteButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
        inviteButton.backgroundColor = [UIColor whiteColor];
        inviteButton.titleLabel.font = [FontProperties scMediumFont:12.0f];
        inviteButton.layer.cornerRadius = 5;
        inviteButton.layer.borderWidth = 1;
        inviteButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
        [placeSubView addSubview:aroundInviteButton];
        [aroundInviteButton addSubview:inviteButton];
    }
    else {
//        UIButton *aroundGoOutButton = [[UIButton alloc] initWithFrame:CGRectMake(placeSubView.frame.size.width - 90 - 5, 10 - 5, 80 + 10, 17 + 25)];
        UIButton *aroundGoOutButton = [[UIButton alloc] initWithFrame:CGRectMake(placeSubView.frame.size.width/2 - 50, 168, 90 + 10, 17 + 25)];
        aroundGoOutButton.tag = [(NSNumber *)[event eventID] intValue];
        [aroundGoOutButton addTarget:self action:@selector(goHerePressed:) forControlEvents:UIControlEventTouchUpInside];
        
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
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 70, sizeOfEachImage, sizeOfEachImage)];
        xPosition += sizeOfEachImage + 3;
        imageButton.tag = [self createUniqueIndexFromUserIndex:i andEventIndex:(int)[indexPath row]];
        [imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
        [imagesScrollView addSubview:imageButton];
        imagesScrollView.contentSize = CGSizeMake(xPosition, placeSubView.frame.size.height);
        
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.frame = CGRectMake(0, 0, sizeOfEachImage, sizeOfEachImage);
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        [imgView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
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
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 70, sizeOfEachImage, sizeOfEachImage)];
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
    
    //add invisible event conversation button
    UIButton *eventFeedButton = [[UIButton alloc] initWithFrame:CGRectMake(labelName.frame.origin.x, labelName.frame.origin.y, self.view.frame.size.width - labelName.frame.origin.x, labelName.frame.size.height)];
    eventFeedButton.backgroundColor = [UIColor clearColor];
    eventFeedButton.tag = indexPath.row;
    [eventFeedButton addTarget: self action: @selector(showEventConversation:) forControlEvents: UIControlEventTouchUpInside];
    [cell.contentView addSubview: eventFeedButton];
    imagesScrollView.contentOffset = CGPointMake(eventOffset, 0);
    return cell;
}


- (void)showEventConversation:(UIButton *) button {
    NSArray *eventsArray;
    if (_isSearching) eventsArray = [_filteredContentParty getObjectArray];
    else eventsArray = [_contentParty getObjectArray];
    
    Event *chosenEvent = [eventsArray objectAtIndex: button.tag];
    
    EventStoryViewController *eventStoryController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventStoryViewController"];
    eventStoryController.event = chosenEvent;
    
    [self presentViewController:eventStoryController animated:YES completion:nil];
//    [self.navigationController pushViewController: eventStoryController animated: YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (int)createUniqueIndexFromUserIndex:(int)userIndex andEventIndex:(int)eventIndex {
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

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != _placesTableView)
        if (scrollView.contentOffset.x + 320 >= scrollView.contentSize.width - sizeOfEachImage && !fetchingEventAttendees) {
            fetchingEventAttendees = YES;
            [self fetchEventAttendeesAsynchronousForEvent:(int)scrollView.tag];
        }
}

#pragma mark - Network Asynchronous Functions

- (void) fetchEventsFirstPage {
    page = @1;
    [self fetchEvents];
}

- (void) fetchEvents {
    if (!fetchingEventAttendees) {
        fetchingEventAttendees = YES;
        if (_spinnerAtCenter) [WiGoSpinnerView addDancingGToCenterView:self.view];
        NSString *queryString;
        if (![page isEqualToNumber:@1] && [_eventsParty nextPageString]) {
            queryString = [_eventsParty nextPageString];
        }
        else {
            queryString = [NSString stringWithFormat:@"events/?date=tonight&page=%@&attendees_limit=10", [page stringValue]];
        }
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            if ([page isEqualToNumber:@1]) {
                numberOfFetchedParties = 0;
                _eventsParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
                _contentParty = _eventsParty;
                _filteredContentParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
            }
            NSArray *events = [jsonResponse objectForKey:@"objects"];
            [self getFirstIndexOfSuggestedEvent:events];
            [_eventsParty addObjectsFromArray:events];
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_eventsParty addMetaInfo:metaDictionary];
            [self fillEventAttendees];
            page = @([page intValue] + 1);
            fetchingEventAttendees = NO;
            [eventPageArray removeAllObjects];
            for (int i = 0; i < [[_eventsParty getObjectArray] count]; i++) {
                [eventPageArray addObject:@2];
            }
            [self fetchedOneParty];
        }];
    }
}

- (void)getFirstIndexOfSuggestedEvent:(NSArray *)events {
    NSArray *arrayOfIDs = [events valueForKey:@"id"];
    NSUInteger index = [arrayOfIDs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *eventID = (NSNumber *)obj;
        if ([eventID intValue] < 0) {
            return YES;
        }
        else return NO;
    }];
    
    if (index != NSNotFound) firstIndexOfNegativeEvent = -1;
    firstIndexOfNegativeEvent = index;
}

- (void)fillEventAttendees {
    _partyUserArray =  [[NSMutableArray alloc] init];
    for (int i = 0; i < [[_eventsParty getObjectArray] count]; i++) {
        Event *event = [[_eventsParty getObjectArray] objectAtIndex:i];
        NSArray *eventAttendeesArray = [event getEventAttendees];
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
            [partyUser addObject:user];
        }
        [_partyUserArray addObject:partyUser];
    }
}

- (void)fetchEventAttendeesAsynchronousForEvent:(int)eventNumber {
    Event *event = [[_eventsParty getObjectArray] objectAtIndex:eventNumber];
    NSNumber *eventId = [event eventID];
    if (eventNumber < [eventPageArray count]) {
        NSNumber *pageNumberForEvent = [eventPageArray objectAtIndex:eventNumber];
        if ([pageNumberForEvent intValue] > 0) {
            NSString *queryString = [NSString stringWithFormat:@"eventattendees/?event=%@&limit=10&page=%@", [eventId stringValue], [pageNumberForEvent stringValue]];
            NSDictionary *inputDictionary = @{@"i": [NSNumber numberWithInt:eventNumber], @"page": pageNumberForEvent};
            [Network queryAsynchronousAPI:queryString
                      withInputDictionary:(NSDictionary *)inputDictionary
                              withHandler:^(NSDictionary *resultInputDictionary, NSDictionary *jsonResponse, NSError *error) {
                                  dispatch_async(dispatch_get_main_queue(), ^(void){
                                      NSNumber *pageNumberForEvent = [resultInputDictionary objectForKey:@"page"];
                                      NSArray *eventAttendeesArray = [jsonResponse objectForKey:@"objects"];
                                      Party *partyUser = [_partyUserArray objectAtIndex:eventNumber];
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
                                      
                                      if ([eventAttendeesArray count] > 0) {
                                          pageNumberForEvent = @([pageNumberForEvent intValue] + 1);
                                          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:eventNumber inSection:0];
                                          UITableViewCell *cell = [_placesTableView cellForRowAtIndexPath:indexPath];
                                          for (UIView *view in [[[cell.contentView subviews] objectAtIndex:0] subviews]) {
                                              if ([view isKindOfClass:[UIScrollView class]]) {
                                                  UIScrollView *scrollView = (UIScrollView *)view;
                                                  eventOffset = scrollView.contentOffset.x;
                                              }
                                          }
                                          [_placesTableView beginUpdates];
                                          [_placesTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:eventNumber inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                                          [_placesTableView endUpdates];
                                          eventOffset = 0;
                                      }
                                      else {
                                          pageNumberForEvent = @-1;
                                      }
                                      [eventPageArray replaceObjectAtIndex:eventNumber withObject:pageNumberForEvent];
                                      fetchingEventAttendees = NO;
                                  });
                              }];
        }
        else  fetchingEventAttendees = NO;
    }
    else fetchingEventAttendees = NO;
}

- (void)fetchedOneParty {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        _spinnerAtCenter ? [WiGoSpinnerView removeDancingGFromCenterView:self.view] : [_placesTableView didFinishPullToRefresh];
         _spinnerAtCenter = NO;
        _contentParty = _eventsParty;
        _filteredContentParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
        [self dismissKeyboard];
        if ([page isEqualToNumber:@2]) [_placesTableView setContentOffset:CGPointZero animated:YES];
    });
}

- (void) fetchUserInfo {
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ([[jsonResponse allKeys] containsObject:@"status"]) {
                if (![[jsonResponse objectForKey:@"status"] isEqualToString:@"error"]) {
                    User *user = [[User alloc] initWithDictionary:jsonResponse];
                    [Profile setUser:user];
                    [self updatedTitleView];
                }
            }
            else {
                User *user = [[User alloc] initWithDictionary:jsonResponse];
                [Profile setUser:user];
                [self updatedTitleView];
            }
        });
    }];
}


#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    [WiGoSpinnerView addDancingGToUIScrollView:_placesTableView withHandler:^{
        _spinnerAtCenter = NO;
        [self fetchEventsFirstPage];
    }];
}

#pragma mark - Growth Hack
- (BOOL)shouldPresentGrowthHack {
    int numberOfTimesWentOut = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"numberOfTimesWentOut"];
    if (numberOfTimesWentOut == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"numberOfTimesWentOut"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return NO;
    }
    else if (numberOfTimesWentOut == 1) {
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"numberOfTimesWentOut"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
    return NO;
}

- (void)presentGrowthHack {
    [[Profile user] setGrowthHackPresented];
    [[Profile user] saveKeyAsynchronously:@"properties"];
    CATransition* transition = [CATransition animation];
    transition.duration = 1;
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromBottom;
    [self.view.window.layer addAnimation:transition forKey:kCATransition];
    [self presentViewController:[WigoConfirmationViewController new] animated:NO completion:nil];
}

- (void)presentContactsView {
    if (!presentedMobileContacts) {
        presentedMobileContacts = YES;
        [self presentViewController:[MobileContactsViewController new] animated:YES completion:nil];
    }
}

- (void)createEventWithName:(NSString *)eventName {
    Event *event = [[Event alloc] initWithDictionary:@{@"id": @-1, @"name": eventName, @"num_attending": @1}];
    [_eventsParty addObjectsFromArray:@[[event dictionary]]];
    Party *partyUser = [[Party alloc] initWithObjectType:USER_TYPE];
    [partyUser addObject:[Profile user]];
    [_partyUserArray addObject:partyUser];
    [_eventsParty exchangeObjectAtIndex:([[_eventsParty getObjectArray] count] - 1) withObjectAtIndex:0];
    [_partyUserArray exchangeObjectAtIndex:([_partyUserArray count] - 1) withObjectAtIndex:0];
    [self removeUserFromAnyOtherEvent:[Profile user]];
}

- (void)addProfileUserToEventWithNumber:(int)eventID {
    NSArray *arrayOfEvents = [_eventsParty getObjectArray];
    int index;
    for (int i = 0; i < [arrayOfEvents count]; i++) {
        Event *newEvent = [arrayOfEvents objectAtIndex:i];
        if ([[newEvent eventID] intValue] == eventID) {
            index = i;
            [self addUser:[Profile user] toEventAtIndex:(int)index];
            Event *event = [[_eventsParty getObjectArray] objectAtIndex:index];
            [[Profile user] setIsAttending:YES];
            [[Profile user] setIsGoingOut:YES];
            [[Profile user] setEventID:[event eventID]];
            [[Profile user] setAttendingEventID:[event eventID]];
            [newEvent setNumberAttending:@([[newEvent numberAttending] intValue] + 1)];
            [_eventsParty replaceObjectAtIndex:index withObject:newEvent];

            break;
        }
        
    }
    [_eventsParty exchangeObjectAtIndex:index withObjectAtIndex:0];
}

- (void)addUser:(User *)user toEventAtIndex:(int)index {
    Party *partyUser = [_partyUserArray objectAtIndex:index];
    [self removeUserFromAnyOtherEvent:user];
    [partyUser insertObject:user inObjectArrayAtIndex:0];
    [_partyUserArray replaceObjectAtIndex:index withObject:partyUser];
    [_partyUserArray exchangeObjectAtIndex:index withObjectAtIndex:0];
}


- (void)removeUserFromAnyOtherEvent:(User *)user {
    NSArray *arrayOfEvents = [_eventsParty getObjectArray];
    for (int i = 0; i < [arrayOfEvents count]; i++) {
        Event *event = [arrayOfEvents objectAtIndex:i];
        Party *partyUser = [_partyUserArray objectAtIndex:i];
        for (int j = 0; j < [[partyUser getObjectArray] count]; j++) {
            User *newUser = [[partyUser getObjectArray] objectAtIndex:j];
            if ([user isEqualToUser:newUser]) {
                [partyUser removeUser:newUser];
                [event setNumberAttending:@([[event numberAttending] intValue] - 1)];
                [_partyUserArray replaceObjectAtIndex:i withObject:partyUser];
            }
        }
    }
}

@end
