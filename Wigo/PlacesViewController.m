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
#import "SignViewController.h"
#import "SignNavigationViewController.h"
#import "PeekViewController.h"
#import "ReProfileViewController.h"
#import "EventStoryViewController.h"
#import "FancyProfileViewController.h"

#define sizeOfEachCell 180
#define kEventCellName @"EventCell"
#define kHighlightOldEventCel @"HighlightOldEventCell"
#define kOldEventCellName @"OldEventCell"
#define kHeaderOldEventCellName @"HeaderOldEventCell"


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
@property Party *oldEventsParty;
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
int sizeOfEachImage;
BOOL shouldReloadEvents;
int firstIndexOfNegativeEvent;

@implementation PlacesViewController {
    int numberOfFetchedParties;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.automaticallyAdjustsScrollViewInsets = NO;
    eventPageArray = [[NSMutableArray alloc] init];
    fetchingEventAttendees = NO;
    shouldAnimate = NO;
    presentedMobileContacts = NO;
    shouldReloadEvents = YES;
    firstIndexOfNegativeEvent = -1;
    self.eventOffsetDictionary = [NSMutableDictionary new];
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
    
    [self initializeFlashScreen];

    _spinnerAtCenter = YES;
    [self initializeTapHandler];
    [self initializeWhereView];


}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initializeNotificationObservers];
    [self initializeNavigationBar];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
}

- (void) viewDidAppear:(BOOL)animated {
    [EventAnalytics tagEvent:@"Where View"];

    [self.view endEditing:YES];
    [self fetchIsThereNewPerson];
    if (shouldReloadEvents) {
        [self fetchEventsFirstPage];
    }
    else {
        shouldReloadEvents = YES;
    }
}



- (void) initializeNavigationBar {
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;

    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        CGRect profileFrame = CGRectMake(0, 0, 30, 30);
        UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        [profileImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]] placeholderImage:[[UIImage alloc] init] imageArea:[[Profile user] coverImageArea]];
        [profileButton addSubview:profileImageView];
        [profileButton addTarget:self action:@selector(profileSegue)
                forControlEvents:UIControlEventTouchUpInside];
        [profileButton setShowsTouchWhenHighlighted:YES];
        if ([(NSNumber *)[[Profile user] objectForKey:@"num_unread_conversations"] intValue] > 0 &&
            [(NSNumber *)[[Profile user] objectForKey:@"num_unread_notifications"] intValue] > 0) {
            UILabel *redDotLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, 10, 10)];
            redDotLeftLabel.backgroundColor = [UIColor redColor];
            redDotLeftLabel.layer.borderColor = [UIColor clearColor].CGColor;
            redDotLeftLabel.clipsToBounds = YES;
            redDotLeftLabel.layer.borderWidth = 3;
            redDotLeftLabel.layer.cornerRadius = 5;
            [profileButton addSubview:redDotLeftLabel];
        }
        UIBarButtonItem *profileBarButton = [[UIBarButtonItem alloc] initWithCustomView:profileButton];
        self.navigationItem.leftBarButtonItem = profileBarButton;
        
        self.rightButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 10, 30, 30) andType:@3];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 8, 22, 17)];
        imageView.image = [UIImage imageNamed:@"followPlusBlue"];
        [self.rightButton addTarget:self action:@selector(followPressed)
                   forControlEvents:UIControlEventTouchUpInside];
        [self.rightButton addSubview:imageView];
        [self.rightButton setShowsTouchWhenHighlighted:YES];
        UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.rightButton];
        self.navigationItem.rightBarButtonItem = rightBarButton;
        self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    }
    else {
        self.navigationController.navigationBar.barTintColor = RGB(100, 173, 215);
    }
  

    [self updateTitleView];
}

- (void)initializeFlashScreen {
    SignViewController *signViewController = [[SignViewController alloc] init];
    SignNavigationViewController *signNavigationViewController = [[SignNavigationViewController alloc] initWithRootViewController:signViewController];
    [self presentViewController:signNavigationViewController animated:NO completion:nil];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadViewAfterSigningUser)
                                                 name:@"loadViewAfterSigningUser"
                                               object:nil];

}

