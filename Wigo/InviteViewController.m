//
//  InviteViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "InviteViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import "MobileContactsViewController.h"

@interface InviteViewController() {
    NSArray *mobileContacts;
    NSMutableArray *filteredMobileContacts;
    NSMutableArray *chosenPeople;
    WGEvent *event;
    UISearchBar *searchBar;
}

@end

@implementation InviteViewController

- (id)initWithEvent:(WGEvent *)newEvent {
    self = [super init];
    if (self) {
        event = newEvent;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mobileContacts = [NSArray new];
    filteredMobileContacts = [NSMutableArray new];
    NSSet *savedChosenPeople = [[NSUserDefaults standardUserDefaults] valueForKey:@"chosenPeople"];
    if (savedChosenPeople) chosenPeople = [NSMutableArray arrayWithArray:[savedChosenPeople allObjects]];
    else chosenPeople = [NSMutableArray new];
    [self getMobileContacts];
    [self fetchFirstPageEveryone];
    [self fetchSuggestions];
    [self initializeTitle];
    [self initializeTableInvite];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagView:@"invite"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}


- (void)initializeTitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, self.view.frame.size.width - 20, 30)];
    titleLabel.text = @"Invite";
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:titleLabel];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 64 - 1, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGBAlpha(122, 193, 226, 0.1f);
    [self.view addSubview:lineView];

    UIButton *aroundDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(15 - 5, 40 - 5, 60 + 10, 15 + 10)];
    [aroundDoneButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [aroundDoneButton setShowsTouchWhenHighlighted:YES];
    [self.view addSubview:aroundDoneButton];
    UILabel *doneLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, 60, 15)];
    doneLabel.text = @"Done";
    doneLabel.textColor = [FontProperties getBlueColor];
    doneLabel.textAlignment = NSTextAlignmentLeft;
    doneLabel.font = [FontProperties getTitleFont];
    [aroundDoneButton addSubview:doneLabel];
    
    UIButton *aroundMobileButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 10 - 70, 40 - 5, 60 + 10, 15 + 10)];
    [aroundMobileButton addTarget:self action:@selector(mobilePressed) forControlEvents:UIControlEventTouchUpInside];
    [aroundMobileButton setShowsTouchWhenHighlighted:YES];
    [self.view addSubview:aroundMobileButton];
    UILabel *mobileLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, 60, 15)];
    mobileLabel.text = @"Mobile";
    mobileLabel.textColor = [FontProperties getBlueColor];
    mobileLabel.textAlignment = NSTextAlignmentRight;
    mobileLabel.font = [FontProperties getTitleFont];
    [aroundMobileButton addSubview:mobileLabel];
}


- (void)mobilePressed {
    [self presentViewController:[MobileContactsViewController new] animated:YES completion:nil];
}

- (void)donePressed {
    NSArray *savedChosenPeople = [[NSUserDefaults standardUserDefaults] valueForKey:@"chosenPeople"];
    if (savedChosenPeople) {
        NSMutableSet *newChosenPeople = [NSMutableSet setWithArray:savedChosenPeople];
        [newChosenPeople addObjectsFromArray:chosenPeople];
        [[NSUserDefaults standardUserDefaults] setValue:[newChosenPeople allObjects] forKey:@"chosenPeople"];
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:chosenPeople forKey:@"chosenPeople"];
    }
    NSMutableSet *differenceChosenPeople = [NSMutableSet setWithArray:chosenPeople];
    for (NSString *record in savedChosenPeople) {
        [differenceChosenPeople removeObject:record];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [MobileDelegate sendChosenPeople:[differenceChosenPeople allObjects] forContactList:mobileContacts];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initializeTableInvite {
    self.invitePeopleTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    [self.invitePeopleTableView registerClass:[TapCell class] forCellReuseIdentifier:kTapCellName];
    [self.invitePeopleTableView registerClass:[TapAllCell class] forCellReuseIdentifier:kTapAllName];
    [self.invitePeopleTableView registerClass:[FollowCell class] forCellReuseIdentifier:kFollowCellName];
    self.invitePeopleTableView.dataSource = self;
    self.invitePeopleTableView.delegate = self;
    self.invitePeopleTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 40)];
    searchBar.placeholder = @"Search By Name";
    searchBar.delegate = self;
    self.invitePeopleTableView.tableHeaderView = searchBar;
    self.invitePeopleTableView.contentOffset = CGPointMake(0, 40);
    [self.view addSubview:self.invitePeopleTableView];
}


