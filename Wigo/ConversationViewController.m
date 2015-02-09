//
//  ConversationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ConversationViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import "ProfileViewController.h"

#define kTimeDifferenceToShowDate 1800 // 30 minutes

@interface ConversationViewController ()

@property WGUser *user;

@end

JSQMessagesBubbleImageFactory *bubbleFactory;
JSQMessagesBubbleImage *orangeBubble;
JSQMessagesBubbleImage *grayBubble;
ProfileViewController *profileViewController;

@implementation ConversationViewController

- (id)initWithUser: (WGUser *)user
{
    self = [super init];
    if (self) {
        self.user = user;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeNotificationObservers];
    
    bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    orangeBubble = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor orangeColor]];
    grayBubble = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    
    self.showLoadEarlierMessagesHeader = NO;
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.automaticallyScrollsToMostRecentMessage = YES;
    
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1)];
    bottomLine.backgroundColor = [FontProperties getLightOrangeColor];
    [self.view addSubview:bottomLine];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textChanged:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Title setup
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    self.navigationController.navigationBar.barTintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.tintColor = [FontProperties getOrangeColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [FontProperties getOrangeColor]}];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[FontProperties getOrangeColor] forKey:NSForegroundColorAttributeName];
    
    self.title = [self.user fullName];
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    [self fetchFirstPageMessages];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [WGAnalytics tagEvent:@"Conversation View"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void) textChanged:(id)sender {
    if ([self.inputToolbar.contentView.textView.text hasSuffix:@"\n"] && self.inputToolbar.contentView.rightBarButtonItem.enabled) {
        [self.inputToolbar.contentView.textView resignFirstResponder];
        [self.inputToolbar.delegate messagesInputToolbar:self.inputToolbar didPressRightBarButton:nil];
    }
}

-(void) keyboardWillShow: (NSNotification *)notification {
    if (self.viewForEmptyConversation) {
        [UIView
         animateWithDuration:0.5
         animations:^{
             self.viewForEmptyConversation.frame = CGRectMake(self.viewForEmptyConversation.frame.origin.x, self.viewForEmptyConversation.frame.origin.y / 2, self.viewForEmptyConversation.frame.size.width, self.viewForEmptyConversation.frame.size.height);
         }];
    }
}

-(void) keyboardWillHide: (NSNotification *)notification {
    if (self.viewForEmptyConversation) {
        [UIView
         animateWithDuration:0.5
         animations:^{
             self.viewForEmptyConversation.frame = CGRectMake(self.viewForEmptyConversation.frame.origin.x, self.viewForEmptyConversation.frame.origin.y * 2, self.viewForEmptyConversation.frame.size.width, self.viewForEmptyConversation.frame.size.height);
         }];
    }
}

- (NSString *)senderDisplayName {
    return [[WGProfile currentUser] fullName];
}

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%@", [WGProfile currentUser].id];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
}

- (void) initializeRightBarButton {
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 30, 30) andType:@3];
    [profileButton addTarget:self action:@selector(showUser) forControlEvents:UIControlEventTouchUpInside];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setSmallImageForUser:self.user completed:nil];
    [profileButton addSubview:profileImageView];
    [profileButton setShowsTouchWhenHighlighted:NO];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItem = profileBarButton;
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return (WGMessage *)[self.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return grayBubble;
    }
    
    return orangeBubble;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:indexPath.item];
    if (indexPath.item == 0) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.created];
    }
    WGMessage *previousMessage = (WGMessage *)[self.messages objectAtIndex:indexPath.item - 1];
    if (previousMessage && [message.created timeIntervalSinceDate:previousMessage.created] > kTimeDifferenceToShowDate) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.created];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:indexPath.item];
    
    if (!message.isMediaMessage) {
        
        if ([message.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:indexPath.item];
    if (indexPath.item == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    WGMessage *previousMessage = (WGMessage *)[self.messages objectAtIndex:indexPath.item - 1];
    if (previousMessage && [message.created timeIntervalSinceDate:previousMessage.created] > kTimeDifferenceToShowDate) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender {
    
    [self fetchMessages:NO];
}

- (void) goBack {
    [self.user readConversation:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
        }
    }];
    
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationController.navigationBar.translucent = YES;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showUser {
    ProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    [profileViewController setStateWithUser: self.user];
    profileViewController.user = self.user;
    
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationController.navigationBar.translucent = YES;
    
    [self.navigationController pushViewController:profileViewController animated:YES];
}

-(void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    WGMessage *message = [[WGMessage alloc] init];
    message.message = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    message.created = date;
    message.toUser = self.user;
    message.user = [WGProfile currentUser];
    __weak typeof(self) weakSelf = self;
    [message create:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [strongSelf.messages removeObject:message];
            [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.collectionView reloadData];
            [strongSelf scrollToBottomAnimated:YES];
        });
    }];
    [self.viewForEmptyConversation removeFromSuperview];
    
    self.inputToolbar.contentView.textView.text = @"";
    self.inputToolbar.contentView.rightBarButtonItem.enabled = NO;
    
    [self.messages addObject:message];
    [self finishReceivingMessageAnimated:YES];
}

