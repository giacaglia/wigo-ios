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
        self.view.backgroundColor = UIColor.whiteColor;
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
    [self initializeTableViewWithPeople];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    isFiltered = NO;
    if (contactsTableView) [contactsTableView reloadData];
    [WGAnalytics tagView:@"mobile_contacts"];
}

- (void)initializeTitle {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 30, self.view.frame.size.width - 30, 25)];
    titleLabel.text = @"Tap 5 or More Friends";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [FontProperties getTitleFont];
    titleLabel.textColor = [FontProperties getBlueColor];
    [self.view addSubview:titleLabel];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 30, 60, 25)];
    [doneButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    doneButton.titleLabel.textAlignment = NSTextAlignmentRight;
    doneButton.titleLabel.font = [FontProperties getTitleFont];
    [doneButton setShowsTouchWhenHighlighted:YES];
    [self.view addSubview:doneButton];
}

- (void)initializeTableViewWithPeople {
    self.automaticallyAdjustsScrollViewInsets = NO;
    contactsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    contactsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [contactsTableView registerClass:[MobileInviteCell class] forCellReuseIdentifier:kMobileInviteCellName];
    contactsTableView.dataSource = self;
    contactsTableView.delegate = self;
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    searchBar.placeholder = @"Search By Name";
    searchBar.delegate = self;
    [contactsTableView setTableHeaderView:searchBar];
    contactsTableView.contentOffset = CGPointMake(0, 50);
    [self.view addSubview:contactsTableView];
    [self getContactAccess];
}

- (void)getContactAccess {
    [WGSpinnerView addDancingGToCenterView:self.view];
    [MobileDelegate getMobileContacts:^(NSArray *mobileArray) {
        [WGSpinnerView removeDancingGFromCenterView:self.view];
        if ([mobileArray count] > 0) {
            peopleContactList = [NSMutableArray arrayWithArray:mobileArray];
            [contactsTableView reloadData];
        } else {
            [WGAnalytics tagAction:@"declined_access_mobile" atView:@"mobile_contacts"];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MobileInviteCell *cell = [tableView dequeueReusableCellWithIdentifier:kMobileInviteCellName forIndexPath:indexPath];

    ABRecordRef contactPerson;
    if (isFiltered)
        contactPerson  = (__bridge ABRecordRef)([filteredPeopleContactList objectAtIndex:[indexPath row]]);
    else
        contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:[indexPath row]]);
    

    ABRecordID recordID = ABRecordGetRecordID(contactPerson);
    NSString *recordIdString = [NSString stringWithFormat:@"%d",recordID];
    
    if ([shownChosenPeople containsObject:recordIdString])
        cell.selectedPersonImageView.image = [UIImage imageNamed:@"tapSelectedInvite"];
    else
        cell.selectedPersonImageView.image = [UIImage imageNamed:@"tapUnselectedInvite"];
    
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
    cell.nameOfPersonLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:attString];
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
    return [MobileInviteCell height];
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int tag = (int)indexPath.row;
    ABRecordRef contactPerson;
    ABRecordID recordID;
    if (isFiltered) {
        contactPerson = (__bridge ABRecordRef)([filteredPeopleContactList objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
        tag = [MobileDelegate changeTag:tag fromArray:filteredPeopleContactList toArray:peopleContactList];
        
    } else {
        contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:tag]);
        recordID = ABRecordGetRecordID(contactPerson);
    }
    NSString *recordIdString = [NSString stringWithFormat:@"%d",recordID];
    if (![shownChosenPeople containsObject:recordIdString]) {
        [chosenPeople addObject:recordIdString];
        [shownChosenPeople addObject:recordIdString];
    }
    else {
        [shownChosenPeople removeObject:recordIdString];
    }
    [selectedPeopleIndexes addObject:[NSNumber numberWithInt:tag]];
    [contactsTableView reloadData];
}

- (void)donePressed {
    [MobileDelegate sendChosenPeople:chosenPeople forContactList:peopleContactList];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [searchBar endEditing:YES];
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



@end


@implementation MobileInviteCell

+(CGFloat) height {
    return 60;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [MobileInviteCell height]);
    self.contentView.frame = self.frame;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.selectedPersonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 30, 30)];
    self.selectedPersonImageView.tintColor = [FontProperties getOrangeColor];
    self.selectedPersonImageView.center = CGPointMake(self.selectedPersonImageView.center.x, self.center.y);
    [self.contentView addSubview:self.selectedPersonImageView];
    
    self.nameOfPersonLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 10, self.frame.size.width - 55 - 15, 30)];
    self.nameOfPersonLabel.center  = CGPointMake(self.nameOfPersonLabel.center.x, self.center.y);
    [self.contentView addSubview:self.nameOfPersonLabel];
}

@end