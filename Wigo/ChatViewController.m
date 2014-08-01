//
//  ChatViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ChatViewController.h"
#import "Globals.h"

#import "UIButtonAligned.h"
#import "UIImageCrop.h"

@interface ChatViewController ()

@property UITableView *tableViewOfPeople;
@property Party * messageParty;
@property NSNumber *page;

@end

@implementation ChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFirstPageMessages) name:@"fetchMessages" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];

    [self initializeTableOfChats];
}

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"chatsSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
    [self fetchFirstPageMessages];
}


- (void) viewDidAppear:(BOOL)animated {
    [[LocalyticsSession shared] tagScreen:@"Chats"];

    self.tabBarController.tabBar.hidden = NO;
    
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Chats";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self initializeRightBarButtonItem];
    
    self.navigationItem.leftBarButtonItem = nil;
}

- (void)scrollUp {
    [_tableViewOfPeople setContentOffset:CGPointZero animated:YES];
}

- (void)initializeRightBarButtonItem {
    CGRect profileFrame = CGRectMake(0, 0, 21, 21);
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
    [profileButton setBackgroundImage:[UIImage imageNamed:@"writeIcon"] forState:UIControlStateNormal];
    [profileButton addTarget:self action:@selector(writeMessage)
            forControlEvents:UIControlEventTouchUpInside];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItem = profileBarButton;

}

- (void) writeMessage {
    self.messageViewController = [[MessageViewController alloc] init];
    [self.navigationController pushViewController:self.messageViewController animated:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)initializeTableOfChats {
    _tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49)];
    _tableViewOfPeople.delegate = self;
    _tableViewOfPeople.dataSource = self;
    _tableViewOfPeople.backgroundColor = [UIColor clearColor];
    _tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_tableViewOfPeople];
    [self addRefreshToTableView];
}

#pragma mark - RefreshTableView 

- (void)addRefreshToTableView {
    [WiGoSpinnerView addDancingGToUIScrollView:_tableViewOfPeople withHandler:^{
        [self fetchFirstPageMessages];
    }];
}

#pragma mark - Network functions

- (void)fetchFirstPageMessages {
    _page = @1;
    [self fetchMessages];
}

- (void)fetchMessages {
    NSString *queryString = [NSString stringWithFormat:@"conversations/?to_user=me&page=%@", [_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if ([_page isEqualToNumber:@1])  _messageParty = [[Party alloc] initWithObjectType:MESSAGE_TYPE];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSArray *arrayOfMessages = [jsonResponse objectForKey:@"latest"];
            [_messageParty addObjectsFromArray:arrayOfMessages];
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_messageParty addMetaInfo:metaDictionary];
            [_tableViewOfPeople reloadData];
            [_tableViewOfPeople didFinishPullToRefresh];
        });
    }];
    
}

- (void)deleteConversationAsynchronusly:(Message *)message {
    NSString *idString = [(NSNumber*)[[message otherUser] objectForKey:@"id"] stringValue];
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", idString];
    [Network sendAsynchronousHTTPMethod:DELETE withAPIName:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {}];
}

- (void)markMessageAsRead:(Message *)message {
    NSString *idString = [(NSNumber*)[[message otherUser] objectForKey:@"id"] stringValue];
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", idString];
    NSDictionary *options = @{@"read": [NSNumber numberWithBool:YES]};
    [Network sendAsynchronousHTTPMethod:POST
                            withAPIName:queryString
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                            withOptions:options];
}

#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int hasNextPage = ([_messageParty hasNextPage] ? 1 : 0);
    return [[_messageParty getObjectArray] count] + hasNextPage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.backgroundColor = [UIColor whiteColor];

    
    cell.backgroundColor = [UIColor clearColor];
    if ([indexPath row] == [[_messageParty getObjectArray] count]) {
        [self fetchMessages];
        return cell;
    }
    
    if ([[_messageParty getObjectArray] count] == 0) return cell;
    Message *message = [[_messageParty getObjectArray] objectAtIndex:[indexPath row]];
    User *user = [message otherUser];
    if (!user) {
        user = [[User alloc] initWithDictionary:[message objectForKey:@"to_user"]];
    }
    
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    [cell.contentView addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    textLabel.font = [FontProperties getSubtitleFont];
    [cell.contentView addSubview:textLabel];
    
    UIImageView *lastMessageImageView = [[UIImageView alloc] initWithFrame:CGRectMake(85, 25, 150, 40)];
    UILabel *lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
    lastMessageLabel.text = [message messageString];
    lastMessageLabel.font = LIGHT_FONT(13.0f);
    lastMessageLabel.textColor = [UIColor blackColor];
    lastMessageLabel.textAlignment = NSTextAlignmentLeft;
    lastMessageLabel.numberOfLines = 2;
    lastMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;

    if ([message isMessageFromLastDay]) {
        lastMessageLabel.textColor = RGB(150, 150, 150);
        lastMessageLabel.text = [message messageString];
        [lastMessageImageView addSubview:lastMessageLabel];
        lastMessageImageView = [UIImageCrop blurImageView:lastMessageImageView withRadius:3.0f];
        [lastMessageLabel removeFromSuperview];
    }
    else {
        [lastMessageImageView addSubview:lastMessageLabel];
    }
    [cell.contentView addSubview:lastMessageImageView];

    UILabel *timeStampLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 90, 10, 80, 20)];
    timeStampLabel.font = LIGHT_FONT(15.0f);
    timeStampLabel.text = [message timeOfCreation];
    timeStampLabel.textColor = RGB(179, 179, 179);
    timeStampLabel.textAlignment = NSTextAlignmentRight;
    [cell.contentView addSubview:timeStampLabel];
    
    if (![message isRead]) {
        cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    }
    return cell;
}

- (void) followedPerson:(id)sender {
    UIButton *senderButton = (UIButton*)sender;
    [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![[_messageParty getObjectArray] count] == 0) {
        Message *message = [[_messageParty getObjectArray] objectAtIndex:[indexPath row]];
        [message setIsRead:YES];
        [self markMessageAsRead:message];
        User *user = [message otherUser];
        if (!user) {
            user = [[User alloc] initWithDictionary:[message objectForKey:@"to_user"]];
        }
        self.conversationViewController = [[ConversationViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.conversationViewController animated:YES];
        self.tabBarController.tabBar.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Message *message = [[_messageParty getObjectArray] objectAtIndex:[indexPath row]];
        [self deleteConversationAsynchronusly:message];
        [_messageParty removeObjectAtIndex:[indexPath row]];
        [tableView reloadData];
    }
}

#pragma mark - acessory methods


- (UIImage *)imageFromView:(UIView *)v
{
    CGSize size = v.bounds.size;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    size.width *= scale;
    size.height *= scale;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    
    if ([v respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        [v drawViewHierarchyInRect:(CGRect){.origin = CGPointZero, .size = size} afterScreenUpdates:YES];
    }
    else
    {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGContextScaleCTM(ctx, scale, scale);
        
        [v.layer renderInContext:ctx];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