- (void)loadViewAfterSigningUser {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canFetchAppStartup"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchAppStart" object:nil];
}


- (void)scrollUp {
    [_placesTableView setContentOffset:CGPointZero animated:YES];
}

- (void) updateViewNotGoingOut {
    [[Profile user] setIsGoingOut:NO];
    [self updateTitleView];
    [self fetchEventsFirstPage];
}

- (void) updateTitleView {
    if (!self.groupName) self.groupName = [[Profile user] groupName];
    UIButton *schoolButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [schoolButton setTitle:self.groupName forState:UIControlStateNormal];
    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        [schoolButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    }
    else {
        [schoolButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    [schoolButton addTarget:self action:@selector(showSchools) forControlEvents:UIControlEventTouchUpInside];
    schoolButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  
    CGFloat fontSize = 20.0f;
    CGSize size;
    while (fontSize > 0.0f)
    {
        size = [self.groupName sizeWithAttributes:
                       @{NSFontAttributeName:[FontProperties scMediumFont:fontSize]}];
        //TODO: not use fixed length
        if (size.width <= 210) break;
        
        fontSize -= 2.0;
    }
    schoolButton.titleLabel.font = [FontProperties scMediumFont:fontSize];

    UIImageView *triangleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(size.width + 5, 0, 6, 5)];
    
    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        [schoolButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
        triangleImageView.image = [UIImage imageNamed:@"blueTriangle"];
    }
    else {
        [schoolButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        triangleImageView.image = [UIImage imageNamed:@"whiteTriangle"];
    }
    [schoolButton addSubview:triangleImageView];

    
    self.navigationItem.titleView = schoolButton;
}

- (void)showSchools {
    PeekViewController *peekViewController = [PeekViewController new];
    peekViewController.placesDelegate = self;
    [self presentViewController:peekViewController animated:YES completion:nil];
}

- (void)initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    _ungoOutButton.enabled = YES;
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
    if (touch.view == _createButton) {
        [self createPressed];
    }
    return YES;
}

- (void)initializeWhereView {
    _placesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    _placesTableView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:_placesTableView];
    _placesTableView.dataSource = self;
    _placesTableView.delegate = self;
    _placesTableView.showsVerticalScrollIndicator = NO;
    [_placesTableView setSeparatorColor:UIColor.clearColor];
    [_placesTableView registerClass:[EventCell class] forCellReuseIdentifier:kEventCellName];
    [_placesTableView registerClass:[HighlightOldEventCell class] forCellReuseIdentifier:kHighlightOldEventCel];
    [_placesTableView registerClass:[OldEventCell class] forCellReuseIdentifier:kOldEventCellName];
    [_placesTableView registerClass:[HeaderOldEventCell class] forHeaderFooterViewReuseIdentifier:kHeaderOldEventCellName];
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

- (void)followPressed {
    if ([Profile user]) {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
        [self.navigationController pushViewController:[[PeopleViewController alloc] initWithUser:[Profile user]] animated:YES];
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
    [self updateTitleView];
    [[Profile user] setEventID:eventID];
    [Network postGoingToEventNumber:[eventID intValue]];
    [self fetchEventsFirstPage];
}

- (void)initializeGoingSomewhereElseButton {
    _goingSomewhereButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 55, self.view.frame.size.height - 55, 45, 45)];
    [_goingSomewhereButton addTarget:self action:@selector(goingSomewhereElsePressed) forControlEvents:UIControlEventTouchUpInside];
    _goingSomewhereButton.backgroundColor = [FontProperties getBlueColor];
    _goingSomewhereButton.layer.borderWidth = 1.0f;
    _goingSomewhereButton.layer.borderColor = [UIColor clearColor].CGColor;
    _goingSomewhereButton.layer.cornerRadius = 20;
    _goingSomewhereButton.layer.shadowColor = [UIColor blackColor].CGColor;
    _goingSomewhereButton.layer.shadowOpacity = 0.4f;
    _goingSomewhereButton.layer.shadowRadius = 5.0f;
    _goingSomewhereButton.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    [self.view addSubview:_goingSomewhereButton];
    [self.view bringSubviewToFront:_goingSomewhereButton];
    
    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 15, 15)];
    sendOvalImageView.image = [UIImage imageNamed:@"plusStoryButton"];
    [_goingSomewhereButton addSubview:sendOvalImageView];
}

