//
//  FollowRequestsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FollowRequestsViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"

@interface FollowRequestsViewController ()

@property WGCollection *followRequests;
@property NSNumber *page;
@end

@implementation FollowRequestsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _page = @1;
   
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [FontProperties getOrangeColor];
    titleLabel.font = [FontProperties getTitleFont];
    titleLabel.text = @"Follow Requests";
    [titleLabel sizeToFit];
    [self.navigationItem setTitleView:titleLabel];


    [self initializeLeftBarButton];
    [self initializeFollowRequestTable];
    _followRequests = [[WGCollection alloc] initWithType:[WGNotification class]];
    [self fetchFollowRequests];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Follow Requests View"];
}

- (void) initializeFollowRequestTable {
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void)acceptUser:(id)sender {
    [WGAnalytics tagEvent:@"Follow Request Accepted"];
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:buttonSender.tag inSection:0]];
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    WGNotification *notification = (WGNotification *)[_followRequests objectAtIndex:buttonSender.tag];
    WGUser *user = notification.fromUser;
    
    [[WGProfile currentUser] acceptFollowRequestForUser:user withHandler:^(BOOL success, NSError *error) {
        // Do nothing!
    }];
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width - 100, 54)];
    notificationButton.tag = tag;
    [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:notificationButton];
    
    [cell.contentView addSubview:notificationButton];
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:user.smallCoverImageURL imageArea:[user smallCoverImageArea]];
    profileImageView.layer.cornerRadius = 5;
    profileImageView.layer.borderWidth = 0.5;
    profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(55, 27 - 12, 150, 24)];
    labelName.font = [FontProperties getSmallFont];
    labelName.text = [user fullName];
    labelName.tag = tag;
    labelName.textAlignment = NSTextAlignmentLeft;
    [notificationButton addSubview:labelName];
    
    UIButton *followBackPersonButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 15 - 49, 27 - 15, 49, 30)];
    followBackPersonButton.tag = 100;
    [followBackPersonButton setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
     [followBackPersonButton addTarget:self action:@selector(followedPersonPressed:) forControlEvents:UIControlEventTouchDown];
    
    if ([user.isFollowing boolValue]) {
        followBackPersonButton.tag = -100;
        [followBackPersonButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
    }
    if ([user state] == NOT_YET_ACCEPTED_PRIVATE_USER_STATE) {
        [followBackPersonButton setBackgroundImage:nil forState:UIControlStateNormal];
        [followBackPersonButton setTitle:@"Pending" forState:UIControlStateNormal];
        [followBackPersonButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
        followBackPersonButton.titleLabel.font =  [FontProperties scMediumFont:12.0f];
        followBackPersonButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        followBackPersonButton.layer.borderWidth = 1;
        followBackPersonButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
        followBackPersonButton.layer.cornerRadius = 3;
        followBackPersonButton.tag = 100;
    }
 
   
    [cell.contentView addSubview:followBackPersonButton];

}

- (void)rejectUser:(id)sender {
    [WGAnalytics tagEvent:@"Follow Request Rejected"];
    UIButton *buttonSender = (UIButton *)sender;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:buttonSender.tag inSection:0]];
    for (UIView *subview in [cell.contentView subviews]) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview removeFromSuperview];
        }
    }
    WGNotification *notification = (WGNotification *)[_followRequests objectAtIndex:buttonSender.tag];
    [[WGProfile currentUser] rejectFollowRequestForUser:notification.fromUser withHandler:^(BOOL success, NSError *error) {
        // Do nothing!
    }];
}

