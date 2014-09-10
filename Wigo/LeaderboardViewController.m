//
//  LeaderboardViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/9/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "LeaderboardViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"

UIButton *mostTappedTabButton;
UIButton *partyAnimalTabButton;
UITableView *leaderboardTableView;

@implementation LeaderboardViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"leaderboard"]];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeNavigationItem];
    [self initializeTabsAtTheTop];
    [self initializeLeaderboardTableView];
}

- (void)initializeNavigationItem {
    self.tabBarController.tabBar.hidden = NO;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Leaderboard";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)initializeTabsAtTheTop {
    [self initializeMostTappedTabBar];
    [self initializePartyAnimalsTabBar];
}

- (void)initializeMostTappedTabBar {
    mostTappedTabButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width/2, 40)];
    [mostTappedTabButton setTitle:@"Most Tapped" forState:UIControlStateNormal];
    mostTappedTabButton.backgroundColor = [UIColor clearColor];
    mostTappedTabButton.titleLabel.font = [FontProperties getTitleFont];
    mostTappedTabButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    mostTappedTabButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    mostTappedTabButton.tag = 2;
    [mostTappedTabButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchUpInside];
    mostTappedTabButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    mostTappedTabButton.layer.borderWidth = 1.0;
    [self.view addSubview:mostTappedTabButton];
}

- (void)initializePartyAnimalsTabBar {
    partyAnimalTabButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, 64, self.view.frame.size.width/2, 40)];
    [partyAnimalTabButton setTitle:@"Party Animals" forState:UIControlStateNormal];
    partyAnimalTabButton.backgroundColor = [FontProperties getLightOrangeColor];
    partyAnimalTabButton.titleLabel.font = [FontProperties getTitleFont];
    partyAnimalTabButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    partyAnimalTabButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    partyAnimalTabButton.tag = 3;
    [partyAnimalTabButton addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchUpInside];
    partyAnimalTabButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    partyAnimalTabButton.layer.borderWidth = 1.0;
    [self.view addSubview:partyAnimalTabButton];
}


- (void) changeFilter:(id)sender {
    UIButton *senderButton = (UIButton *)sender;
    int tag = (int)senderButton.tag;
    senderButton.backgroundColor = [FontProperties getLightOrangeColor];
    UIButton *filterButton;
    for (int i = 2; i < 4; i++) {
        if (i != tag) {
            filterButton = (UIButton *)[self.view viewWithTag:i];
            filterButton.backgroundColor = [UIColor clearColor];
        }
    }
}


- (void)loadTableView {
    UIButton *filterButton;
    for (int i = 2; i < 5; i++) {
        filterButton = (UIButton *)[self.view viewWithTag:i];
        filterButton.backgroundColor = [FontProperties getLightOrangeColor];
        [filterButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
}

#pragma mark - UITableView

- (void)initializeLeaderboardTableView {
    leaderboardTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
}

#pragma mark - Network functions

- (void)fetchLeaderBoard {
    NSString *queryString = @"leaderboard";
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
        });
    }];
}


#pragma mark - UITableView Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    return cell;
//    if ([[_contentParty getObjectArray] count] == 0) return cell;
//    User *user = [self getUserAtIndex:(int)[indexPath row]];
//    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
//    UIView *clickableView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 15 - 79, PEOPLEVIEW_HEIGHT_OF_CELLS - 5)];
//    if (![user isEqualToUser:[Profile user]]) [clickableView addGestureRecognizer:tap];
//    clickableView.userInteractionEnabled = YES;
//    clickableView.tag = [indexPath row];
//    [cell.contentView addSubview:clickableView];
//    
//    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(15, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 30, 60, 60)];
//    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
//    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
//    profileImageView.clipsToBounds = YES;
//    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
//    [profileButton addSubview:profileImageView];
//    profileButton.tag = [indexPath row];
//    if (![user isEqualToUser:[Profile user]]) {
//        [profileButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    [cell.contentView addSubview:profileButton];
//    
//    if ([user isFavorite]) {
//        UIImageView *favoriteSmall = [[UIImageView alloc] initWithFrame:CGRectMake(6, profileButton.frame.size.height - 16, 10, 10)];
//        favoriteSmall.image = [UIImage imageNamed:@"favoriteSmall"];
//        [profileButton addSubview:favoriteSmall];
//    }
//    
//    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
//    labelName.font = [FontProperties mediumFont:18.0f];
//    labelName.text = [user fullName];
//    labelName.textAlignment = NSTextAlignmentLeft;
//    labelName.userInteractionEnabled = YES;
//    [clickableView addSubview:labelName];
//    
//    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 45, 150, 20)];
//    goingOutLabel.font =  [FontProperties mediumFont:15.0f];
//    goingOutLabel.textAlignment = NSTextAlignmentLeft;
//    if ([user isGoingOut]) {
//        goingOutLabel.text = @"Going Out";
//        goingOutLabel.textColor = [FontProperties getOrangeColor];
//    }
//    [clickableView addSubview:goingOutLabel];
//    
//    
//    if (![user isEqualToUser:[Profile user]]) {
//        UIButton *followPersonButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, PEOPLEVIEW_HEIGHT_OF_CELLS/2 - 15, 49, 30)];
//        [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
//        followPersonButton.tag = -100;
//        [followPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchUpInside];
//        [cell.contentView addSubview:followPersonButton];
//        if ([user getUserState] == BLOCKED_USER) {
//            [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
//            [followPersonButton setTitle:@"Blocked" forState:UIControlStateNormal];
//            [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
//            followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
//            followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
//            followPersonButton.layer.borderWidth = 1;
//            followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
//            followPersonButton.layer.cornerRadius = 3;
//            followPersonButton.tag = 50;
//        }
//        else {
//            if ([user isFollowing]) {
//                [followPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
//                followPersonButton.tag = 100;
//            }
//            if ([user getUserState] == NOT_YET_ACCEPTED_PRIVATE_USER) {
//                [followPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
//                [followPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
//                [followPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
//                followPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
//                followPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
//                followPersonButton.layer.borderWidth = 1;
//                followPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
//                followPersonButton.layer.cornerRadius = 3;
//                followPersonButton.tag = 100;
//            }
//        }
//    }
//    if ([(NSNumber *)[user objectForKey:@"id"] intValue] > [(NSNumber *)[[Profile user] lastUserRead] intValue]) {
//        cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
//    }
//    
//    return cell;
}

@end