- (void) goingSomewhereElsePressed {
    [self scrollUp];
    [self dismissKeyboard];
    [self showWhereAreYouGoingView];
    _ungoOutButton.enabled = NO;
    [_whereAreYouGoingTextField becomeFirstResponder];
    _placesTableView.userInteractionEnabled = NO;
    [self textFieldDidChange:_whereAreYouGoingTextField];
}

- (void)profileSegue {
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: [Profile user]];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: fancyProfileViewController];
    
    [self presentViewController:navController animated:YES completion:nil];
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
    _whereAreYouGoingTextField.returnKeyType = UIReturnKeyDone;
    [_whereAreYouGoingView addSubview:_whereAreYouGoingTextField];
    
    [self addCreateButtonToTextField];
    
    _clearButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 25 - 100, _whereAreYouGoingView.frame.size.height/2 - 9, 25, 25)];
    [_clearButton addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clearButton"]]];
    [_clearButton addTarget:self action:@selector(clearTextField) forControlEvents:UIControlEventTouchUpInside];
    [_whereAreYouGoingView addSubview:_clearButton];
}

- (void)clearTextField {
    _placesTableView.userInteractionEnabled = YES;
    _whereAreYouGoingTextField.text = @"";
    [self textFieldDidChange:_whereAreYouGoingTextField];
}