- (void)followedPersonPressed:(id)sender {
    UIButton *buttonSender = (UIButton*)sender;
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonOriginInTableView];
    WGUser *user = [self getUserAtIndex:(int)[indexPath row]];
    if (user) {
        if (buttonSender.tag == 50) {
            [buttonSender setTitle:nil forState:UIControlStateNormal];
            [buttonSender setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
            buttonSender.tag = -100;
            user.isBlocked = @NO;
            
            [[WGProfile currentUser] unblock:user withHandler:^(BOOL success, NSError *error) {
                // Do nothing!
            }];
        }
        else if (buttonSender.tag == -100) {
            if (user.privacy == PRIVATE) {
                [buttonSender setBackgroundImage:nil forState:UIControlStateNormal];
                [buttonSender setTitle:@"Pending" forState:UIControlStateNormal];
                [buttonSender setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
                buttonSender.titleLabel.font =  [FontProperties scMediumFont:12.0f];
                buttonSender.titleLabel.textAlignment = NSTextAlignmentCenter;
                buttonSender.layer.borderWidth = 1;
                buttonSender.layer.borderColor = [FontProperties getOrangeColor].CGColor;
                buttonSender.layer.cornerRadius = 3;
                user.isFollowingRequested = @YES;
            }
            else {
                [buttonSender setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
                user.isFollowing = @YES;
            }
            buttonSender.tag = 100;
            [[WGProfile currentUser] follow:user withHandler:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                }
            }];
        } else {
            [buttonSender setTitle:nil forState:UIControlStateNormal];
            [buttonSender setBackgroundImage:[UIImage imageNamed:@"followPersonIcon"] forState:UIControlStateNormal];
            buttonSender.tag = -100;
            user.isFollowing = @NO;
            user.isFollowingRequested = @NO;
            [[WGProfile currentUser] unfollow:user withHandler:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                }
            }];
        }
    }
}


- (WGUser *)getUserAtIndex:(int)index {
    WGUser *user;
    if (index >= 0 && index < [_followRequests count]) {
        WGNotification *notification = (WGNotification *)[_followRequests objectAtIndex:index];
        user = notification.fromUser;
    }
    return user;
}

- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Tablew View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_followRequests count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    
    if ([_followRequests count] == 0) return cell;

    WGNotification *notification = (WGNotification *)[_followRequests objectAtIndex:[indexPath row]];
    WGUser *user = notification.fromUser;
    
    UIButton *notificationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width - 100, 54)];
    notificationButton.tag = [indexPath row];
    [notificationButton addTarget:self action:@selector(profileSegue:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:notificationButton];
    
    [cell.contentView addSubview:notificationButton];
    UIImageView *profileImageView = [[UIImageView alloc] init];
    profileImageView.frame = CGRectMake(10, 10, 35, 35);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:user.smallCoverImageURL imageArea:[user smallCoverImageArea]];
    profileImageView.layer.cornerRadius = 5;
    profileImageView.layer.borderWidth = 0.5;
    profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    profileImageView.layer.masksToBounds = YES;
    [notificationButton addSubview:profileImageView];
    
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(55, 27 - 12, 150, 24)];
    labelName.font = [FontProperties getSmallFont];
    labelName.text = [user fullName];
    labelName.tag = [indexPath row];
    labelName.textAlignment = NSTextAlignmentLeft;
    [notificationButton addSubview:labelName];
    
    UIButton *acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 2*30 - 20, 27 - 13, 30, 30)];
    UIImageView *acceptImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"acceptFollowRequest"]];
    acceptImageView.frame = CGRectMake(0, 0, 30, 30);
    [acceptButton addSubview:acceptImageView];
    acceptButton.tag = [indexPath row];
    [acceptButton addTarget:self action:@selector(acceptUser:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:acceptButton];
    
    UIButton *rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 10 - 30 , 27 - 13, 30, 30)];
    UIImageView *rejectImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rejectFollowRequest"]];
    rejectImageView.frame = CGRectMake(0, 0, 30, 30);
    [rejectButton addSubview:rejectImageView];
    rejectButton.tag = [indexPath row];
    [rejectButton addTarget:self action:@selector(rejectUser:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:rejectButton];
    return cell;
}

- (void)profileSegue:(id)sender {
    int index = (int)((UIButton *)sender).tag;
    WGNotification *notification = (WGNotification *)[_followRequests objectAtIndex:index];
    WGUser *user = notification.fromUser;
    
    FancyProfileViewController *fancyProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: user];
    
    self.profileViewController = fancyProfileViewController;
    [self.navigationController pushViewController: self.profileViewController animated:YES];
}

- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Network Functions

- (void)fetchFollowRequests {
    [WGNotification getFollowRequests:^(WGCollection *collection, NSError *error) {
        _followRequests = collection;
        _page = @([_page intValue] + 1);
        [self.tableView reloadData];
    }];
}

@end
