//
//  ChatViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ChatViewController.h"
#import "FontProperties.h"
#import <QuartzCore/QuartzCore.h>
#import "UIButtonAligned.h"

#import "Message.h"
#import "Network.h"
#import "MBProgressHUD.h"

@interface ChatViewController ()

@property UITableView *tableViewOfPeople;
@property Party * messageParty;

@end

@implementation ChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [Network queryAsynchronousAPI:@"messages/summary/?to_user=me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSArray *arrayOfMessages = [jsonResponse objectForKey:@"latest"];
            _messageParty = [[Party alloc] initWithObjectName:@"Message"];
            [_messageParty addObjectsFromArray:arrayOfMessages];
            [self initializeTableOfChats];
        });
    }];
}

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"chatsSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
}


- (void) viewDidAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"CHATS";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    CGRect profileFrame = CGRectMake(0, 0, 21, 21);
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
    [profileButton setBackgroundImage:[UIImage imageNamed:@"writeIcon"] forState:UIControlStateNormal];
    [profileButton addTarget:self action:@selector(writeMessage)
            forControlEvents:UIControlEventTouchUpInside];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItem = profileBarButton;
    
    self.navigationItem.leftBarButtonItem = nil;
}


- (void) writeMessage {
    self.messageViewController = [[MessageViewController alloc] init];
    [self.navigationController pushViewController:self.messageViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)initializeTableOfChats {
    _tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    _tableViewOfPeople.delegate = self;
    _tableViewOfPeople.dataSource = self;
    _tableViewOfPeople.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableViewOfPeople];

}


#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_messageParty getObjectArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [[_messageParty getObjectArray] objectAtIndex:[indexPath row]];
    User *user = [message fromUser];
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    profileImageView.image = [user coverImage];
    [cell.contentView addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    if (indexPath.row == 0) {
        cell.backgroundColor = [UIColor colorWithRed:244/255.0f green:149/255.0f blue:45/255.0f alpha:0.1f];
    }
//    if (_isSearching) {
//        textLabel.text = [_filteredContentList objectAtIndex:indexPath.row];
//    }
//    else {
//        textLabel.text = [_contentList objectAtIndex:indexPath.row];
//    }
    textLabel.font = [FontProperties getSubtitleFont];
    [cell.contentView addSubview:textLabel];
    
    UILabel *lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 30, 150, 20)];
    lastMessageLabel.text = [message messageString];
    lastMessageLabel.font = [UIFont fontWithName:@"Whitney-Light" size:13.0f];
    lastMessageLabel.textColor = [UIColor blackColor];
    lastMessageLabel.textAlignment = NSTextAlignmentLeft;
    lastMessageLabel.numberOfLines = 0;
    lastMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [cell.contentView addSubview:lastMessageLabel];
    
    UILabel *timeStampLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 90, 10, 80, 20)];
    timeStampLabel.font = [UIFont fontWithName:@"Whitney-Light" size:15.0f];
    timeStampLabel.text = [message timeOfCreation];
    timeStampLabel.textColor = RGB(179, 179, 179);
    timeStampLabel.textAlignment = NSTextAlignmentRight;
    [cell.contentView addSubview:timeStampLabel];
    return cell;
}

- (void) followedPerson:(id)sender {
    UIButton *senderButton = (UIButton*)sender;
    [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [[_messageParty getObjectArray] objectAtIndex:[indexPath row]];
    User *user = [message fromUser];
    [self getChatOfUser:user];
}

- (void) getChatOfUser:(User *)user {
    self.conversationViewController = [[ConversationViewController alloc] initWithUser:user];
    self.conversationViewController.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:self.conversationViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

@end