- (void) addCreateButtonToTextField {
    _createButton = [[UIButton alloc] initWithFrame:CGRectMake(_whereAreYouGoingView.frame.size.width - 90, _whereAreYouGoingView.frame.size.height/2 - 12, 80, 25)];
    [_createButton setTitle:@"CREATE" forState:UIControlStateNormal];
    _createButton.isAccessibilityElement = YES;
    _createButton.accessibilityLabel = @"Create";
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
        [self updateTitleView];
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

    [_placesTableView reloadData];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self createPressed];
    return YES;
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
    if ([indexPath section] == 0) {
        if ([indexPath row] == [[_contentParty getObjectArray] count]) {
            return 70;
        }
        if (firstIndexOfNegativeEvent >= 0 && [indexPath row] >= firstIndexOfNegativeEvent) {
            return 70;
        }
        return sizeOfEachCell;

    }
    Event *event = (Event *)[[_oldEventsParty getObjectArray] objectAtIndex:[indexPath row]];
    if ([event containsHighlight]) {
        return 304;
    }
    else return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (_isSearching) {
            return [[_filteredContentParty getObjectArray] count];
        }
        else {
            int hasNextPage = ([_eventsParty hasNextPage] ? 1 : 0);
            return [[_contentParty getObjectArray] count] + hasNextPage;
        }
    }
    else return [[_oldEventsParty getObjectArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        EventCell *cell = [tableView dequeueReusableCellWithIdentifier:kEventCellName];

        cell.placesDelegate = self;
        if (_isSearching) {
            if (indexPath.row == [[_filteredContentParty getObjectArray] count]) {
                return cell;
            }
        }
        else {
            if (indexPath.row == [[_contentParty getObjectArray] count]) {
                [self fetchEvents];
                return cell;
            }
        }
        
        Event *event;
        if (_isSearching) {
            int sizeOfArray = (int)[[_filteredContentParty getObjectArray] count];
            if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
            event = [[Event alloc] initWithDictionary:[[_filteredContentParty getObjectArray] objectAtIndex:[indexPath row]]];
        }
        else {
            int sizeOfArray = (int)[[_contentParty getObjectArray] count];
            if (sizeOfArray == 0 || sizeOfArray <= [indexPath row]) return cell;
            event = [[_contentParty getObjectArray] objectAtIndex:[indexPath row]];
        }
        cell.event = event;
        if (self.groupNumberID) {
            cell.eventPeopleScrollView.groupID = self.groupNumberID;
        }
        else {
            cell.eventPeopleScrollView.groupID = nil;
        }
        cell.eventPeopleScrollView.placesDelegate = self;
        if ([[self.eventOffsetDictionary allKeys] containsObject:[[event eventID] stringValue]]) {
            cell.eventPeopleScrollView.contentOffset = CGPointMake([(NSNumber *)[self.eventOffsetDictionary objectForKey:[[event eventID] stringValue]] intValue],0);
        }
        [cell updateUI];
        if ([[[event dictionary] objectForKey:@"is_read"] boolValue]) {
            cell.chatBubbleImageView.image = [UIImage imageNamed:@"grayChatBubble"];
        }
        else {
            cell.chatBubbleImageView.image = [UIImage imageNamed:@"chatBubble"];
        }
        if ( ([[[Profile user] attendingEventID] intValue] < 0 && [indexPath row] == 0) ||
            ([[Profile user] isGoingOut] && [[Profile user] isAttending] && [[[Profile user] attendingEventID] isEqualToNumber:[event eventID]])
            ) {
            cell.backgroundColor = [FontProperties getLightBlueColor];
        }
        else {
            cell.backgroundColor = UIColor.whiteColor;
        }
        return cell;
    }
    else {
        Event *event = (Event *)[[_oldEventsParty getObjectArray] objectAtIndex:[indexPath row]];
        if ([event containsHighlight]) {
            HighlightOldEventCell *cell = [tableView dequeueReusableCellWithIdentifier:kHighlightOldEventCel];
            cell.event = event;
            cell.placesDelegate = self;
            cell.oldEventLabel.text = [event name];
            if ([event.numberOfMessages intValue] > 0) {
                cell.chatBubbleImageView.hidden = NO;
                cell.chatNumberLabel.text = [NSString stringWithFormat:@"%@", [event.numberOfMessages stringValue]];
            }
            NSString *contentURL = [[[event dictionary] objectForKey:@"highlight"] objectForKey:@"media"];
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
            [cell.highlightImageView setImageWithURL:imageURL];
            return cell;
        }
        else {
            OldEventCell *cell = [tableView dequeueReusableCellWithIdentifier:kOldEventCellName];
            cell.placesDelegate = self;
            cell.oldEventLabel.text = [event name];
            if ([event.numberOfMessages intValue] > 0) {
                cell.chatBubbleImageView.hidden = NO;
                cell.chatNumberLabel.text = [NSString stringWithFormat:@"%@", [event.numberOfMessages stringValue]];
            }
            return cell;
        }
      
    }
  
}

#pragma mark - PlacesDelegate

- (void)showUser:(User *)user {
    shouldReloadEvents = NO;
    
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: user];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: fancyProfileViewController];
    
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showConversationForEvent:(Event *)event {
    NSString *queryString = [NSString stringWithFormat:@"eventmessages/?event=%@", [event eventID]];
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:queryString
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{                                            NSMutableArray *eventMessages = [NSMutableArray arrayWithArray:(NSArray *)[jsonResponse objectForKey:@"objects"]];
                                    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                    EventConversationViewController *conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
                                    conversationViewController.event = event;
                                    conversationViewController.index = 0;
                                    conversationViewController.eventMessages = eventMessages;
                                    [self presentViewController:conversationViewController animated:YES completion:nil];
                                });
                            }];
}

- (void)showStoryForEvent:(Event*)event {
    EventStoryViewController *eventStoryController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventStoryViewController"];
    eventStoryController.placesDelegate = self;
    eventStoryController.event = event;
    [self presentViewController:eventStoryController animated:YES completion:nil];
}

- (void)setGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName {
    self.eventOffsetDictionary = [NSMutableDictionary new];
    self.groupNumberID = groupID;
    self.groupName = groupName;
    [self updateTitleView];
    [self fetchEventsFirstPage];
}

