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
#import "MobileDelegate.h"
#define HEIGHT_CELLS 70

@interface InviteViewController() {
    NSArray *mobileContacts;
    NSMutableArray *filteredMobileContacts;
    NSMutableArray *chosenPeople;
    
    UITableView *invitePeopleTableView;
    WGCollection *content;
    WGCollection *filteredContent;
    WGEvent *event;
    UISearchBar *searchBar;
    BOOL isSearching;
    
    UIButton *aroundInviteButton;
    UILabel *titleLabel;
    UIButton *searchButton;
    UIButton *cancelButton;
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
    [self initializeTitle];
    [self initializeTapPeopleTitle];
    [self initializeSearchBar];
    [self initializeTableInvite];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Invite View"];
}


- (void)initializeTitle {
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, self.view.frame.size.width - 20, 30)];
    titleLabel.text = @"Invite";
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:titleLabel];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 64 - 1, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGBAlpha(122, 193, 226, 0.1f);
    [self.view addSubview:lineView];

    aroundInviteButton = [[UIButton alloc] initWithFrame:CGRectMake(15 - 5, 40 - 5, 60 + 10, 15 + 10)];
    [aroundInviteButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [aroundInviteButton setShowsTouchWhenHighlighted:YES];
    [self.view addSubview:aroundInviteButton];
    
    UILabel *doneLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, 60, 15)];
    doneLabel.text = @"Done";
    doneLabel.textColor = [FontProperties getBlueColor];
    doneLabel.textAlignment = NSTextAlignmentLeft;
    doneLabel.font = [FontProperties getTitleFont];
    [aroundInviteButton addSubview:doneLabel];
    
    searchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 30 - 15, 40 - 40, 60, 80)];
    [searchButton addTarget:self action:@selector(searchPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];
    
    UIImageView *searchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 35, 15, 16)];
    searchImageView.image = [UIImage imageNamed:@"searchIcon"];
    [searchButton addSubview:searchImageView];
}

- (void)initializeTapPeopleTitle {
    UILabel *tapPeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 64, self.view.frame.size.width - 30, 75)];
    tapPeopleLabel.numberOfLines = 0;
    tapPeopleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tapPeopleLabel.textAlignment = NSTextAlignmentCenter;
    NSString *string;
  
    if (event.name.length > 0 ) {
        string = [NSString stringWithFormat:@"Tap people you want to see out \nat %@", event.name];
    }
    else {
        string = @"Tap people you want to see out";
    }
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc]
                                             initWithString:string];
    if (35 + event.name.length <= string.length) {
        [attString addAttribute:NSFontAttributeName
                          value:[FontProperties lightFont:18.0f]
                          range:NSMakeRange(0, 35 + event.name.length)];
        [attString addAttribute:NSForegroundColorAttributeName
                          value:[FontProperties getBlueColor]
                          range:NSMakeRange(35, event.name.length)];
    }
    tapPeopleLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:attString];
    [self.view addSubview:tapPeopleLabel];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, 64 + 75 - 1, self.view.frame.size.width - 15, 1)];
    lineView.backgroundColor = [FontProperties getLightBlueColor];
    [self.view addSubview:lineView];

}

- (void)donePressed {
    NSArray *savedChosenPeople = [[NSUserDefaults standardUserDefaults] valueForKey:@"chosenPeople"];
    if (savedChosenPeople) {
        NSMutableSet *newChosenPeople = [NSMutableSet setWithArray:savedChosenPeople];
        [newChosenPeople addObjectsFromArray:chosenPeople];
        [[NSUserDefaults standardUserDefaults] setValue:[newChosenPeople allObjects] forKey:@"chosenPeople"];
    }
    else {
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
    invitePeopleTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64 + 75, self.view.frame.size.width, self.view.frame.size.height - 64 - 75)];
    [self.view addSubview:invitePeopleTableView];
    invitePeopleTableView.dataSource = self;
    invitePeopleTableView.delegate = self;
    [invitePeopleTableView setSeparatorColor:[FontProperties getBlueColor]];
    invitePeopleTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}