#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionTapAllCell) {
        return [TapCell height];
    }
    else if (indexPath.section == kSectionTapCell) {
        return [TapCell height];
    }
    return [FollowCell height];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionTapAllCell) {
        if ([WGProfile.currentUser isEqual:event.owner]) return 1;
        else return 0;
    }
    else if (section == kSectionTapCell) {
//        return 5;
        return self.presentedUsers.count + self.presentedUsers.hasNextPage.intValue;
    }
    else if (section == kSectionAllFriends) {
        return self.presentedUsers.count + self.presentedUsers.hasNextPage.intValue;
    }
    else {
        if (self.presentedUsers.total.intValue > 10) {
            return 0;
        }
        return MIN(self.presentedSuggestions.count, 5);
//        return 0;
//        if (self.presentedUsers.count + self.presentedUsers.hasNextPage.intValue >= 11) {
//            return 0;
//        }
//        return MIN(self.presentedSuggestions.count, 5);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionTapAllCell) {
        TapAllCell *tapAllCell = (TapAllCell *)[tableView dequeueReusableCellWithIdentifier:kTapAllName forIndexPath:indexPath];
        [tapAllCell.aroundTapButton addTarget:self action:@selector(tapAllPressed) forControlEvents:UIControlEventTouchUpInside];
        return tapAllCell;
    }
    else if (indexPath.section == kSectionTapCell ) {
        TapCell *cell = (TapCell*)[tableView dequeueReusableCellWithIdentifier:kTapCellName forIndexPath:indexPath];
        cell.fullNameLabel.text = nil;
        cell.profileImageView.image = nil;
        cell.goingOutLabel.text = nil;
        cell.tapImageView.image = nil;
        
        int tag = (int)indexPath.row;
        WGUser *user;
        if (self.presentedUsers.count == 0) return cell;
        if (tag < self.presentedUsers.count) {
            user = (WGUser *)[self.presentedUsers objectAtIndex:tag];
        }
        if (user) {
            cell.user = user;
            [cell.aroundTapButton removeTarget:nil
                                        action:NULL
                              forControlEvents:UIControlEventAllEvents];
            [cell.aroundTapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.aroundTapButton.tag = indexPath.row;
        }
        
        return cell;
    }
    else if (indexPath.section == kSectionAllFriends) {
        TapCell *cell = (TapCell*)[tableView dequeueReusableCellWithIdentifier:kTapCellName forIndexPath:indexPath];
        cell.fullNameLabel.text = nil;
        cell.profileImageView.image = nil;
        cell.goingOutLabel.text = nil;
        cell.tapImageView.image = nil;
        
        int tag = (int)indexPath.row;
        WGUser *user;
        if (self.presentedUsers.count == 0) return cell;
        if (tag < self.presentedUsers.count) {
            user = (WGUser *)[self.presentedUsers objectAtIndex:tag];
        }
        if (tag == self.presentedUsers.count - 5 || tag == self.presentedUsers.count - 1) {
            [self getNextPage];
        }
        if (user) {
            cell.user = user;
            [cell.aroundTapButton removeTarget:nil
                                        action:NULL
                              forControlEvents:UIControlEventAllEvents];
            [cell.aroundTapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.aroundTapButton.tag = indexPath.row;
        }
        
        return cell;
    }
    
    if (indexPath.section == kSectionFollowCell) {
        FollowCell *cell = (FollowCell *)[tableView dequeueReusableCellWithIdentifier:kFollowCellName forIndexPath:indexPath];
        cell.profileImageView.image = nil;
        cell.nameLabel.text = nil;
        if (self.presentedSuggestions.count == 0) return cell;
        if (indexPath.row < self.presentedSuggestions.count) {
            WGUser *user = (WGUser *)[self.presentedSuggestions objectAtIndex:indexPath.row];
            cell.followPersonButton.tag = (int)indexPath.row;
            [cell.followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.user = user;
        }
        return cell;
    }
//    else  {
//        ABRecordRef contactPerson;
//        if (self.isSearching)
//            contactPerson  = (__bridge ABRecordRef)([filteredMobileContacts objectAtIndex:indexPath.row]);
//        else
//            contactPerson = (__bridge ABRecordRef)([mobileContacts objectAtIndex:indexPath.row]);
//        [cell setCellForContactPerson:contactPerson withChosenPeople:chosenPeople];
//        cell.aroundTapButton.tag = indexPath.row;
//        [cell.aroundTapButton removeTarget:nil
//                                    action:NULL
//                          forControlEvents:UIControlEventAllEvents];
//        [cell.aroundTapButton addTarget:self action:@selector(inviteMobilePressed:) forControlEvents:UIControlEventTouchUpInside];
//    }
    return nil;
    
}

- (void)tapAllPressed {
    if (!WGProfile.tapAll) {
        WGProfile.tapAll = YES;
        TapAllCell *tapAllCell = (TapAllCell *)[self.invitePeopleTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:kSectionTapAllCell]];
        tapAllCell.tapImageView.image = [UIImage imageNamed:@"tapSelectedInvite"];
        __weak typeof(self) weakSelf = self;
        [WGProfile.currentUser tapAllUsersWithHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                return;
            }
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.invitePeopleTableView reloadData];
        }];
    }
}


