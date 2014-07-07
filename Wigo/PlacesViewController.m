//
//  PlacesViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PlacesViewController.h"
#import "FontProperties.h"
#import "Profile.h"
#import <QuartzCore/QuartzCore.h>
#import "RWBlurPopover.h"
#define xSpacing 10
#define sizeOfEachCell 125

//View Extensions
#import "UIButtonAligned.h"
#import "UIButtonUngoOut.h"
#import "Party.h"
#import "Event.h"
#import "Network.h"

#import "MBProgressHUD.h"
#import "SDWebImage/UIImageView+WebCache.h"
@interface PlacesViewController ()

// TextField
@property UIView *whereAreYouGoingView;
@property UITextField *whereAreYouGoingTextField;
@property UIButton *clearButton;
@property UIButton *createButton;


@property int tagInteger;
@property NSMutableArray *contentList;
@property NSMutableArray *filteredContentList;
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
@property NSMutableArray *summaryArray;
@property Party *everyoneParty;

//@property ;

@end

@implementation PlacesViewController {
    int numberOfFetchedParties;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self initializeNotificationObservers];
    [self initializeTapHandler];

    [self loadEvents];
}

- (void) loadEvents {
    _everyoneParty = [Profile everyoneParty];
    numberOfFetchedParties = 0;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [Network queryAsynchronousAPI:@"events/?date=tonight" withHandler:^(NSDictionary *jsonRespone, NSError *error) {
        NSArray *events = [jsonRespone objectForKey:@"objects"];
        _eventsParty = [[Party alloc] initWithObjectName:@"Event"];
        [_eventsParty addObjectsFromArray:events];

        [self fetchEventAttendeesAsynchronous];
        [self fetchEventSummaryAsynchronous];
        if ([events count] == 0) {
            [self fetchedOneParty];
        }
    }];
}

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"placesSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToBlue" object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    [self initializeNavigationBar];
}

- (void) initializeNavigationBar {
    CGRect profileFrame = CGRectMake(0, 0, 30, 30);
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
    [profileButton setBackgroundImage:[Profile getProfileImage] forState:UIControlStateNormal];
    [profileButton addTarget:self action:@selector(profileSegue)
            forControlEvents:UIControlEventTouchUpInside];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.leftBarButtonItem = profileBarButton;
    self.navigationItem.rightBarButtonItem = nil;
    
    if ([Profile isGoingOut]) {
        [self updatedTitleViewForGoingOut];
    }
    else {
        [self updateViewNotGoingOut];
    }
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
}


- (void)initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViewNotGoingOut) name:@"updateViewNotGoingOut" object:nil];
}

- (void) updateViewNotGoingOut {
    [_placesTableView reloadData];
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"PLACES";

    [self loadEvents];
}

- (void) updatedTitleViewForGoingOut {
    UIButtonUngoOut *ungoOutButton = [[UIButtonUngoOut alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
    [ungoOutButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    self.navigationItem.titleView = ungoOutButton;
}

- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = YES;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.2 animations:^{
        _placesTableView.transform = CGAffineTransformMakeTranslation(0, 0);
        _whereAreYouGoingView.transform = CGAffineTransformMakeTranslation(0,-47);
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
    _contentList = [[NSMutableArray alloc] initWithArray:[_eventsParty getNameArray]];
    _filteredContentList = [[NSMutableArray alloc] initWithArray:_contentList];
    if (!_placesTableView) {
        _placesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
        _placesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.view addSubview:_placesTableView];
        _placesTableView.dataSource = self;
        _placesTableView.delegate = self;
        
        _yPositionOfWhereSubview = 280;
        [self initializeGoingSomewhereElseButton];
    }
    else {
        [_placesTableView reloadData];
    }
}


- (void) goOutHere:(id)sender {
    [Profile setIsGoingOut:YES];
    [self updatedTitleViewForGoingOut];
    UIButton *buttonSender = (UIButton *)sender;
    [[Profile user] setEventID:[NSNumber numberWithInt:buttonSender.tag]];
    [Network postGoingToEventNumber:buttonSender.tag];
    [self loadEvents];
}

- (void)initializeGoingSomewhereElseButton {
    _goingSomewhereButton = [[UIButton alloc] initWithFrame:CGRectMake(xSpacing, 10, self.view.frame.size.width, 68)];
    [_goingSomewhereButton addTarget:self action:@selector(goingSomewhereElsePressed) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *goingSomewhereLabel = [[UILabel alloc] initWithFrame:CGRectMake(67, _goingSomewhereButton.frame.size.height/2 - 7, 230, 15)];
    goingSomewhereLabel.text = @"GOING SOMEWHERE ELSE";
    goingSomewhereLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:18.0];
    goingSomewhereLabel.textColor = [FontProperties getBlueColor];
    [_goingSomewhereButton addSubview:goingSomewhereLabel];
    UIImageView *goingSomewhereImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"goingSomewhereElse"]];
    goingSomewhereImageView.frame = CGRectMake(_goingSomewhereButton.frame.size.height/2 - 15, 21, 23, 31);
    [_goingSomewhereButton addSubview:goingSomewhereImageView];
}

