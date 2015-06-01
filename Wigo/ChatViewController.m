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
#import "UIButtonAligned.h"
#import "GroupConversationViewController.h"


@interface ChatViewController ()
@property (nonatomic,strong) NSString *chatIdToOpen;
@end


@implementation ChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchMessages) name:@"fetchMessages" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];
    self.messages = NetworkFetcher.defaultGetter.messages;
    self.attendingEvent = [[WGEvent alloc] initWithJSON:@{@"id": @604231511195609600,
                                    @"name": @"Wigo Supernova Launch Party @ Society on High"}];
    [self initializeTableOfChats];
    [self initializeNewChatView];
    self.collectionUsers = [[WGCollection alloc] initWithType:[WGUser class]];
    [self.collectionUsers addObject:WGProfile.currentUser];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lastMessageRead = WGProfile.currentUser.lastMessageRead;
    if (!self.messages) [WGSpinnerView addDancingGToCenterView:self.view];
    [self fetchMessages];
    [self initializeTitleView];
    [self initializeRightBarButtonItem];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Chat View"];
    [WGAnalytics tagView:@"chat_list" withTargetUser:nil];
    [self initializeTitleView];
    [self initializeRightBarButtonItem];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    WGProfile.currentUser.lastMessageRead = [NSDate date];
    [TabBarAuxiliar checkIndex:kIndexOfChats forDate:self.lastMessageRead];
    
    self.tabBarController.navigationItem.titleView = nil;
}

- (void)scrollUp {
    [self.tableViewOfPeople setContentOffset:CGPointZero animated:YES];
}

- (void)initializeTitleView {
    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    chatLabel.text = @"Chat";
    chatLabel.font = [FontProperties mediumFont:18.0f];
    chatLabel.textAlignment = NSTextAlignmentCenter;
    chatLabel.textColor = UIColor.whiteColor;
    self.tabBarController.navigationItem.titleView = chatLabel;
}

- (void)initializeRightBarButtonItem {
    CGRect profileFrame = CGRectMake(0, 0, 30, 21);
    UIButtonAligned *writeButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@3];
    UIImageView *writeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    writeImageView.image = [UIImage imageNamed:@"writeIcon"];
    [writeButton addSubview:writeImageView];
    [writeButton addTarget:self action:@selector(writeMessage)
            forControlEvents:UIControlEventTouchUpInside];
    [writeButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:writeButton];
    self.tabBarController.navigationItem.rightBarButtonItem = profileBarButton;
}

-(void) writeMessage {
    [self.navigationController pushViewController:[MessageViewController new] animated:YES];
}

-(void) initializeNewChatView {
    self.emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    self.emptyView.hidden = YES;
    [self.view addSubview:self.emptyView];
    [self.view bringSubviewToFront:self.emptyView];
    
    UIImageView *emptyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 0.29*self.view.frame.size.width - 70, 14, 0.29*self.view.frame.size.width, 0.48*self.view.frame.size.width)];
    emptyImageView.image = [UIImage imageNamed:@"chatLineView"];
    [self.emptyView addSubview:emptyImageView];
    
    UILabel *startLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, emptyImageView.frame.origin.y + emptyImageView.frame.size.height + 10, self.view.frame.size.width, 40)];
    startLabel.text = @"Start a new chat";
    startLabel.textAlignment = NSTextAlignmentCenter;
    startLabel.textColor = [FontProperties getBlueColor];
    startLabel.font = [FontProperties mediumFont:25.0f];
    [self.emptyView addSubview:startLabel];
}

- (void)initializeTableOfChats {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 20 - 44)];
    self.tableViewOfPeople.delegate = self;
    self.tableViewOfPeople.dataSource = self;
    self.tableViewOfPeople.backgroundColor = UIColor.whiteColor;
    self.tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableViewOfPeople.showsVerticalScrollIndicator = NO;
    [self.tableViewOfPeople registerClass:[ChatCell class] forCellReuseIdentifier:kChatCellName];
    self.tableViewOfPeople.contentOffset = CGPointMake(0, -44.0f);
    [self.view addSubview:self.tableViewOfPeople];
    [self addRefreshToTableView];
}

#pragma mark WGViewController methods

- (void)updateViewWithOptions:(NSDictionary *)options {
    
    NSDictionary *userInfo = options[@"objects"];
    if(userInfo) {
        NSString *chatId = userInfo[@"messages"];
        if(chatId) {
            self.chatIdToOpen = chatId;
        }
    }
}

#pragma mark - RefreshTableView 

