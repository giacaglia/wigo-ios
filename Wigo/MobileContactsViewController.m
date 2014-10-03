//
//  ContactsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MobileContactsViewController.h"
#import <AddressBook/AddressBook.h>
#import "Globals.h"

NSMutableArray *peopleContactList;
UITableView *contactsTableView;
NSMutableArray *selectedPeopleIndexes;
CFArrayRef all;
CFIndex n;
UISearchBar *searchBar;
BOOL isFiltered;
NSMutableArray *filteredPeopleContactList;

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
    peopleContactList = [[NSMutableArray alloc] init];
    chosenPeople = [[NSMutableArray alloc] init];
    shownChosenPeople = [[NSMutableArray alloc] init];
    selectedPeopleIndexes = [[NSMutableArray alloc] init];

    [self initializeTitle];
    [self initializeSearchBar];
    [self initializeTapHandler];
    [self initializeTableViewWithPeople];
//    [self initializeButtonIAmDone];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    CFErrorRef error = NULL;
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted && addressBookRef) {
            [EventAnalytics tagEvent:@"Accepted Apple Contacts"];

            all = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
            n = ABAddressBookGetPersonCount(addressBookRef);
            
            CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
                                                                       kCFAllocatorDefault,
                                                                       CFArrayGetCount(all),
                                                                       all
                                                                       );
            
            CFArraySortValues(
                              peopleMutable,
                              CFRangeMake(0, n),
                              (CFComparatorFunction) ABPersonComparePeopleByName,
                              (void*) ABPersonGetSortOrdering()
                              );
            NSMutableArray* data = [NSMutableArray arrayWithArray: (__bridge NSArray*) peopleMutable];
            

            for( int i = 0 ; i < n ; i++ )
            {
                ABRecordRef ref = (__bridge ABRecordRef)([data objectAtIndex:i]);
                NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(ref, kABPersonFirstNameProperty));
                NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(ref, kABPersonLastNameProperty));
                ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
                if ( ABMultiValueGetCount(phones) > 0 &&
                    (![firstName isEqualToString:@""] || ![lastName isEqualToString:@""]) ) {
                    [peopleContactList addObject:(__bridge id)(ref)];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [contactsTableView reloadData];
            });
       
        }
        else {
            [EventAnalytics tagEvent:@"Decline Apple Contacts"];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    });
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
    int tag = buttonSender.tag;
    if (isFiltered) {
        ABRecordRef contactPerson = (__bridge ABRecordRef)([filteredPeopleContactList objectAtIndex:tag]);
        ABRecordID recordID = ABRecordGetRecordID(contactPerson);
        for (int i = 0 ; i < [peopleContactList count] ; i++ ) {
            ABRecordRef newContactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:i]);
            ABRecordID newRecordID = ABRecordGetRecordID(newContactPerson);
            if (recordID == newRecordID) {
                tag = i;
            }
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
    else {
        ABRecordRef contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:tag]);
        ABRecordID recordID = ABRecordGetRecordID(contactPerson);
        [selectedPeopleIndexes addObject:[NSNumber numberWithInt:tag]];
        for (UIView *subview in buttonSender.subviews) {
            if (subview.tag == tag && [subview isKindOfClass:[UIImageView class]]) {
                UIImageView *selectedImageView = (UIImageView *)subview;
                NSString *recordIdString = [NSString stringWithFormat:@"%d", recordID];
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

}

- (void)initializeButtonIAmDone {
    UIButton *iAmDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(15, self.view.frame.size.height - 50 - 10, self.view.frame.size.width - 30, 50)];
    [iAmDoneButton setTitle:@"OK, I AM DONE" forState:UIControlStateNormal];
    [iAmDoneButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    iAmDoneButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    iAmDoneButton.layer.borderWidth = 2.0f;
    iAmDoneButton.layer.cornerRadius = 10;
    [iAmDoneButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:iAmDoneButton];
}


- (void)donePressed {
    NSMutableArray *numbers = [[NSMutableArray alloc] init];
    for (CFIndex i = 0; i < [chosenPeople count]; i++) {
        NSString *recordIDString = [chosenPeople objectAtIndex:i];
        for (int j = 0; j < [peopleContactList count]; j++) {
            ABRecordRef contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:j]);
            ABRecordID newRecordID = ABRecordGetRecordID(contactPerson);
            NSString *newRecordIDString = [NSString stringWithFormat:@"%d",newRecordID];
            if ([recordIDString isEqualToString:newRecordIDString]) {
                ABMultiValueRef multiPhones = ABRecordCopyValue(contactPerson, kABPersonPhoneProperty);
                for(CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++) {
                    
                    NSString* phoneLabel = (__bridge NSString*) ABMultiValueCopyLabelAtIndex(multiPhones, i);
                    NSString* phoneNumber = (__bridge NSString*) ABMultiValueCopyValueAtIndex(multiPhones, i);
                    //for example
                    if([phoneLabel isEqualToString:(NSString *)kABPersonPhoneIPhoneLabel]) {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                    else if (([phoneLabel isEqualToString:(NSString *)kABPersonPhoneMobileLabel])) {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                    else if (([phoneLabel isEqualToString:(NSString *)kABPersonPhoneMainLabel])) {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                    else {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                }

            }
        }
    }
    if ([numbers count] > 0) {
        NSDictionary *options = (NSDictionary *)numbers;
        [Network sendAsynchronousHTTPMethod:POST
                                withAPIName:@"invites/"
                                withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                                withOptions:options];

    }
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
        filteredPeopleContactList = [[NSMutableArray alloc] init];
        
        for (int i = 0 ; i < [peopleContactList count]; i++) {
            ABRecordRef contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:i]);
            NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
            NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));

            NSRange nameRange = [firstName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange descriptionRange = [lastName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound || descriptionRange.location != NSNotFound)
            {
                [filteredPeopleContactList addObject:(__bridge id)(contactPerson)];
            }
        }
      
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