- (void) goingSomewhereElsePressed {
    [self showWhereAreYouGoingView];
    [_whereAreYouGoingTextField becomeFirstResponder];
}

- (void)profileSegue {
    self.profileViewController = [[ProfileViewController alloc] initWithProfile:YES];
    [self.navigationController pushViewController:self.profileViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
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
    [gotItButton addTarget:self action:@selector(gotItPressed) forControlEvents:UIControlEventTouchDown];
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
    
    _whereAreYouGoingTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 98, 47)];
    _whereAreYouGoingTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"WHERE ARE YOU GOING?" attributes:@{NSForegroundColorAttributeName:[FontProperties getLightBlueColor]}];
    _whereAreYouGoingTextField.font = [UIFont fontWithName:@"Whitney-MediumSC" size:15.0f];
    _whereAreYouGoingTextField.textColor = [FontProperties getBlueColor];
    [[UITextField appearance] setTintColor:[FontProperties getBlueColor]];
    _whereAreYouGoingTextField.delegate = self;
    [_whereAreYouGoingTextField addTarget:self
                                   action:@selector(textFieldDidChange:)
                         forControlEvents:UIControlEventEditingChanged];
    [_whereAreYouGoingView addSubview:_whereAreYouGoingTextField];
    
    [self addCreateButtonToTextField];
    
    _clearButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 18 - 90, _whereAreYouGoingView.frame.size.height/2 - 9, 18, 18)];
    [_clearButton addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clearButton"]]];
    [_clearButton addTarget:self action:@selector(clearTextField) forControlEvents:UIControlEventTouchUpInside];
    [_whereAreYouGoingView addSubview:_clearButton];
}

- (void)clearTextField {
    _whereAreYouGoingTextField.text = @"";
    [self textFieldDidChange:_whereAreYouGoingTextField];
}

- (void) addCreateButtonToTextField {
    _createButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 80, _whereAreYouGoingView.frame.size.height/2 - 10, 80, 20)];
    [_createButton setTitle:@"CREATE" forState:UIControlStateNormal];
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _createButton.backgroundColor = [FontProperties getBlueColor];
    [_createButton addTarget:self action:@selector(createPressed) forControlEvents:UIControlEventTouchDown];
    _createButton.titleLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:12.0f];
    _createButton.layer.cornerRadius = 5;
    _createButton.layer.borderWidth = 1;
    _createButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [_whereAreYouGoingView addSubview:_createButton];
    [_whereAreYouGoingView bringSubviewToFront:_createButton];
}

- (void)createPressed {
    NSNumber *eventID = [Network createEventWithName:_whereAreYouGoingTextField.text];
    NSLog(@"eventID %d", [eventID intValue]);
    [Network postGoingToEventNumber:[eventID intValue]];
    [Profile setIsGoingOut:YES];
    [self updatedTitleViewForGoingOut];
    [self loadEvents];
}

- (void)textFieldDidChange:(UITextField *)textField {
    [_filteredContentList removeAllObjects];
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
    [_placesTableView reloadData];
}


- (void)searchTableList:(NSString *)searchString {
    for (NSString *tempStr in _contentList) {
        NSArray *firstAndLastNameArray = [tempStr componentsSeparatedByString:@" "];
        for (NSString *firstOrLastName in firstAndLastNameArray) {
            NSComparisonResult result = [firstOrLastName compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchString length])];
            if (result == NSOrderedSame) {
                [_filteredContentList addObject:tempStr];
            }
        }
    }
}