- (int)createUniqueIndexFromUserIndex:(int)userIndex andEventIndex:(int)eventIndex {
    int numberOfEvents = (int)[[_eventsParty getObjectArray] count];
    return numberOfEvents * userIndex + eventIndex;
}

- (void)updateEvent:(Event *)newEvent {
    for (int i = 0 ; i < [[_contentParty getObjectArray] count]; i++) {
        Event *event = [[_contentParty getObjectArray] objectAtIndex:i];
        if ([[event eventID] isEqualToNumber:[newEvent eventID]]) {
            [_contentParty replaceObjectAtIndex:i withObject:newEvent];
            break;
        }
    }
}

- (NSDictionary *)getUserIndexAndEventIndexFromUniqueIndex:(int)uniqueIndex {
    int userIndex, eventIndex;
    int numberOfEvents = (int)[[_eventsParty getObjectArray] count];
    userIndex = uniqueIndex/numberOfEvents;
    eventIndex = uniqueIndex - userIndex * numberOfEvents;
    return @{@"userIndex": [NSNumber numberWithInt:userIndex], @"eventIndex":[NSNumber numberWithInt:eventIndex]};
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
    if (section == 0)  return 0;
    if ([[_oldEventsParty  getObjectArray] count] > 0) return 49;
    else return 0;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section {
    HeaderOldEventCell *headerOldEventCell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderOldEventCellName];
    headerOldEventCell.headerTitleLabel.text = @"Fuzzy on Yesterday? Check out ";
    return headerOldEventCell;
}


#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != _placesTableView)
        if (scrollView.contentOffset.x + self.view.frame.size.width >= scrollView.contentSize.width - sizeOfEachImage && !fetchingEventAttendees) {
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
    if (!fetchingEventAttendees && [[Profile user] key]) {
        fetchingEventAttendees = YES;
        if (_spinnerAtCenter) [WiGoSpinnerView addDancingGToCenterView:self.view];
        NSString *queryString;
        if (self.groupNumberID) {
             queryString = [NSString stringWithFormat:@"events/?group=%@&page=%@&attendees_limit=10", [self.groupNumberID stringValue], [page stringValue]];
        }
        else {
            if (![page isEqualToNumber:@1] && [_eventsParty nextPageString]) {
                queryString = [_eventsParty nextPageString];
            }
            else {
                queryString = [NSString stringWithFormat:@"events/?page=%@&attendees_limit=10", [page stringValue]];
            }

        }
        [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            if ([page isEqualToNumber:@1]) {
                numberOfFetchedParties = 0;
                _eventsParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
                _oldEventsParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
                _contentParty = _eventsParty;
                _filteredContentParty = [[Party alloc] initWithObjectType:EVENT_TYPE];
            }
            NSArray *events = [jsonResponse objectForKey:@"objects"];
            NSDictionary *separatedEvents = [self separateEvents:events];
            NSArray *oldEvents = [separatedEvents objectForKey:@"oldEvents"];
            NSArray *newEvents = [separatedEvents objectForKey:@"newEvents"];
            [self getFirstIndexOfSuggestedEvent:events];
            [_eventsParty addObjectsFromArray:newEvents];
            [_oldEventsParty addObjectsFromArray:oldEvents];
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

- (NSDictionary *)separateEvents:(NSArray *)events {
    NSMutableArray *mutableOldEvents = [NSMutableArray new];
    NSMutableArray *newEvents = [NSMutableArray new];
    NSIndexSet *indexSet = [events indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *eventDictionary = (NSDictionary *)obj;
        if ([[eventDictionary objectForKey:@"is_expired"] boolValue]) {
            return YES;
        }
        else return NO;
    }];
    for (int i = 0; i < [events count]; i++) {
        if ([indexSet containsIndex:(NSUInteger)i]) {
            [mutableOldEvents addObject:[events objectAtIndex:i]];
        }
        else {
            [newEvents addObject:[events objectAtIndex:i]];
        }
    }
    return @{@"oldEvents": [NSArray arrayWithArray:mutableOldEvents],
             @"newEvents": [NSArray arrayWithArray:newEvents]
             };
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
    firstIndexOfNegativeEvent = (int)index;
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
            if ([[eventAttendee allKeys] containsObject:@"event_owner"]) {
                [user setIsEventOwner:[[eventAttendee objectForKey:@"event_owner"] boolValue]];
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
            if (!pageNumberForEvent)  pageNumberForEvent = @2;
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
                                          [_placesTableView beginUpdates];
                                          [_placesTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:eventNumber inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                                          [_placesTableView endUpdates];
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
                    [self updateTitleView];
                }
            }
            else {
                User *user = [[User alloc] initWithDictionary:jsonResponse];
                [Profile setUser:user];
                [self updateTitleView];
            }
        });
    }];
}