- (void)inviteMobilePressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    ABRecordRef contactPerson;
    ABRecordID recordID;
    if (self.isSearching) {
        contactPerson = (__bridge ABRecordRef)([filteredMobileContacts objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
        tag = [MobileDelegate changeTag:tag fromArray:filteredMobileContacts toArray:mobileContacts];
    } else {
        contactPerson = (__bridge ABRecordRef)([mobileContacts objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
    }
    for (UIView *subview in buttonSender.subviews) {
        if ([subview isKindOfClass:[UIImageView class]] && subview.tag == 3) {
            UIImageView *selectedImageView = (UIImageView *)subview;
            NSString *recordIdString = [NSString stringWithFormat:@"%d",recordID];
            if (![chosenPeople containsObject:recordIdString]) {
                selectedImageView.image = [UIImage imageNamed:@"tapSelectedInvite"];
                [chosenPeople addObject:recordIdString];
            }
            else {
                selectedImageView.image = [UIImage imageNamed:@"tapUnselectedInvite"];
                [chosenPeople removeObject:recordIdString];
            }
        }
    }
}

- (void)followedPersonPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int row = (int)buttonSender.tag;
    WGUser *user = (WGUser *)[self.presentedSuggestions objectAtIndex:buttonSender.tag];
    [user followUser];
    [self.presentedSuggestions replaceObjectAtIndex:row withObject:user];
    [self.invitePeopleTableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    headerView.backgroundColor = RGB(248, 248, 248);
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.view.frame.size.width, 30)];
    headerLabel.textAlignment = NSTextAlignmentLeft;
    headerLabel.font = [FontProperties lightFont:14.0f];
    headerLabel.textColor = RGB(150, 150, 150);
    if (section == kSectionTapCell) {
        headerLabel.text = @"Best Friends";
    }
    else if (section == kSectionAllFriends) {
        headerLabel.text = @"All Friends";
    }
    else if (section == kSectionFollowCell) {
        headerLabel.text = @"Suggested Friends";
    }
    [headerView addSubview:headerLabel];
    return headerView;
}

-(CGFloat) tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    if (section == kSectionTapCell) {
        return 30.0f;
    }
    if (section == kSectionAllFriends) {
        return 30.0f;
    }
    if (section == kSectionFollowCell) {
        if ([self tableView:tableView numberOfRowsInSection:section] > 0) {
           return 30;
        }
    }
    return 0;
}


- (void)tapPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGUser *user;
    if (tag < self.presentedUsers.count) {
        user = (WGUser *)[self.presentedUsers objectAtIndex:tag];
    }
    
    if (user.isTapped.boolValue) {
        [WGProfile.currentUser untap:user withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionDelete];
            }
        }];
        user.isTapped = @NO;
        [WGAnalytics tagAction:@"untap" atView:@"invite"];
    } else {
#warning Group these
        [WGProfile.currentUser tapUser:user withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
            }
        }];
        user.isTapped = @YES;
        [WGAnalytics tagAction:@"tap" atView:@"invite"];
    }
    if (tag < self.presentedUsers.count) {
        [self.presentedUsers replaceObjectAtIndex:tag withObject:user];
    }
    int sizeOfTable = (int)[self.invitePeopleTableView numberOfRowsInSection:kSectionTapCell];
    if (sizeOfTable > 0 && tag < sizeOfTable && tag >= 0) {
        [self.invitePeopleTableView reloadData];
    }
}