#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return sizeOfEachCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (_isSearching) {
        return [_filteredContentList count] + 1;
    }
    else {
        return [_contentList count] + 1;
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    
    if (_isSearching) {
        if (indexPath.row == [_filteredContentList count]) {
            [cell.contentView addSubview:_goingSomewhereButton];
            return cell;
        }
    }
    else {
        if (indexPath.row == [_contentList count]) {
            [cell.contentView addSubview:_goingSomewhereButton];
            return cell;
        }
    }
    Event *event = [[_eventsParty getObjectArray] objectAtIndex:[indexPath row]];
    Party *partyUser = [_partyUserArray objectAtIndex:[indexPath row]];
    NSDictionary *summary = [_summaryArray objectAtIndex:[indexPath row]];
    NSNumber *totalUsers = [summary objectForKey:@"total"];
    
    UIView *placeSubView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, sizeOfEachCell)];
    placeSubView.tag = _tagInteger;
    _tagInteger += 1;
    
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(xSpacing, 5, self.view.frame.size.width, 30)];
    if (_isSearching) {
        if (indexPath.row < [_filteredContentList count]) {
            labelName.text = [_filteredContentList objectAtIndex:indexPath.row];
        }
    }
    else {
        if (indexPath.row < [_contentList count]) {
            labelName.text = [_contentList objectAtIndex:indexPath.row];
        }
    }
    labelName.font = [UIFont fontWithName:@"Whitney-MediumSC" size:18.0f];
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
   

    if (indexPath.row == 0 && ([[Profile user] eventID] != nil && [Profile isGoingOut])) {
        placeSubView.backgroundColor = [FontProperties getLightBlueColor];
        UILabel *goingHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(183, 5, 125, 30)];
        goingHereLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:13.0f];;
        goingHereLabel.textColor = [FontProperties getBlueColor];
        goingHereLabel.textAlignment = NSTextAlignmentRight;
        goingHereLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:12.0f];
        goingHereLabel.text = @"GOING HERE";
        [placeSubView addSubview:goingHereLabel];
    }
    else {
        UIButton *goOutButton = [[UIButton alloc] initWithFrame:CGRectMake(placeSubView.frame.size.width - 90, 10, 80, 20)];
        [goOutButton setTitle:@"GO HERE" forState:UIControlStateNormal];
        [goOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        goOutButton.backgroundColor = [FontProperties getBlueColor];
        goOutButton.tag = [(NSNumber *)[event eventID] intValue];
        [goOutButton addTarget:self action:@selector(goOutHere:) forControlEvents:UIControlEventTouchDown];
        goOutButton.titleLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:12.0f];
        goOutButton.layer.cornerRadius = 5;
        goOutButton.layer.borderWidth = 1;
        goOutButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
        [placeSubView addSubview:goOutButton];
    }

    for (int i = 0; i < [[partyUser getObjectArray] count]; i++) {
        User *user = [[partyUser getObjectArray] objectAtIndex:i];
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 55, sizeOfEachImage, sizeOfEachImage)];
        xPosition += sizeOfEachImage;
        [imagesScrollView addSubview:imageButton];
        imagesScrollView.contentSize = CGSizeMake(xPosition, placeSubView.frame.size.height);
        
        UIImageView *imgView = [[UIImageView alloc] init];
        [imgView setImageWithURL:[[user imagesURL] objectAtIndex:0]];
        imgView.frame = CGRectMake(0, 0, sizeOfEachImage, sizeOfEachImage);
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
    
    int usersCantSee = [totalUsers intValue] - [[partyUser getObjectArray] count];
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

#pragma mark - Network Asynchronous Functions

-(void)fetchEventSummaryAsynchronous {
    _summaryArray = [[NSMutableArray alloc] initWithCapacity:[[_eventsParty getObjectArray] count]];
    // Pre-populate Array
    for (int j = 0; j < [[_eventsParty getObjectArray] count]; j++) {
        [_summaryArray addObject:[[NSDictionary alloc] init]];
    }
    for (int i = 0; i < [[_eventsParty getObjectArray] count]; i++) {
        Event *event = [[_eventsParty getObjectArray] objectAtIndex:i];
        NSNumber *eventId = [event eventID];
        NSString *queryString = [NSString stringWithFormat:@"eventattendees/summary/?event=%@", [eventId stringValue]];
        NSDictionary *inputDictionary = @{@"i": [NSNumber numberWithInt:i]};
        [Network queryAsynchronousAPI:queryString
                  withInputDictionary:(NSDictionary *)inputDictionary
                          withHandler:^(NSDictionary *resultInputDictionary ,NSDictionary *jsonResponse, NSError *error) {
            if (jsonResponse) {
                int indexOfEvent = [[resultInputDictionary objectForKey:@"i"] intValue];
                [_summaryArray insertObject:jsonResponse atIndex:indexOfEvent];
            }
            [self fetchedOneParty];
        }];
    }
}

- (void)fetchEventAttendeesAsynchronous {
    _partyUserArray =  [[NSMutableArray alloc] initWithCapacity:[[_eventsParty getObjectArray] count]];
    // Pre-populate Array
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
                              for (int i = 0; i < [eventAttendeesArray count]; i++) {
                                  NSDictionary *eventAttendee = [eventAttendeesArray objectAtIndex:i];
                                  User *user;
                                  if ([[eventAttendee objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                                      user = [[User alloc] initWithDictionary:[eventAttendee objectForKey:@"user"]];
                                  }
                                  else {
                                      user = (User *)[_everyoneParty getObjectWithId:[eventAttendee objectForKey:@"user"]];
                                  }
                                  if ([user isEqualToUser:[Profile user]]) {
                                      [Profile setIsGoingOut:YES];
                                      [[Profile user] setEventID:eventId];
                                  }
                                  [partyUser addObject:user];
                              }
                              int indexOfEvent = [[resultInputDictionary objectForKey:@"i"] intValue];
                              [_partyUserArray insertObject:partyUser atIndex:indexOfEvent];
                              [self fetchedOneParty];
        }];
    }
}

- (void)fetchedOneParty {
    numberOfFetchedParties += 1;
    if (numberOfFetchedParties >= 2*[[_eventsParty getObjectArray] count]) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self initializeWhereView];
        });
    }
}

@end
