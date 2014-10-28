//
//  ContactsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MobileContactsViewController.h"
#import "Globals.h"
#import "MobileDelegate.h"

NSArray *peopleContactList;
UITableView *contactsTableView;
NSMutableArray *selectedPeopleIndexes;
UISearchBar *searchBar;
BOOL isFiltered;
NSArray *filteredPeopleContactList;

NSMutableArray *shownChosenPeople;
NSMutableArray *chosenPeople;


@implementation MobileContactsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    peopleContactList = [[NSArray alloc] init];
    chosenPeople = [[NSMutableArray alloc] init];
    shownChosenPeople = [[NSMutableArray alloc] init];
    selectedPeopleIndexes = [[NSMutableArray alloc] init];

    [self initializeTitle];
    [self initializeSearchBar];
    [self initializeTapHandler];
    [self initializeTableViewWithPeople];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    isFiltered = NO;
    if (contactsTableView) [contactsTableView reloadData];
    [EventAnalytics tagEvent:@"MobileContacts View"];
}

- (void)initializeTitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 30, self.view.frame.size.width - 30, 25)];
    titleLabel.text = @"TAP 5 OR MORE FRIENDS";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties mediumFont:16];
    [self.view addSubview:titleLabel];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 30, 60, 25)];
    [doneButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    doneButton.titleLabel.textAlignment = NSTextAlignmentRight;
    doneButton.titleLabel.font = [FontProperties getTitleFont];
    [doneButton setShowsTouchWhenHighlighted:YES];
    [self.view addSubview:doneButton];
}

- (void)initializeTableViewWithPeople {
    self.automaticallyAdjustsScrollViewInsets = NO;
    contactsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 104, self.view.frame.size.width, self.view.frame.size.height - 104)];
    contactsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    contactsTableView.dataSource = self;
    contactsTableView.delegate = self;
    [self.view addSubview:contactsTableView];
    [self getContactAccess];
}

- (void)getContactAccess {
   [MobileDelegate getMobileContacts:^(NSArray *mobileArray) {
       dispatch_async(dispatch_get_main_queue(), ^(void){
           if ([mobileArray count] > 0) {
               peopleContactList = [NSMutableArray arrayWithArray:mobileArray];
               [contactsTableView reloadData];
           }
           else {
               [EventAnalytics tagEvent:@"Decline Apple Contacts"];
               [self dismissViewControllerAnimated:NO completion:nil];
           }
       });
   }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIButton *aroundCellButton = [[UIButton alloc] initWithFrame:cell.contentView.frame];
    aroundCellButton.tag = (int)[indexPath row];
    [aroundCellButton addTarget:self action:@selector(selectedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:aroundCellButton];
    
    ABRecordRef contactPerson;
    if (isFiltered)
        contactPerson  = (__bridge ABRecordRef)([filteredPeopleContactList objectAtIndex:[indexPath row]]);
    else
        contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:[indexPath row]]);
    

    UIImageView *selectedPersonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 30, 30)];
    selectedPersonImageView.tag = (int)[indexPath row];
    ABRecordID recordID = ABRecordGetRecordID(contactPerson);
    NSString *recordIdString = [NSString stringWithFormat:@"%d",recordID];
    
    if ([shownChosenPeople containsObject:recordIdString])
        selectedPersonImageView.image = [UIImage imageNamed:@"tapFilled"];
    else
        selectedPersonImageView.image = [UIImage imageNamed:@"tapUnselected"];
    selectedPersonImageView.tintColor = [FontProperties getOrangeColor];
    [aroundCellButton addSubview:selectedPersonImageView];
    
    UILabel *nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 10, self.view.frame.size.width - 55 - 15, 30)];
    NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
    NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    [fullName capitalizedString];

    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:fullName];
    [attString addAttribute:NSFontAttributeName
                      value:[FontProperties mediumFont:20.0f]
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
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (isFiltered)
        return [filteredPeopleContactList count];
    else
        return [peopleContactList count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


- (void)selectedPersonPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    ABRecordRef contactPerson;
    ABRecordID recordID;
    if (isFiltered) {
        contactPerson = (__bridge ABRecordRef)([filteredPeopleContactList objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
        tag = [MobileDelegate changeTag:tag fromArray:filteredPeopleContactList toArray:peopleContactList];
       
    }
    else {
        contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
    }
    [selectedPeopleIndexes addObject:[NSNumber numberWithInt:tag]];
    for (UIView *subview in buttonSender.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            UIImageView *selectedImageView = (UIImageView *)subview;
            NSString *recordIdString = [NSString stringWithFormat:@"%d",recordID];
            if (![shownChosenPeople containsObject:recordIdString]) {
                selectedImageView.image = [UIImage imageNamed:@"tapFilled"];
                [chosenPeople addObject:recordIdString];
                [shownChosenPeople addObject:recordIdString];
            }
            else {
                selectedImageView.image = [UIImage imageNamed:@"tapUnselected"];
                [shownChosenPeople removeObject:recordIdString];
            }
        }
    }
}

- (void)donePressed {
    [MobileDelegate sendChosenPeople:chosenPeople forContactList:peopleContactList];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initializeSearchBar {
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 40)];
    searchBar.barTintColor = [FontProperties getOrangeColor];
    searchBar.tintColor = [FontProperties getOrangeColor];
    searchBar.placeholder = @"Search By Name";
    searchBar.delegate = self;
    searchBar.layer.borderWidth = 1.0f;
    searchBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [self.view addSubview:searchBar];
}


- (BOOL) textFieldShouldClear:(UITextField *)textField{
    [searchBar resignFirstResponder];
    [self.view endEditing:YES];
    return YES;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self.view endEditing:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    // You can write search code Here
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self.view endEditing:YES];
}

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {
    if(searchText.length == 0)
    {
        isFiltered = FALSE;
        [self.view endEditing:YES];
    }
    else
    {
        isFiltered = true;
        filteredPeopleContactList = [MobileDelegate filterArray:peopleContactList withText:searchText];
    }
    
    [contactsTableView reloadData];
}

- (void) initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}



@end