- (void) initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addMessage:)
                                                 name:@"updateConversation"
                                               object:nil];
}

- (void)addMessage:(NSNotification *)notification {
    NSDictionary *aps = [notification.userInfo objectForKey:@"aps"];
    NSDictionary *alert = [aps objectForKey:@"alert"];
    if (![alert isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *locKeyString = [alert objectForKey:@"loc-key"];
    if (![locKeyString isEqualToString:@"M"]) {
        return;
    }
    NSArray *locArgs = [alert objectForKey:@"loc-args"];
    if ([locArgs count] < 2) {
        return;
    }
    // NSString *fromFullName = locArgs[0];
    NSString *messageString = locArgs[1];
    
    NSNumber *messageID = [[notification userInfo] objectForKey:@"id"];
    
    NSDictionary *fromUser = [[notification userInfo] objectForKey:@"from_user"];
    if (![fromUser isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSNumber *fromUserID = [fromUser objectForKey:@"id"];
    
    if (fromUserID && self.user.id && [fromUserID isEqualToNumber:self.user.id]) {
        WGMessage *message = [[WGMessage alloc] init];
        
        message.id = messageID;
        message.message = messageString;
        message.created = [NSDate dateInLocalTimezone];
        message.user = self.user;
        message.toUser = [WGProfile currentUser];
        
        [self.messages addObject:message];
        
        [self finishReceivingMessageAnimated:YES];
    }
}

- (void)initializeMessageForEmptyConversation {
    self.viewForEmptyConversation = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
    self.viewForEmptyConversation.center = self.view.center;
    
    [self.view addSubview:self.viewForEmptyConversation];
    
    UILabel *everyDayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 , self.view.frame.size.width, 30)];
    everyDayLabel.text = @"Start a new chat today.";
    everyDayLabel.textColor = [FontProperties getOrangeColor];
    everyDayLabel.textAlignment = NSTextAlignmentCenter;
    everyDayLabel.font = [FontProperties getBigButtonFont];
    [self.viewForEmptyConversation addSubview:everyDayLabel];
}

# pragma mark - Network functions

- (void)fetchFirstPageMessages {
    self.fetching = NO;
    [self fetchMessages:YES];
}

- (void)fetchMessages:(BOOL)scrollToBottom {
    if (!self.fetching) {
        self.fetching = YES;
        if (!self.messages) {
            UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 120)];
            [self.view addSubview:loadingView];
            [WGSpinnerView showOrangeSpinnerAddedTo:loadingView];
            __weak typeof(self) weakSelf = self;
            [self.user getConversation:^(WGCollection *collection, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    strongSelf.fetching = NO;
                    return;
                }
                [collection reverse];
                strongSelf.messages = collection;
                [WGSpinnerView hideSpinnerForView:loadingView];
                [loadingView removeFromSuperview];
                strongSelf.fetching = NO;
                
                if (strongSelf.messages.count == 0) {
                    [strongSelf initializeMessageForEmptyConversation];
                } else {
                    [strongSelf.viewForEmptyConversation removeFromSuperview];
                }
                
                strongSelf.showLoadEarlierMessagesHeader = [[strongSelf.messages hasNextPage] boolValue];
                [strongSelf.collectionView reloadData];
                if (scrollToBottom) {
                    [strongSelf scrollToBottomAnimated:YES];
                }
            }];
        } else if ([self.messages.hasNextPage boolValue]) {
            __weak typeof(self) weakSelf = self;
            [self.messages getNextPage:^(WGCollection *collection, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    strongSelf.fetching = NO;
                    return;
                }
                [collection reverse];
                [strongSelf.messages addObjectsFromCollectionToBeginning:collection notInCollection:self.messages];
                strongSelf.messages.hasNextPage = collection.hasNextPage;
                strongSelf.messages.nextPage = collection.nextPage;
                
                [strongSelf.viewForEmptyConversation removeFromSuperview];
                strongSelf.fetching = NO;
                strongSelf.showLoadEarlierMessagesHeader = [[strongSelf.messages hasNextPage] boolValue];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.collectionView reloadData];
                    if (scrollToBottom) {
                        [strongSelf scrollToBottomAnimated:YES];
                    }
                });
            }];
        } else {
            self.fetching = NO;
        }
    }
}

- (void)updateLastMessagesRead:(WGMessage *)message {
    if ([message.id intValue] > [[WGProfile currentUser].lastMessageRead intValue]) {
        [WGProfile currentUser].lastMessageRead = message.id;
    }
}

@end