#pragma mark - UISearchBar


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [searchBar endEditing:YES];
}


#pragma mark - UISearchBarDelegate


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if([searchText length] != 0) {
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.25
     cancelPreviousRequest:YES];
    } else {
        self.presentedUsers = self.content;
        self.presentedSuggestions = self.suggestions;
        self.isSearching = NO;
        [self.invitePeopleTableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performBlock:^(void){[self searchTableList];}
            afterDelay:0.25
 cancelPreviousRequest:YES];
}


- (void)searchTableList {
    // Normal users
    NSString *oldString = searchBar.text;
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    __weak typeof(self) weakSelf = self;
    [WGProfile.currentUser searchNotMe:searchString withContext:@"invite" withHandler:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.isSearching = YES;
            strongSelf.presentedUsers = collection;
            [strongSelf.presentedUsers removeObject:[WGProfile currentUser]];
            [strongSelf.invitePeopleTableView reloadData];
        });
    }];
    
    // Folow users
    [WGUser searchInvites:searchString  withHandler:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.presentedSuggestions = collection;
            [strongSelf.presentedSuggestions removeObject:WGProfile.currentUser];
            [strongSelf.invitePeopleTableView reloadData];
        });
    }];

    // Mobile contacts
    filteredMobileContacts = [NSMutableArray arrayWithArray:[MobileDelegate filterArray:mobileContacts withText:searchBar.text]];
}

- (void) getNextPage {
    if (self.isFetching) return;
    if (!self.presentedUsers.hasNextPage.boolValue) return;

    self.isFetching = YES;
    __weak typeof(self) weakSelf = self;
    [self.presentedUsers addNextPage:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.isFetching = NO;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            [strongSelf.presentedUsers removeObject:WGProfile.currentUser];
            [strongSelf.invitePeopleTableView reloadData];
        });
    }];
 }

#pragma mark - Network requests

- (void) fetchFirstPageEveryone {
    __weak typeof(self) weakSelf = self;
    [event getInvites:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.isSearching = NO;
            strongSelf.content = collection;
            [strongSelf.content removeObject:WGProfile.currentUser];
            strongSelf.presentedUsers = strongSelf.content;
            [strongSelf.invitePeopleTableView reloadData];
        });
    }];
}


- (void)fetchSuggestions {
    __weak typeof(self) weakSelf = self;
    [WGUser getSuggestions:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.suggestions = collection;
            strongSelf.presentedSuggestions = collection;
            [strongSelf.invitePeopleTableView reloadData];
        });
    }];
}



#pragma mark - Mobile

- (void)getMobileContacts {
    [MobileDelegate getMobileContacts:^(NSArray *mobileArray) {
        mobileContacts = mobileArray;
    }];
}

@end

@implementation TapCell

+ (CGFloat)height {
    return 70.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [TapCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    
    self.aroundTapButton = [[UIButton alloc] initWithFrame:self.frame];
    [self.contentView addSubview:self.aroundTapButton];
    
    self.profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, [TapCell height]/2 - 30, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    [self.aroundTapButton addSubview:self.profileImageView];
    
    self.fullNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 15, 150, 20)];
    self.fullNameLabel.font = [FontProperties getSubtitleFont];
    [self.aroundTapButton addSubview:self.fullNameLabel];
    
    self.goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 35, 170, 20)];
    self.goingOutLabel.font = [FontProperties lightFont:13.0f];
    self.goingOutLabel.textAlignment = NSTextAlignmentLeft;
    self.goingOutLabel.textColor = [FontProperties getBlueColor];
    [self.aroundTapButton addSubview:self.goingOutLabel];
    
    self.tapImageView = [[UIImageView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 15 - 15 - 25, [TapCell height] / 2 - 15, 30, 30)];
    self.tapImageView.tag = 3;
    [self.aroundTapButton addSubview:self.tapImageView];
}

- (void)setUser:(WGUser *)user {
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.fullNameLabel.text = user.fullName;
    if (user.isGoingOut.boolValue) {
        if (user.eventAttending.name && !user.eventAttending.isPrivate) {
            self.goingOutLabel.text = user.eventAttending.name;
        } else {
            self.goingOutLabel.text = @"Going Out";
        }
    }
    else self.goingOutLabel.text = nil;
   
    if (user.isTapped.boolValue || WGProfile.tapAll) {
        [self.tapImageView setImage:[UIImage imageNamed:@"tapSelectedInvite"]];
    }
    else {
        [self.tapImageView setImage:[UIImage imageNamed:@"tapUnselectedInvite"]];
    }
}

