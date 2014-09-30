//
//  InviteViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "InviteViewController.h"
#import "Globals.h"
#define HEIGHT_CELLS 70

UITableView *invitePeopleTableView;
Party *everyoneParty;
NSNumber *page;
NSString *eventName;
NSNumber *eventID;

@implementation InviteViewController

- (id)initWithEventName:(NSString *)newEventName andID:(NSNumber *)newEventID {
    self = [super init];
    if (self) {
        eventID = newEventID;
        eventName = newEventName;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self fetchFirstPageEveryone];
    [self initializeTitle];
    [self initializeTapPeopleTitle];
    [self initializeTableInvite];
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

    UIButton *aroundInviteButton = [[UIButton alloc] initWithFrame:CGRectMake(15 - 5, 40 - 5, 15 + 10, 15 + 10)];
    [aroundInviteButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    [aroundInviteButton setShowsTouchWhenHighlighted:YES];
    [self.view addSubview:aroundInviteButton];
    
    UIImageView *doneImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 15, 15)];
    doneImageView.image = [UIImage imageNamed:@"doneButton"];
    [aroundInviteButton addSubview:doneImageView];
}

- (void)initializeTapPeopleTitle {
    UILabel *tapPeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 64, self.view.frame.size.width - 30, 75)];
    tapPeopleLabel.numberOfLines = 0;
    tapPeopleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tapPeopleLabel.textAlignment = NSTextAlignmentCenter;
    NSString *string;
    if (eventName.length > 0 ) {
        string = [NSString stringWithFormat:@"Tap people you want to see out \nat %@", eventName];
    }
    else {
        string = @"Tap people you want to see out";
    }
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc]
                                             initWithString:string];
    [attString addAttribute:NSFontAttributeName
                      value:[FontProperties lightFont:18.0f]
                      range:NSMakeRange(0, 35 + eventName.length)];
    [attString addAttribute:NSForegroundColorAttributeName
                      value:[FontProperties getBlueColor]
                      range:NSMakeRange(35, eventName.length)];
    tapPeopleLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:attString];
    [self.view addSubview:tapPeopleLabel];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, 64 + 75 - 1, self.view.frame.size.width - 15, 1)];
    lineView.backgroundColor = [FontProperties getLightBlueColor];
    [self.view addSubview:lineView];

}

- (void)donePressed {
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int hasNextPage = ([everyoneParty hasNextPage] ? 1 : 0);
    return [[everyoneParty getObjectArray] count] + hasNextPage;}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.contentView.backgroundColor = [UIColor whiteColor];

    if ([indexPath row] == [[everyoneParty getObjectArray] count] && [[everyoneParty getObjectArray] count] != 0) {
        [self fetchEveryone];
        return cell;
    }
    User *user;
//    if (_isSearching) {
//        if ([[_filteredContentParty getObjectArray] count] == 0) return cell;
//        user = [[_filteredContentParty getObjectArray] objectAtIndex:[indexPath row]];
//    }
//    else {
        if ([[everyoneParty getObjectArray] count] == 0) return cell;
        user = [[everyoneParty getObjectArray] objectAtIndex:[indexPath row]];
//    }
    
    UIButton *aroundTapButton = [[UIButton alloc] initWithFrame:cell.contentView.frame];
    [aroundTapButton addTarget:self action:@selector(tapPressed:) forControlEvents:UIControlEventTouchUpInside];
    aroundTapButton.tag = [indexPath row];
    [cell.contentView addSubview:aroundTapButton];
    
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, HEIGHT_CELLS/2 - 30, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
    [aroundTapButton addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    textLabel.font = [FontProperties getSubtitleFont];
    [aroundTapButton addSubview:textLabel];
    
    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 40, 150, 20)];
    goingOutLabel.font = [FontProperties mediumFont:13.0f];
    goingOutLabel.textAlignment = NSTextAlignmentLeft;
    if ([user isGoingOut]) {
        goingOutLabel.text = @"Going Out";
        goingOutLabel.textColor = [FontProperties getBlueColor];
    }
    [aroundTapButton addSubview:goingOutLabel];
    
    UIImageView *tapImageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 15 - 25, HEIGHT_CELLS/2 - 15, 30, 30)];
    if ([user isTapped]) {
        [tapImageView setImage:[UIImage imageNamed:@"tapSelectedInvite"]];
    }
    else {
        [tapImageView setImage:[UIImage imageNamed:@"tapUnselectedInvite"]];
    }
//    tapButton.layer.borderColor = [UIColor clearColor].CGColor;
//    tapButton.layer.borderWidth = 1.0f;
//    tapButton.layer.cornerRadius = 7.0f;
    [aroundTapButton addSubview:tapImageView];
    
    return cell;
}

- (void) tapPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    User *user = [[everyoneParty getObjectArray] objectAtIndex:tag];
    
    if ([user isTapped]) {
        [buttonSender setBackgroundImage:[UIImage imageNamed:@"tapUnselectedInvite"] forState:UIControlStateNormal];
        [Network sendUntapToUserWithId:[user objectForKey:@"id"]];
        [user setIsTapped:NO];
    }
    else {
        [buttonSender setBackgroundImage:[UIImage imageNamed:@"tapSelectedInvite"] forState:UIControlStateNormal];
        [Network sendAsynchronousTapToUserWithIndex:[user objectForKey:@"id"]];
        [user setIsTapped:YES];
    }
    [everyoneParty replaceObjectAtIndex:tag withObject:user];
    [invitePeopleTableView beginUpdates];
    [invitePeopleTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:tag inSection:0]] withRowAnimation: UITableViewRowAnimationNone];
    [invitePeopleTableView endUpdates];
}

#pragma mark - Network requests


- (void) fetchFirstPageEveryone {
    everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    page = @1;
    [self fetchEveryone];
}

- (void) fetchEveryone {
    NSString *queryString = [NSString stringWithFormat:@"users/?following=true&ordering=invite&page=%@", [page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
        [everyoneParty addObjectsFromArray:arrayOfUsers];
        NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
        [everyoneParty addMetaInfo:metaDictionary];
        [Profile setEveryoneParty:everyoneParty];
        [everyoneParty removeUser:[Profile user]];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            page = @([page intValue] + 1);
            [invitePeopleTableView reloadData];
        });
    }];
}




@end
