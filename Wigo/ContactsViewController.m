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

NSArray *peopleContactList;
NSMutableArray *choosenPeople;
UITableView *contactsTableView;
NSMutableArray *selectedPeopleIndexes;

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
    peopleContactList = [[NSArray alloc] init];
    choosenPeople = [[NSMutableArray alloc] init];
    selectedPeopleIndexes = [[NSMutableArray alloc] init];
    self.title = @"TAP 5 OR MORE FRIENDS";

    [self initializeTableViewWithPeople];
    [self initializeButtonIAmDone];
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
            peopleContactList = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
            for (int i = 0; i < [peopleContactList count]; i++) {
                [choosenPeople addObject:@NO];
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
    
    ABRecordRef contactPerson = (__bridge ABRecordRef)peopleContactList[[indexPath row]];
    
    UIButton *selectedPersonButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 10, 30, 30)];
    selectedPersonButton.tag = (int)[indexPath row];
    [selectedPersonButton addTarget:self action:@selector(selectedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:selectedPersonButton];
    
    UIImageView *selectedPersonImageView = [[UIImageView alloc] initWithFrame:selectedPersonButton.frame];
    selectedPersonImageView.tag = (int)[indexPath row];
    if ([(NSNumber *)[choosenPeople objectAtIndex:[indexPath row]] boolValue])
        selectedPersonImageView.image = [UIImage imageNamed:@"tapFilled"];
    else
        selectedPersonImageView.image = [UIImage imageNamed:@"tapUnfilled"];
    selectedPersonImageView.tintColor = [FontProperties getOrangeColor];
    [cell.contentView addSubview:selectedPersonImageView];
    
    UILabel *nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 10, self.view.frame.size.width - 110, 30)];
    NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
    NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    nameOfPersonLabel.text = fullName;
    nameOfPersonLabel.font = [FontProperties mediumFont:20];
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
            if ([(NSNumber *)[choosenPeople objectAtIndex:tag] boolValue]) {
                [choosenPeople replaceObjectAtIndex:tag withObject:@YES];
                selectedImageView.image = [UIImage imageNamed:@"tapFilled"];
            }
            else {
                [choosenPeople replaceObjectAtIndex:tag withObject:@NO];
                selectedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
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
    
}


//    ABMultiValueRef emails = ABRecordCopyValue(contactPerson, kABPersonPhoneProperty);
//    
//    NSUInteger j = 0;
//    for (j = 0; j < ABMultiValueGetCount(emails); j++) {
//        NSString *email = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emails, j);
//        if (j == 0) {
//            NSLog(@"person's phone = %@ ", email);
//        }
//    }


@end
