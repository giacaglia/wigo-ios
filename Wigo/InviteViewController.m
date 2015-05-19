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

@interface InviteViewController() {
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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    NSSet *savedChosenPeople = [[NSUserDefaults standardUserDefaults] valueForKey:@"chosenPeople"];
    if (savedChosenPeople) chosenPeople = [NSMutableArray arrayWithArray:[savedChosenPeople allObjects]];
    else chosenPeople = [NSMutableArray new];
    [self fetchFirstPageEveryone];
    [self initializeTitle];
    [self initializeTableInvite];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagView:@"invite" withTargetUser:nil];
    [WGAnalytics tagEvent:@"Invite View"];
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
}


- (void)donePressed {
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
        return 1;
    }
    else if (section == kSectionTapCell) {
        return MIN(5, self.presentedUsers.count);
    }
    else if (section == kSectionAllFriends) {
        return MAX(self.presentedUsers.count - 5, 0);
    }
    else {
        if (self.presentedUsers.total.intValue > 10) {
            return 0;
        }
        return MIN(self.presentedSuggestions.count, 5);
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
        
        if (self.presentedUsers.count == 0) return cell;
        if (tag >= self.presentedUsers.count) return cell;
        
        WGUser *user = (WGUser *)[self.presentedUsers objectAtIndex:tag];
        if (!user) return cell;
        cell.user = user;
        [cell.aroundTapButton removeTarget:nil
                                    action:NULL
                          forControlEvents:UIControlEventAllEvents];
        [cell.aroundTapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.aroundTapButton.tag = tag;
        return cell;
    }
    else if (indexPath.section == kSectionAllFriends) {
        TapCell *cell = (TapCell*)[tableView dequeueReusableCellWithIdentifier:kTapCellName forIndexPath:indexPath];
        cell.fullNameLabel.text = nil;
        cell.profileImageView.image = nil;
        cell.goingOutLabel.text = nil;
        cell.tapImageView.image = nil;
        
        if (self.presentedUsers.count == 0) return cell;
        int tag = (int)indexPath.row + 5;
        if (tag >= self.presentedUsers.count) return cell;
        
        WGUser *user = (WGUser *)[self.presentedUsers objectAtIndex:tag];
        if (tag == self.presentedUsers.count - 5 || tag == self.presentedUsers.count - 1) {
            [self getNextPage];
        }
        if (!user) return cell;
        cell.user = user;
        [cell.aroundTapButton removeTarget:nil
                                    action:NULL
                          forControlEvents:UIControlEventAllEvents];
        [cell.aroundTapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.aroundTapButton.tag = tag;
        return cell;
    }
    
    if (indexPath.section == kSectionFollowCell) {
        FollowCell *cell = (FollowCell *)[tableView dequeueReusableCellWithIdentifier:kFollowCellName forIndexPath:indexPath];
        cell.profileImageView.image = nil;
        cell.nameLabel.text = nil;
        if (self.presentedSuggestions.count == 0) return cell;
        if (indexPath.row >=  self.presentedSuggestions.count) return cell;
        WGUser *user = (WGUser *)[self.presentedSuggestions objectAtIndex:indexPath.row];
        cell.followPersonButton.tag = (int)indexPath.row;
        [cell.followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.user = user;
        return cell;
    }
    return nil;
    
}

- (void)tapAllPressed {
    if (WGProfile.tapAll) return;
    
    WGProfile.tapAll = YES;
    TapAllCell *tapAllCell = (TapAllCell *)[self.invitePeopleTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:kSectionTapAllCell]];
    tapAllCell.tapImageView.image = [UIImage imageNamed:@"tapSelectedInvite"];
    __weak typeof(self) weakSelf = self;
    [WGProfile.currentUser tapAllUsersToEvent:event
                                  withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.invitePeopleTableView reloadData];
    }];
    
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
    if (tag >= self.presentedUsers.count) return;
    
    WGUser *user = (WGUser *)[self.presentedUsers objectAtIndex:tag];

    if (!user.isTapped.boolValue) {
        [WGProfile.currentUser inviteUser:user
                                  atEvent:event
                              withHandler:^(BOOL success, NSError *error) {
                                  
                              }];
        user.isTapped = @YES;
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Invite", @"Tap Source", nil];
        [WGAnalytics tagEvent:@"Tap User" withDetails:options];
        [WGAnalytics tagAction:@"event_invite" atView:@"invite" andTargetUser:user atEvent:nil andEventMessage:nil];
    }
    
    [self.presentedUsers replaceObjectAtIndex:tag withObject:user];
    [self.invitePeopleTableView reloadData];
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
    [WGProfile.currentUser searchNotMe:searchString
                           withContext:@"invite"
                           withHandler:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.isSearching = YES;
            strongSelf.presentedUsers = collection;
            [strongSelf.invitePeopleTableView reloadData];
        });
    }];
    
    // Folow users
    [WGUser searchInvites:searchString  withHandler:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.presentedSuggestions = collection;
            [strongSelf.invitePeopleTableView reloadData];
        });
    }];

}

- (void) getNextPage {
    if (self.isFetching) return;
    if (!self.presentedUsers.nextPage) return;

    self.isFetching = YES;
    __weak typeof(self) weakSelf = self;
    [self.presentedUsers addNextPage:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.isFetching = NO;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
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
            strongSelf.presentedUsers = strongSelf.content;
            if (strongSelf.presentedUsers.count < 10) {
                [strongSelf fetchSuggestions];
            }
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
    self.tapAllLabel.text = @"Invite All Friends";
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
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [FollowCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, self.contentView.frame.size.width - 15 - 79 - 15, 60)];
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    [self.profileButton addSubview:self.profileImageView];
    self.profileButton.center = CGPointMake(self.profileButton.center.x, self.center.y);
    [self.contentView addSubview:self.profileButton];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 15, 150, 20)];
    self.nameLabel.font = [FontProperties getSubtitleFont];
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.userInteractionEnabled = NO;
    [self.contentView addSubview:self.nameLabel];

    self.followPersonButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 21 - 49, [FollowCell height] / 2 - 15, 42, 30)];
    [self.contentView addSubview:self.followPersonButton];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text =  user.fullName;
    [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
    [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
    self.followPersonButton.backgroundColor = UIColor.clearColor;

    if (user.isCurrentUser) return;
   
    if (user.state == BLOCKED_USER_STATE) {
        [self.followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
        [self.followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
        self.followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
        self.followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.followPersonButton.layer.borderWidth = 1;
        self.followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
        self.followPersonButton.layer.cornerRadius = 3;
        return;
    }
    if (user.state == FRIEND_USER_STATE) {
        [self.followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
        [self.followPersonButton setTitle:nil forState:UIControlStateNormal];
        return;
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
        return;
    }
}
@end