#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return HEIGHT_CELLS;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (isSearching) {
            return [filteredContent count];
        }
        else {
            int hasNextPage = ([content.hasNextPage boolValue] ? 1 : 0);
            return [content count] + hasNextPage;
        }
    }
    else {
        if (isSearching) return [filteredMobileContacts count];
        return [mobileContacts count];
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
    cell.contentView.frame = CGRectMake(0, 0, self.view.frame.size.width, HEIGHT_CELLS);
    if ([indexPath section] == 0) {
        int tag = (int)[indexPath row];
        WGUser *user;
        if (isSearching) {
            if ([filteredContent count] == 0) return cell;
            if (tag < [filteredContent count]) {
                user = (WGUser *)[filteredContent objectAtIndex:tag];
            }
            if ([filteredContent count] > 5 && [content.hasNextPage boolValue]) {
                if (tag == [filteredContent count] - 5) {
                    [self fetchEveryone];
                }
            }
            else {
                if (tag == [filteredContent count] && [content count] != 0) {
                    [self fetchEveryone];
                    return cell;
                }
            }
        }
        else {
            if ([content count] == 0) return cell;
            if (tag < [content count]) {
                user = (WGUser *)[content objectAtIndex:tag];
            }
            if ([content count] > 5 && [content.hasNextPage boolValue]) {
                if (tag == [content count] - 5) {
                    [self fetchEveryone];
                }
            }
            else {
                if (tag == [content count] && [content count] != 0) {
                    [self fetchEveryone];
                    return cell;
                }
            }
            
        }
        
        if (user) {
            UIButton *aroundTapButton = [[UIButton alloc] initWithFrame:cell.contentView.frame];
            [aroundTapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
            aroundTapButton.tag = tag;
            [cell.contentView addSubview:aroundTapButton];
            
            UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, HEIGHT_CELLS/2 - 30, 60, 60)];
            profileImageView.contentMode = UIViewContentModeScaleAspectFill;
            profileImageView.clipsToBounds = YES;
            [profileImageView setImageWithURL:user.coverImageURL imageArea:[user coverImageArea]];
            [aroundTapButton addSubview:profileImageView];
            
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
            textLabel.text = [user fullName];
            textLabel.font = [FontProperties getSubtitleFont];
            [aroundTapButton addSubview:textLabel];
            
            UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 40, 150, 20)];
            goingOutLabel.font = [FontProperties mediumFont:13.0f];
            goingOutLabel.textAlignment = NSTextAlignmentLeft;
            goingOutLabel.textColor = [FontProperties getBlueColor];
            if ([user isGoingOut]) {
                if (user.eventAttending.name) {
                    goingOutLabel.text = [NSString stringWithFormat:@"Going out to %@", user.eventAttending.name];
                }
                else {
                    goingOutLabel.text = @"Going Out";
                }
            }
            [aroundTapButton addSubview:goingOutLabel];
            
            UIImageView *tapImageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 15 - 25, HEIGHT_CELLS / 2 - 15, 30, 30)];
            if ([user isTapped]) {
                [tapImageView setImage:[UIImage imageNamed:@"tapSelectedInvite"]];
            }
            else {
                [tapImageView setImage:[UIImage imageNamed:@"tapUnselectedInvite"]];
            }
            [aroundTapButton addSubview:tapImageView];
        }
    }
    else  {
        UIButton *aroundCellButton = [[UIButton alloc] initWithFrame:cell.contentView.frame];
        aroundCellButton.tag = (int)[indexPath row];
        [aroundCellButton addTarget:self action:@selector(inviteMobilePressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:aroundCellButton];
        
        UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, HEIGHT_CELLS / 2 - 30, 60, 60)];
        profileImageView.tag = -1;
        profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        profileImageView.clipsToBounds = YES;
        profileImageView.image = [UIImage imageNamed:@"grayIcon"];
        [aroundCellButton addSubview:profileImageView];

        
        ABRecordRef contactPerson;
        if (isSearching)
            contactPerson  = (__bridge ABRecordRef)([filteredMobileContacts objectAtIndex:[indexPath row]]);
        else
            contactPerson = (__bridge ABRecordRef)([mobileContacts objectAtIndex:[indexPath row]]);
        
        
        UIImageView *tapImageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 15 - 25, HEIGHT_CELLS/2 - 15, 30, 30)];
        ABRecordID recordID = ABRecordGetRecordID(contactPerson);
        NSString *recordIdString = [NSString stringWithFormat:@"%d",recordID];
        if ([chosenPeople containsObject:recordIdString])
            tapImageView.image = [UIImage imageNamed:@"tapSelectedInvite"];
        else
            [tapImageView setImage:[UIImage imageNamed:@"tapUnselectedInvite"]];
        [aroundCellButton addSubview:tapImageView];
        
        UILabel *nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
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
        if ([lastName isEqualToString:@""])
            [attString addAttribute:NSForegroundColorAttributeName
                              value:RGB(20, 20, 20)
                              range:NSMakeRange(0, [firstName length])];
        else
            [attString addAttribute:NSForegroundColorAttributeName
                              value:RGB(20, 20, 20)
                              range:NSMakeRange([firstName length] + 1, [lastName length])];
        nameOfPersonLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:attString];
        [aroundCellButton addSubview:nameOfPersonLabel];
    }
    
    return cell;
}

