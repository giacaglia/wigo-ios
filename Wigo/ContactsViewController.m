//
//  ContactsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ContactsViewController.h"
#import <AddressBook/AddressBook.h>
#import "Globals.h"

NSMutableArray *peopleContactList;
NSMutableArray *choosenPeople;
UITableView *contactsTableView;
NSMutableArray *selectedPeopleIndexes;
CFArrayRef all;
CFIndex n;

@implementation ContactsViewController

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
    choosenPeople = [[NSMutableArray alloc] init];
    selectedPeopleIndexes = [[NSMutableArray alloc] init];

    [self initializeTitle];
    [self initializeTableViewWithPeople];
    [self initializeButtonIAmDone];
}

- (void)initializeTitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 30, self.view.frame.size.width - 30, 25)];
    titleLabel.text = @"TAP 5 OR MORE FRIENDS";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties mediumFont:16];
    [self.view addSubview:titleLabel];
}

- (void)initializeTableViewWithPeople {
    self.automaticallyAdjustsScrollViewInsets = NO;
    contactsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 70)];
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
            
            all = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
            n = ABAddressBookGetPersonCount(addressBookRef);
            
            for (int i = 0; i < n; i++) {
                [choosenPeople addObject:@NO];
            }

            for( int i = 0 ; i < n ; i++ )
            {
                ABRecordRef ref = CFArrayGetValueAtIndex(all, i);
                NSString *firstName = (__bridge NSString *)ABRecordCopyValue(ref, kABPersonFirstNameProperty);
                NSLog(@"Name %@", firstName);
                if ([firstName isEqualToString:@"Bianca"]) {
                    NSLog(@"here");
                }
                ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
                if (ABMultiValueGetCount(phones) > 0) {
                    [peopleContactList addObject:(__bridge id)(ref)];
                }
            }
            [contactsTableView reloadData];
            CFRelease(addressBookRef);
            
            
        }
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
//    ABRecordRef contactPerson = CFArrayGetValueAtIndex(all, [indexPath row]);
    ABRecordRef contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:[indexPath row]]);
    
    UIButton *selectedPersonButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 10, 30, 30)];
    selectedPersonButton.tag = (int)[indexPath row];
    [selectedPersonButton addTarget:self action:@selector(selectedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:selectedPersonButton];
    
    UIImageView *selectedPersonImageView = [[UIImageView alloc] initWithFrame:selectedPersonButton.frame];
    selectedPersonImageView.tag = (int)[indexPath row];
    if ([(NSNumber *)[choosenPeople objectAtIndex:[indexPath row]] boolValue])
        selectedPersonImageView.image = [UIImage imageNamed:@"tapFilled"];
    else
        selectedPersonImageView.image = [UIImage imageNamed:@"tapUnselected"];
    selectedPersonImageView.tintColor = [FontProperties getOrangeColor];
    [cell.contentView addSubview:selectedPersonImageView];
    
    UILabel *nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 10, self.view.frame.size.width - 110, 30)];
    NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
    NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    nameOfPersonLabel.text = fullName;
    nameOfPersonLabel.font = [FontProperties mediumFont:20];
    nameOfPersonLabel.textColor = RGB(100, 100, 100);
    [cell.contentView addSubview:nameOfPersonLabel];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [peopleContactList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (void)selectedPersonPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = buttonSender.tag;
    
    [selectedPeopleIndexes addObject:[NSNumber numberWithInt:tag]];
    for (UIView *subview in buttonSender.superview.subviews) {
        if (subview.tag == tag && [subview isKindOfClass:[UIImageView class]]) {
            UIImageView *selectedImageView = (UIImageView *)subview;
            if (![(NSNumber *)[choosenPeople objectAtIndex:tag] boolValue]) {
                [choosenPeople replaceObjectAtIndex:tag withObject:@YES];
                selectedImageView.image = [UIImage imageNamed:@"tapFilled"];
            }
            else {
                [choosenPeople replaceObjectAtIndex:tag withObject:@NO];
                selectedImageView.image = [UIImage imageNamed:@"tapUnselected"];
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
    for(CFIndex i = 0; i < [choosenPeople count]; i++) {
        if ([[choosenPeople objectAtIndex:i] boolValue]) {
            ABRecordRef contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:i]);
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
//    NSLog(@"numbers %@", numbers);
//    NSDictionary *options = @{@"phone": @"6179813206"};
//    [Network sendAsynchronousHTTPMethod:POST
//                            withAPIName:@"invites/"
//                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
//                            withOptions:options];
    [self dismissViewControllerAnimated:YES completion:nil];
}





@end
