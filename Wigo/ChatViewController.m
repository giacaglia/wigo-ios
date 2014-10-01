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
@property BOOL fetchingFirstPage;
@end

UIButton *newChatButton;

@implementation ChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFirstPageMessages) name:@"fetchMessages" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];

    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 1, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGBAlpha(244, 149, 45, 0.1f);
    [self.navigationController.navigationBar addSubview:lineView];
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [self initializeNewChatButton];
    [self initializeTableOfChats];
}

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
    UITabBarController *tabController = (UITabBarController *)self.parentViewController.parentViewController;
    tabController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"chatsSelected"];
    tabController.tabBar.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabBarToOrange" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTabBarNotifications" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadColorWhenTabBarIsMessage" object:nil];
    [self fetchFirstPageMessages];
}


- (void) viewDidAppear:(BOOL)animated {
    [EventAnalytics tagEvent:@"Chat View"];

    self.tabBarController.tabBar.hidden = NO;
    
    
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Chats";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self initializeRightBarButtonItem];
    
    self.navigationItem.leftBarButtonItem = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTabBarNotifications" object:nil];
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


- (void)initializeNewChatButton {
    newChatButton = [[UIButton alloc] initWithFrame:CGRectMake(40, self.view.frame.size.height/2 - 20, self.view.frame.size.width - 2*40, 40)];
    [newChatButton addTarget:self action:@selector(writeMessage) forControlEvents:UIControlEventTouchUpInside];
    newChatButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    [newChatButton setTitle:@"Start a New Chat" forState:UIControlStateNormal];
    [newChatButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    newChatButton.hidden = YES;
    [self.view addSubview:newChatButton];
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
    if (!_fetchingFirstPage) {
        _fetchingFirstPage = YES;
        _page = @1;
        [self fetchMessages];
    }
}

- (void)fetchMessages {
    NSString *queryString = [NSString stringWithFormat:@"conversations/?page=%@", [_page stringValue]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
            if ([_page isEqualToNumber:@1])  _messageParty = [[Party alloc] initWithObjectType:MESSAGE_TYPE];
            NSArray *arrayOfMessages = [jsonResponse objectForKey:@"objects"];
            [_messageParty addObjectsFromArray:arrayOfMessages];
            NSDictionary *metaDictionary = [jsonResponse objectForKey:@"meta"];
            [_messageParty addMetaInfo:metaDictionary];
            if ([_page isEqualToNumber:@1]) _fetchingFirstPage = NO;
            _page = @([_page intValue] + 1);
            if ([[_messageParty getObjectArray] count] == 0) {
                _tableViewOfPeople.hidden = YES;
                newChatButton.hidden = NO;
            }
            else {
                _tableViewOfPeople.hidden = NO;
                newChatButton.hidden = YES;
            }
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
    cell.contentView.backgroundColor = [UIColor whiteColor];

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
    [profileImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
    [cell.contentView addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    textLabel.font = [FontProperties getSubtitleFont];
    [cell.contentView addSubview:textLabel];
    
    UIImageView *lastMessageImageView = [[UIImageView alloc] initWithFrame:CGRectMake(85, 25, 150, 40)];
    UILabel *lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
    lastMessageLabel.text = [message messageString];
    lastMessageLabel.font = [FontProperties lightFont:13.0f];
    lastMessageLabel.textColor = [UIColor blackColor];
    lastMessageLabel.textAlignment = NSTextAlignmentLeft;
    lastMessageLabel.numberOfLines = 2;
    lastMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;

    if ([message expired]) {
        lastMessageLabel.textColor = RGB(150, 150, 150);
        lastMessageLabel.text = [message messageString];
        [lastMessageImageView addSubview:lastMessageLabel];
        UIImage *blurredImage = [[[SDWebImageManager sharedManager] imageCache] imageFromMemoryCacheForKey:[message messageString]];
        if (!blurredImage) {
            blurredImage = [UIImageCrop blurredImageFromImageView:lastMessageImageView withRadius:3.0f];
            [[[SDWebImageManager sharedManager] imageCache] storeImage:blurredImage forKey:[message messageString]];
        }
        lastMessageImageView.image = blurredImage;
        [lastMessageLabel removeFromSuperview];
    }
    else {
        [lastMessageImageView addSubview:lastMessageLabel];
    }
    [cell.contentView addSubview:lastMessageImageView];

    UILabel *timeStampLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 90, 10, 80, 20)];
    timeStampLabel.font = [FontProperties lightFont:15.0f];
    timeStampLabel.text = [message timeOfCreation];
    timeStampLabel.textColor = RGB(179, 179, 179);
    timeStampLabel.textAlignment = NSTextAlignmentRight;
    [cell.contentView addSubview:timeStampLabel];

    if (![message isRead]) cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    
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