- (void)inviteMobilePressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    ABRecordRef contactPerson;
    ABRecordID recordID;
    if (isSearching) {
        contactPerson = (__bridge ABRecordRef)([filteredMobileContacts objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
        tag = [MobileDelegate changeTag:tag fromArray:filteredMobileContacts toArray:mobileContacts];
    }
    else {
        contactPerson = (__bridge ABRecordRef)([mobileContacts objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
    }
    for (UIView *subview in buttonSender.subviews) {
        if ([subview isKindOfClass:[UIImageView class]] && subview.tag != -1) {
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [[UIView alloc ] init];
    }
    else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
        headerView.backgroundColor = [UIColor whiteColor];
        
        UILabel *tapPeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.view.frame.size.width, 30)];
        tapPeopleLabel.text = @"Tap Contacts";
        tapPeopleLabel.textAlignment = NSTextAlignmentLeft;
        tapPeopleLabel.font = [FontProperties lightFont:15.0f];
        tapPeopleLabel.textColor = [FontProperties getBlueColor];
        
        [headerView addSubview:tapPeopleLabel];
        
        return headerView;
    }
}
-(CGFloat) tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    if (section == 1) return 30;
    else return 0;
}



- (void) tapPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGUser *user;
    if (isSearching) {
        if (tag < [filteredContent count]) {
            user = (WGUser *)[filteredContent objectAtIndex:tag];
        }
    }
    else {
        if (tag < [content count]) {
            user = (WGUser *)[content objectAtIndex:tag];
        }
    }
    
    if ([user isTapped]) {
        [[WGProfile currentUser] untap:user withHandler:^(BOOL success, NSError *error) {
            // Do nothing!
        }];
        user.isTapped = [NSNumber numberWithBool:NO];
    }
    else {
#warning group these taps!
        [[WGProfile currentUser] tapUser:user withHandler:^(BOOL success, NSError *error) {
            // Do nothing!
        }];
        user.isTapped = [NSNumber numberWithBool:YES];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Invite", @"Tap Source", nil];
        [WGAnalytics tagEvent:@"Tap User" withDetails:options];
    }
    if (tag < [content count]) {
        [content replaceObjectAtIndex:tag withObject:user];
    }
    int sizeOfTable = (int)[invitePeopleTableView numberOfRowsInSection:0];
    if (sizeOfTable > 0 && tag < sizeOfTable && tag >= 0) {
//        [invitePeopleTableView beginUpdates];
//        [invitePeopleTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:tag inSection:0]] withRowAnimation: UITableViewRowAnimationNone];
//        [invitePeopleTableView endUpdates];
        
        [invitePeopleTableView reloadData];
    }
}

#pragma mark - UISearchBar