- (void) fetchIsThereNewPerson {
    if (!self.fetchingIsThereNewPerson && [[Profile user] key]) {
        self.fetchingIsThereNewPerson = YES;
        [Network queryAsynchronousAPI:@"users/?limit=1" withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
            NSArray *objects = [jsonResponse objectForKey:@"objects"];
            if ([objects isKindOfClass:[NSArray class]]) {
                User *lastUserJoined = [[User alloc] initWithDictionary:[objects objectAtIndex:0]];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    User *profileUser = [Profile user];
                    if (profileUser) {
                        NSNumber *lastUserRead = [profileUser lastUserRead];
                        NSNumber *lastUserJoinedNumber = (NSNumber *)[lastUserJoined objectForKey:@"id"];
                        [Profile setLastUserJoined:lastUserJoinedNumber];
                        [self.rightButton.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 8, 22, 17)];
                        imageView.image = [UIImage imageNamed:@"followPlusBlue"];
                        [self.rightButton addSubview:imageView];
                        
                        if ([lastUserRead intValue] < [lastUserJoinedNumber intValue]) {
                            self.redDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 3, 10, 10)];
                            self.redDotLabel.backgroundColor = [UIColor redColor];
                            self.redDotLabel.layer.borderColor = [UIColor clearColor].CGColor;
                            self.redDotLabel.clipsToBounds = YES;
                            self.redDotLabel.layer.borderWidth = 3;
                            self.redDotLabel.layer.cornerRadius = 5;
                            [self.rightButton addSubview:self.redDotLabel];
                        }
                        else {
                            if (self.redDotLabel) [self.redDotLabel removeFromSuperview];
                        }
                    }
                    self.fetchingIsThereNewPerson = NO;
                });
            }
        }];
    }
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

@implementation EventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, sizeOfEachCell);
    self.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.eventNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, self.frame.size.width - 75, 50)];
    self.eventNameLabel.numberOfLines = 2;

    self.eventNameLabel.font = [FontProperties scMediumFont: 20];
    self.eventNameLabel.textColor = RGB(100, 173, 215);
    [self.contentView addSubview:self.eventNameLabel];
    
    self.chatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 55, 15, 20, 20)];
    self.chatBubbleImageView.image = [UIImage imageNamed:@"chatBubble"];
    self.chatBubbleImageView.center = CGPointMake(self.chatBubbleImageView.center.x, self.eventNameLabel.center.y);
    self.chatBubbleImageView.hidden = YES;
    [self.contentView addSubview:self.chatBubbleImageView];
    
    self.chatNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 15)];
    self.chatNumberLabel.textAlignment = NSTextAlignmentCenter;
    self.chatNumberLabel.font = [FontProperties mediumFont:12.0f];

    self.chatNumberLabel.textColor = [UIColor whiteColor];
    [self.chatBubbleImageView addSubview:self.chatNumberLabel];
    
    self.postStoryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 13, 13, 22)];
    self.postStoryImageView.center = CGPointMake(self.postStoryImageView.center.x, self.eventNameLabel.center.y);
    self.postStoryImageView.image = [UIImage imageNamed:@"postStory"];
    [self.contentView addSubview:self.postStoryImageView];

    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    self.eventPeopleScrollView.frame = CGRectMake(10, 60, self.frame.size.width - 10, 120);
    self.eventPeopleScrollView.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.eventPeopleScrollView];
    
    UIButton *eventFeedButton = [[UIButton alloc] initWithFrame:CGRectMake(self.eventNameLabel.frame.origin.x, self.eventNameLabel.frame.origin.y, self.frame.size.width - self.eventNameLabel.frame.origin.x, self.eventNameLabel.frame.size.height)];
    eventFeedButton.backgroundColor = [UIColor clearColor];
    [eventFeedButton addTarget: self action: @selector(showEventConversation) forControlEvents: UIControlEventTouchUpInside];
    [self.contentView addSubview: eventFeedButton];
    
    UILabel *lineSeparator = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 1)];
    lineSeparator.backgroundColor = [FontProperties getBlueColor];
    [self.contentView addSubview:lineSeparator];
}

