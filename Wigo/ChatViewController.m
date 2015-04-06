//
//  ChatViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ChatViewController.h"
#import "UIImageCrop.h"
#import "MessageViewController.h"
#import "ConversationViewController.h"


@implementation ChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchMessages) name:@"fetchMessages" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];
    
    self.messages = NetworkFetcher.defaultGetter.messages;
    [self initializeNewChatButton];
    [self initializeTableOfChats];
}

- (void) viewWillAppear:(BOOL)animated {
    [self fetchMessages];
}


- (void) viewDidAppear:(BOOL)animated {
    [WGAnalytics tagView:@"chat_list"];
}


- (void)scrollUp {
    [self.tableViewOfPeople setContentOffset:CGPointZero animated:YES];
}

//- (void)initializeRightBarButtonItem {
//    CGRect profileFrame = CGRectMake(0, 0, 21, 21);
//    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@2];
//    [profileButton setBackgroundImage:[UIImage imageNamed:@"writeIcon"] forState:UIControlStateNormal];
//    [profileButton addTarget:self action:@selector(writeMessage)
//            forControlEvents:UIControlEventTouchUpInside];
//    [profileButton setShowsTouchWhenHighlighted:YES];
//    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
//    self.navigationItem.rightBarButtonItem = profileBarButton;
//
//}

- (void) writeMessage {
    [self.navigationController pushViewController:[MessageViewController new] animated:YES];
}


- (void)initializeNewChatButton {
    self.chatButton = [[UIButton alloc] initWithFrame:CGRectMake(40, self.view.frame.size.height/2 - 20, self.view.frame.size.width - 2*40, 40)];
    [self.chatButton addTarget:self action:@selector(writeMessage) forControlEvents:UIControlEventTouchUpInside];
    self.chatButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    [self.chatButton setTitle:@"Start a New Chat" forState:UIControlStateNormal];
    [self.chatButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    self.chatButton.hidden = YES;
    [self.view addSubview:self.chatButton];
}

- (void)initializeTableOfChats {
    self.tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 49)];
    self.tableViewOfPeople.delegate = self;
    self.tableViewOfPeople.dataSource = self;
    self.tableViewOfPeople.backgroundColor = UIColor.clearColor;
    self.tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableViewOfPeople.showsVerticalScrollIndicator = NO;
    [self.tableViewOfPeople registerClass:[ChatCell class] forCellReuseIdentifier:kChatCellName];
    [self.view addSubview:self.tableViewOfPeople];
    [self addRefreshToTableView];
}

#pragma mark - RefreshTableView 

- (void)addRefreshToTableView {
    [WGSpinnerView addDancingGToUIScrollView:self.tableViewOfPeople withHandler:^{
        [self fetchMessages];
    }];
}

#pragma mark - Network functions


- (void)fetchMessages {
    if (self.isFetching) return;
    self.isFetching = YES;
    __weak typeof(self) weakSelf = self;
    [WGMessage getConversations:^(WGCollection *collection, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.isFetching = NO;
        [WGSpinnerView removeDancingGFromCenterView:self.view];
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        strongSelf.messages = collection;
        if (strongSelf.messages.count == 0) {
            strongSelf.tableViewOfPeople.hidden = YES;
            strongSelf.chatButton.hidden = NO;
        } else {
            strongSelf.tableViewOfPeople.hidden = NO;
            strongSelf.chatButton.hidden = YES;
        }
        [strongSelf.tableViewOfPeople reloadData];
        [strongSelf.tableViewOfPeople didFinishPullToRefresh];
    }];
    
}

- (void)fetchNextPage {
    if (!self.messages.hasNextPage.boolValue) return;
    if (self.isFetching) return;
    self.isFetching = YES;
    __weak typeof(self) weakSelf = self;
    
    [self.messages addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.isFetching = NO;
        [strongSelf.tableViewOfPeople reloadData];
    }];
    
}

- (void)deleteConversationAsynchronusly:(WGMessage *)message {
    [message.otherUser deleteConversation:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionDelete];
        }
    }];
}

- (void)markMessageAsRead:(WGMessage *)message {
    [message.otherUser readConversation:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
        }
    }];
}


#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:kChatCellName forIndexPath:indexPath];
    
    if (indexPath.row == self.messages.count - 1) [self fetchNextPage];
    if (self.messages.count  == 0) return cell;
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:[indexPath row]];
    cell.message = message;
    return cell;
}

- (void) followedPerson:(id)sender {
    UIButton *senderButton = (UIButton*)sender;
    [senderButton setBackgroundImage:[UIImage imageNamed:@"followedPersonIcon"] forState:UIControlStateNormal];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [ChatCell height];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.messages.count == 0) return;
    
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:[indexPath row]];
    message.isRead = @YES;
    [self markMessageAsRead:message];
    WGUser *user = [message otherUser];
    ConversationViewController *conversationViewController = [[ConversationViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:conversationViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WGMessage *message = (WGMessage *)[self.messages objectAtIndex:[indexPath row]];
        [self deleteConversationAsynchronusly:message];
        [self.messages removeObjectAtIndex:[indexPath row]];
        [tableView reloadData];
    }
}

@end

@implementation ChatCell

+ (CGFloat) height {
    return 75.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [ChatCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    
    self.profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    [self.contentView addSubview:self.profileImageView];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 15, 150, 20)];
    self.nameLabel.font = [FontProperties getSubtitleFont];
    [self.contentView addSubview:self.nameLabel];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 90, 10, 80, 20)];
    self.timeLabel.font = [FontProperties lightFont:15.0f];
    self.timeLabel.textColor = RGB(179, 179, 179);
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.timeLabel];
    
    self.lastMessageImageView = [[UIImageView alloc] initWithFrame:CGRectMake(85, 25, 150, 40)];
    [self.contentView addSubview:self.lastMessageImageView];

    self.lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
    self.lastMessageLabel.font = [FontProperties lightFont:13.0f];
    self.lastMessageLabel.textColor = UIColor.blackColor;
    self.lastMessageLabel.textAlignment = NSTextAlignmentLeft;
    self.lastMessageLabel.numberOfLines = 2;
    self.lastMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.lastMessageImageView addSubview:self.lastMessageLabel];
    
    self.orangeNewView = [[UIView alloc] initWithFrame:CGRectMake(6, 6, 12, 12)];
    self.orangeNewView.backgroundColor = [FontProperties getOrangeColor];
    self.orangeNewView.layer.cornerRadius = self.orangeNewView.frame.size.width/2;
    self.orangeNewView.layer.borderColor = UIColor.clearColor.CGColor;
    self.orangeNewView.layer.borderWidth = 1.0f;
    self.orangeNewView.hidden = YES;
    [self.contentView addSubview:self.orangeNewView];
}

- (void)setMessage:(WGMessage *)message {
    WGUser *user = [message otherUser];
    
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text = user.fullName;
    self.timeLabel.text = [message.created getUTCTimeStringToLocalTimeString];
    self.lastMessageLabel.text = message.message;
 
    self.lastMessageImageView.image = nil;
    self.lastMessageLabel.textColor = UIColor.blackColor;
    self.lastMessageLabel.hidden = NO;
    self.orangeNewView.hidden = message.isRead.boolValue;
}

@end