- (void)searchPressed {
    aroundInviteButton.hidden = YES;
    titleLabel.hidden = YES;
    searchButton.hidden = YES;
    [invitePeopleTableView setContentOffset:invitePeopleTableView.contentOffset animated:NO];

    searchBar.hidden = NO;
    [self.view addSubview:searchBar];
    [searchBar becomeFirstResponder];
    
    cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 65 - 15, 20, 65, 44)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action: @selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.textAlignment = NSTextAlignmentRight;
    cancelButton.titleLabel.font = [FontProperties getSubtitleFont];
    [cancelButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    [self.view addSubview:cancelButton];
}

- (void)cancelPressed {
    aroundInviteButton.hidden = NO;
    titleLabel.hidden = NO;
    searchButton.hidden = NO;

    cancelButton.hidden = YES;
    [self.view endEditing:YES];
    isSearching = NO;
    searchBar.text = @"";
    searchBar.hidden = YES;
    
    [invitePeopleTableView reloadData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [searchBar endEditing:YES];
}


- (void)initializeSearchBar {
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width - 60, 40)];
    searchBar.barTintColor = [FontProperties getBlueColor];
    searchBar.tintColor = [FontProperties getBlueColor];
    searchBar.placeholder = @"Search By Name";
    searchBar.delegate = self;
    UITextField *searchField = [searchBar valueForKey:@"_searchField"];
    [searchField setValue:[FontProperties getBlueColor] forKeyPath:@"_placeholderLabel.textColor"];
    
    // Search Icon Clear
    UITextField *txfSearchField = [searchBar valueForKey:@"_searchField"];
    [txfSearchField setLeftViewMode:UITextFieldViewModeNever];
    
    // Remove Clear Button on the right
    UITextField *textField = [searchBar valueForKey:@"_searchField"];
    textField.clearButtonMode = UITextFieldViewModeNever;
    
    // Text when editing becomes orange
    for (UIView *subView in searchBar.subviews) {
        for (UIView *secondLevelSubview in subView.subviews){
            if (![secondLevelSubview isKindOfClass:[UITextField class]]) {
                [secondLevelSubview removeFromSuperview];
            }
        }
    }
}


#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    isSearching = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if([searchText length] != 0) {
        isSearching = YES;
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.25
     cancelPreviousRequest:YES];
    }
    else {
//        [self.view endEditing:YES];
//        isSearching = NO;
    }
    [invitePeopleTableView reloadData];
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
    if (!filteredContent || filteredContent.hasNextPage == nil) {
        [WGUser searchNotMe:searchString withHandler:^(WGCollection *collection, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                strongSelf->filteredContent = collection;
                [strongSelf->filteredContent removeObject:[WGProfile currentUser]];
                [strongSelf->invitePeopleTableView reloadData];
            });
        }];
    } else if ([filteredContent.hasNextPage boolValue]) {
        [filteredContent addNextPage:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                [strongSelf->filteredContent removeObject:[WGProfile currentUser]];
                [strongSelf->invitePeopleTableView reloadData];
            });
        }];
    }
    
    // Mobile contacts
    filteredMobileContacts = [NSMutableArray arrayWithArray:[MobileDelegate filterArray:mobileContacts withText:searchBar.text]];
}

#pragma mark - Network requests

- (void) fetchFirstPageEveryone {
    [self fetchEveryone];
}

- (void) fetchEveryone {
    __weak typeof(self) weakSelf = self;
    if (!content || content.hasNextPage == nil) {
        [WGUser getInvites:^(WGCollection *collection, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                strongSelf->content = collection;
                [strongSelf->content removeObject:[WGProfile currentUser]];
                [strongSelf->invitePeopleTableView reloadData];
            });
        }];
    } else if ([content.hasNextPage boolValue]) {
        [content addNextPage:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                [strongSelf->content removeObject:[WGProfile currentUser]];
                [strongSelf->invitePeopleTableView reloadData];
            });
        }];
    }
}

#pragma mark - Mobile

- (void)getMobileContacts {
    [MobileDelegate getMobileContacts:^(NSArray *mobileArray) {
        mobileContacts = mobileArray;
    }];
}

@end
