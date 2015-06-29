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

@interface ChatViewController ()
@property (nonatomic,strong) NSString *chatIdToOpen;
@end

NSString *const ATLMConversationMetadataNameKey = @"conversationName";


@implementation ChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchMessages) name:@"fetchMessages" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollUp) name:@"scrollUp" object:nil];
    self.messages = NetworkFetcher.defaultGetter.messages;
//    self.attendingEvent = [[WGEvent alloc] initWithJSON:@{@"id": @604231511195609600,
//                                    @"name": @"Wigo Supernova Launch Party @ Society on High"}];
    [self initializeTableOfChats];
    [self initializeNewChatView];
    self.collectionUsers = [[WGCollection alloc] initWithType:[WGUser class]];
    [self.collectionUsers addObject:WGProfile.currentUser];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lastMessageRead = WGProfile.currentUser.lastMessageRead;
//    if (!self.messages) [WGSpinnerView addDancingGToCenterView:self.view];
//    [self fetchMessages];
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
    self.atlasListViewController = [ATLConversationListViewController conversationListViewControllerWithLayerClient:LayerHelper.defaultLyrClient];
    self.atlasListViewController.tableView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    self.atlasListViewController.view.backgroundColor = UIColor.whiteColor;
    self.atlasListViewController.displaysAvatarItem = YES;
    self.atlasListViewController.delegate = self;
    self.atlasListViewController.dataSource = self;
    [self addChildViewController:self.atlasListViewController];
    [self.view addSubview:self.atlasListViewController.view];
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

#pragma mark - ATLConversationListViewControllerDelegate

- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController
                 didSelectConversation:(LYRConversation *)conversation
{
    [self presentControllerWithConversation:conversation];
}

- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController didDeleteConversation:(LYRConversation *)conversation deletionMode:(LYRDeletionMode)deletionMode
{
    NSLog(@"Conversation Successfully Deleted");
}

- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController didFailDeletingConversation:(LYRConversation *)conversation deletionMode:(LYRDeletionMode)deletionMode error:(NSError *)error
{
    NSLog(@"Conversation Deletion Failed with Error: %@", error);
}


- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController didSearchForText:(NSString *)searchText completion:(void (^)(NSSet *))completion
{
    completion([NSSet new]);
    //    [self.participantDataSource participantsMatchingSearchText:searchText completion:^(NSSet *participants) {
    //        completion(participants);
    //    }];
}

#pragma mark - ATLConversationListViewControllerDataSource

- (NSString *)conversationListViewController:(ATLConversationListViewController *)conversationListViewController titleForConversation:(LYRConversation *)conversation
{
    // If we have a Conversation name in metadata, return it.
    NSString *conversationTitle = conversation.metadata[ATLMConversationMetadataNameKey];
    if (conversationTitle.length) {
        return conversationTitle;
    }
    
    NSMutableSet *participantIdentifiers = [conversation.participants mutableCopy];
    [participantIdentifiers minusSet:[NSSet setWithObject:LayerHelper.defaultLyrClient.authenticatedUserID]];
    if (participantIdentifiers.count == 0) return @"Personal Conversation";
    NSMutableArray *firstNames = [NSMutableArray new];
    for (int i = 0; i < NetworkFetcher.defaultGetter.allUsers.count; i++) {
        WGUser *user = (WGUser *)[NetworkFetcher.defaultGetter.allUsers objectAtIndex:i];
        if ([participantIdentifiers containsObject:user.id.stringValue]) {
            [firstNames addObject:user.firstName];
        }
    }
    NSString *firstNamesString = [firstNames componentsJoinedByString:@", "];
    if (firstNamesString.length == 0) return WGProfile.currentUser.firstName;
    return firstNamesString;
}

- (id<ATLAvatarItem>)conversationListViewController:(ATLConversationListViewController *)conversationListViewController
                          avatarItemForConversation:(LYRConversation *)conversation {
    NSMutableSet *participantIdentifiers = [conversation.participants mutableCopy];
    [participantIdentifiers minusSet:[NSSet setWithObject:LayerHelper.defaultLyrClient.authenticatedUserID]];
    if (participantIdentifiers.count == 0) return WGProfile.currentUser;
    for (int i = 0; i < NetworkFetcher.defaultGetter.allUsers.count; i++) {
        WGUser *user = (WGUser *)[NetworkFetcher.defaultGetter.allUsers objectAtIndex:i];
        if ([participantIdentifiers containsObject:user.id.stringValue]) {
            return user;
        }
    }
    return WGProfile.currentUser;
}

- (id<ATLParticipant>)conversationViewController:(ATLConversationViewController *)conversationViewController
                        participantForIdentifier:(NSString *)participantIdentifier {
    for (int i = 0; i < NetworkFetcher.defaultGetter.allUsers.count; i++) {
        WGUser *user = (WGUser *)[NetworkFetcher.defaultGetter.allUsers objectAtIndex:i];
        if ([participantIdentifier isEqualToString:user.id.stringValue]) {
            return user;
        }
    }
    return nil;
}

- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController
                  attributedStringForDisplayOfDate:(NSDate *)date {
    return [[NSAttributedString alloc] initWithString:@"2 weeks ago"];
}

- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController attributedStringForDisplayOfRecipientStatus:(NSDictionary *)recipientStatus {
    return [[NSAttributedString alloc] initWithString:@"read"];
}

#pragma mark - Conversation Selection

// The following method handles presenting the correct `ATLMConversationViewController`, regardeless of the current state of the navigation stack.
- (void)presentControllerWithConversation:(LYRConversation *)conversation
{
    ConversationViewController *conversationViewController = [ConversationViewController conversationViewControllerWithLayerClient:LayerHelper.defaultLyrClient];
    NSMutableSet *participantIdentifiers = [conversation.participants mutableCopy];
    [participantIdentifiers minusSet:[NSSet setWithObject:LayerHelper.defaultLyrClient.authenticatedUserID]];
    WGUser *returnedUser;
    if (participantIdentifiers.count == 0) returnedUser = WGProfile.currentUser;
    for (int i = 0; i < NetworkFetcher.defaultGetter.allUsers.count; i++) {
        WGUser *user = (WGUser *)[NetworkFetcher.defaultGetter.allUsers objectAtIndex:i];
        if ([participantIdentifiers containsObject:user.id.stringValue]) {
            returnedUser = user;
        }
    }
    conversationViewController.conversation = conversation;
    conversationViewController.user = returnedUser;
    [self.navigationController pushViewController:conversationViewController animated:YES];
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
                    message.readDate = message.created;
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
    if (!message.readDate) message.readDate = [NSDate date];
    if ([message.readDate compare:message.created] == NSOrderedAscending) {
        self.lastMessageLabel.textColor = UIColor.blackColor;
    }
    else {
        self.lastMessageLabel.textColor = RGB(208, 208, 208);
    }
}

@end