- (void)updateUI {
    self.eventNameLabel.text = [self.event name];
    if ([self.event.numberOfMessages intValue] > 0) {
        self.chatBubbleImageView.hidden = NO;
        self.chatNumberLabel.text = [NSString stringWithFormat:@"%@", [self.event.numberOfMessages stringValue]];
    }
    else self.chatBubbleImageView.hidden = YES;
    self.eventPeopleScrollView.event = self.event;
    [self.eventPeopleScrollView updateUI];
}

- (void)setOffset:(int)offset forIndexPath:(NSIndexPath *)indexPath {
    
}


- (void)showEventConversation {
    [self.placesDelegate showStoryForEvent:self.event];
}

@end

@implementation TitleHeaderEventCell

- (void)setupTitleHeader {
    self.oldEventLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, self.frame.size.width - 75, 50)];
    self.oldEventLabel.textAlignment = NSTextAlignmentLeft;
    self.oldEventLabel.font = [FontProperties mediumFont:18.0f];
    self.oldEventLabel.textColor = RGB(184, 184, 184);
    [self.contentView addSubview:self.oldEventLabel];
    
    self.chatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 55, 15, 20, 20)];
    self.chatBubbleImageView.image = [UIImage imageNamed:@"grayChatBubble"];
    self.chatBubbleImageView.hidden = YES;
    [self.contentView addSubview:self.chatBubbleImageView];
    
    self.chatNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 15)];
    self.chatNumberLabel.textAlignment = NSTextAlignmentCenter;
    self.chatNumberLabel.font = [FontProperties mediumFont:12.0f];
    self.chatNumberLabel.textColor = [UIColor whiteColor];
    [self.chatBubbleImageView addSubview:self.chatNumberLabel];
    
    UIImageView *postStoryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 13, 13, 22)];
    postStoryImageView.image = [UIImage imageNamed:@"postStory"];
    [self.contentView addSubview:postStoryImageView];
    
    UILabel *borderLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, self.frame.size.width - 20, self.frame.size.height - 10)];
    borderLabel.layer.borderColor = RGB(176, 209, 228).CGColor;
    borderLabel.layer.borderWidth = 1.5f;
    borderLabel.layer.cornerRadius = 8;
    [self.contentView addSubview:borderLabel];
}

@end

@implementation HighlightOldEventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 304);
    self.backgroundColor = UIColor.whiteColor;
    [super setupTitleHeader];
    self.highlightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 50, self.frame.size.width - 20, 254)];
    self.highlightImageView.clipsToBounds = YES;
    self.highlightImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.highlightImageView];
    
    UIButton *conversationButton = [[UIButton alloc] initWithFrame:self.frame];
    [conversationButton addTarget:self action:@selector(loadConversation) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:conversationButton];
}

- (void)loadConversation {
    [self.placesDelegate showConversationForEvent:self.event];
}

@end

@implementation OldEventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
    self.backgroundColor = UIColor.whiteColor;
    [super setupTitleHeader];
}

@end

@implementation HeaderOldEventCell
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 49);
    self.contentView.backgroundColor = UIColor.whiteColor;
   
    self.headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, self.frame.size.width, 39)];
    self.headerTitleLabel.textColor = RGB(155, 155, 155);
    self.headerTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.headerTitleLabel.font = [FontProperties scMediumFont:14.0f];
    [self.contentView addSubview:self.headerTitleLabel];
}
@end