- (void)setCellForContactPerson:(ABRecordRef)contactPerson
               withChosenPeople:(NSArray *)chosenPeople {
    
    ABRecordID recordID = ABRecordGetRecordID(contactPerson);
    NSString *recordIdString = [NSString stringWithFormat:@"%d",recordID];

    self.profileImageView.image = [UIImage imageNamed:@"grayIcon"];
    if ([chosenPeople containsObject:recordIdString])
        self.tapImageView.image = [UIImage imageNamed:@"tapSelectedInvite"];
    else
        self.tapImageView.image = [UIImage imageNamed:@"tapUnselectedInvite"];
    
    NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
    NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    [fullName capitalizedString];
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:fullName];
    [attString addAttribute:NSFontAttributeName
                      value:[FontProperties getSubtitleFont]
                      range:NSMakeRange(0, fullName.length)];
    [attString addAttribute:NSForegroundColorAttributeName
                      value:RGB(120, 120, 120)
                      range:NSMakeRange(0, fullName.length)];
    if (lastName.length == 0)
        [attString addAttribute:NSForegroundColorAttributeName
                          value:RGB(20, 20, 20)
                          range:NSMakeRange(0, [firstName length])];
    else
        [attString addAttribute:NSForegroundColorAttributeName
                          value:RGB(20, 20, 20)
                          range:NSMakeRange([firstName length] + 1, [lastName length])];
    self.fullNameLabel.attributedText = attString;
}

@end

@implementation TapAllCell

+ (CGFloat) height {
    return 70;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [TapAllCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.aroundTapButton = [[UIButton alloc] initWithFrame:self.frame];
    [self.contentView addSubview:self.aroundTapButton];
    
    self.tapAllLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, [TapAllCell height]/2 - 30, 155, 60)];
    self.tapAllLabel.textAlignment = NSTextAlignmentLeft;
    self.tapAllLabel.numberOfLines = 0;
    self.tapAllLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.tapAllLabel.textColor = UIColor.blackColor;
    self.tapAllLabel.font = [FontProperties lightFont:18.0f];
    self.tapAllLabel.text = @"Tap All";
    [self.aroundTapButton addSubview:self.tapAllLabel];
    
    self.tapImageView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 15 - 15 - 25, [TapAllCell height] / 2 - 15, 30, 30)];
    if (WGProfile.tapAll) {
        [self.tapImageView setImage:[UIImage imageNamed:@"tapSelectedInvite"]];
    }
    else {
        [self.tapImageView setImage:[UIImage imageNamed:@"tapUnselectedInvite"]];
    }
    [self.aroundTapButton addSubview:self.tapImageView];
}

@end

@implementation FollowCell

+ (CGFloat) height {
     return 70;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
        return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [FollowCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
 
    self.profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.profileImageView];
    
    self.profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 30, self.contentView.frame.size.width - 15 - 79 - 15, 60)];
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    [self.profileButton addSubview:self.profileImageView];
    [self.contentView addSubview:self.profileButton];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    self.nameLabel.font = [FontProperties mediumFont:18.0f];
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.userInteractionEnabled = YES;
    [self.contentView addSubview:self.nameLabel];
    
    self.followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.contentView.frame.size.width - 15 - 49, PEOPLEVIEW_HEIGHT_OF_CELLS / 2 - 15, 49, 30)];
    [self.contentView addSubview:self.followPersonButton];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text =  user.fullName;
    [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
    self.followPersonButton.backgroundColor = UIColor.clearColor;

    if (!user.isCurrentUser) {
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
        if (user.isFriend.boolValue) {
            [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
            [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
        }
        if (user.state == SENT_OR_RECEIVED_REQUEST_USER_STATE) {
            [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
            [self.followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
            [self.followPersonButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            self.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
            self.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.followPersonButton.backgroundColor = RGB(223, 223, 223);
            self.followPersonButton.layer.borderWidth = 1;
            self.followPersonButton.layer.borderColor = UIColor.clearColor.CGColor;
            self.followPersonButton.layer.cornerRadius = 3;
        }
    }
    }
}
@end