- (void)addRefreshToTableView {
    CGFloat contentInset = 44.0f;
    self.tableViewOfPeople.contentInset = UIEdgeInsetsMake(contentInset, 0, 0, 0);
    [WGSpinnerView addDancingGToUIScrollView:self.tableViewOfPeople
                         withBackgroundColor:UIColor.clearColor
                            withContentInset:contentInset
                                 withHandler:^{
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
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        strongSelf.messages = collection;
        if (strongSelf.messages.count == 0) {
            strongSelf.emptyView.hidden = NO;
        } else {
            strongSelf.emptyView.hidden = YES;
        }
        [strongSelf.tableViewOfPeople reloadData];
        [strongSelf.tableViewOfPeople didFinishPullToRefresh];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.chatIdToOpen) {
                NSString *userId = self.chatIdToOpen;
                self.chatIdToOpen = nil;
                    
                WGUser *chatUser = nil;
                for(int i = 0; i < self.messages.count; i++) {
                    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:i];
                    WGUser *user = message.otherUser;
                    if([user.id integerValue] == [userId integerValue]) {
                        chatUser = user;
                    }
                }
                
                if(chatUser) {
                    [self.navigationController pushViewController:[[ConversationViewController alloc] initWithUser:chatUser] animated:NO];
                }
            }
        });
    }];
}

- (void)fetchNextPage {
    if (!self.messages.nextPage) return;
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


#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if (section == kSectionEventChat) return 1;
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:kChatCellName forIndexPath:indexPath];
//    if (indexPath.section == kSectionEventChat) {
//        [cell.profileImageView setSmallImageForUsers:self.collectionUsers];
//        cell.nameLabel.text = self.attendingEvent.name;
//        cell.lastMessageLabel.textColor = RGB(208, 208, 208);
//        cell.lastMessageLabel.text = @"Wigonna work";
//        return cell;
//    }
    if (indexPath.row == self.messages.count - 1) [self fetchNextPage];
    if (self.messages.count  == 0) return cell;
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:indexPath.row];
    if (WGProfile.currentUser.lastMessageRead &&
        ([message.created compare:WGProfile.currentUser.lastMessageRead] == NSOrderedAscending ||
        [message.created compare:WGProfile.currentUser.lastMessageRead] == NSOrderedSame)
        ) {
        cell.lastMessageLabel.textColor = RGB(208, 208, 208);
        cell.orangeNewView.hidden = YES;
    }
    else {
        cell.lastMessageLabel.textColor = UIColor.blackColor;
        cell.orangeNewView.hidden = NO;
    }
    if (indexPath.row == 2) [self.collectionUsers addObject:message.otherUser];
    if (indexPath.row == 3) [self.collectionUsers addObject:message.otherUser];
    cell.message = message;
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [ChatCell height];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.section == kSectionEventChat) {
//        GroupConversationViewController *groupChatVC = [GroupConversationViewController new];
//        
//        groupChatVC.event = self.attendingEvent;
//        [self.navigationController pushViewController:groupChatVC animated:YES];
//        return;
//    }
    if (self.messages.count == 0) return;
    
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:[indexPath row]];
    message.isRead = @YES;
    WGUser *user = message.otherUser;
    [self.navigationController pushViewController:[[ConversationViewController alloc] initWithUser:user] animated:YES];
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
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 15, self.frame.size.width - 85 - 30 - 5, 20)];
    self.nameLabel.font = [FontProperties getSubtitleFont];
    [self.contentView addSubview:self.nameLabel];
    
    self.arrowMsgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, [ChatCell height]/2 - 9.5, 11, 19)];
    self.arrowMsgImageView.image = [UIImage imageNamed:@"arrowMessage"];
    [self.contentView addSubview:self.arrowMsgImageView];

    self.lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 35, self.frame.size.width - 85 - 40, 20)];
    self.lastMessageLabel.font = [FontProperties getSubtitleFont];
    self.lastMessageLabel.textColor = UIColor.blackColor;
    self.lastMessageLabel.textAlignment = NSTextAlignmentLeft;
    self.lastMessageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.lastMessageLabel];
    
    self.orangeNewView = [[UIView alloc] initWithFrame:CGRectMake(6, 6, 12, 12)];
    self.orangeNewView.backgroundColor = [FontProperties getOrangeColor];
    self.orangeNewView.layer.cornerRadius = self.orangeNewView.frame.size.width/2;
    self.orangeNewView.layer.borderColor = UIColor.clearColor.CGColor;
    self.orangeNewView.layer.borderWidth = 1.0f;
    self.orangeNewView.hidden = YES;
    [self.contentView addSubview:self.orangeNewView];
}

- (void)setMessage:(WGMessage *)message {
    WGUser *user = message.otherUser;
    
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text = user.fullName;
    self.lastMessageLabel.text = message.message;
}

@end
