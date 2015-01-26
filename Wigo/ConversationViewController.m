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
#import "FancyProfileViewController.h"

#define kTimeDifferenceToShowDate 1800 // 30 minutes

@interface ConversationViewController ()

@property WGUser *user;
@property WGCollection *messages;
@property UIView *viewForEmptyConversation;

@end

JSQMessagesBubbleImageFactory *bubbleFactory;
JSQMessagesBubbleImage *orangeBubble;
JSQMessagesBubbleImage *grayBubble;
FancyProfileViewController *profileViewController;
BOOL fetching;

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
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self fetchFirstPageMessages];
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
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [WGAnalytics tagEvent:@"Conversation View"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void) keyboardWillShow: (NSNotification *)notification {
    if (_viewForEmptyConversation) {
        [UIView
         animateWithDuration:0.5
         animations:^{
             _viewForEmptyConversation.frame = CGRectMake(_viewForEmptyConversation.frame.origin.x, _viewForEmptyConversation.frame.origin.y / 2, _viewForEmptyConversation.frame.size.width, _viewForEmptyConversation.frame.size.height);
         }];
    }
}

-(void) keyboardWillHide: (NSNotification *)notification {
    if (_viewForEmptyConversation) {
        [UIView
         animateWithDuration:0.5
         animations:^{
             _viewForEmptyConversation.frame = CGRectMake(_viewForEmptyConversation.frame.origin.x, _viewForEmptyConversation.frame.origin.y * 2, _viewForEmptyConversation.frame.size.width, _viewForEmptyConversation.frame.size.height);
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
    return (WGMessage *)[_messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    WGMessage *message = (WGMessage *)[_messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return grayBubble;
    }
    
    return orangeBubble;
    
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    WGMessage *message = (WGMessage *)[_messages objectAtIndex:indexPath.item];
    if (indexPath.item == 0) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.created];
    }
    WGMessage *previousMessage = (WGMessage *)[_messages objectAtIndex:indexPath.item - 1];
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
    return [_messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    WGMessage *message = (WGMessage *)[_messages objectAtIndex:indexPath.item];
    
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
    WGMessage *message = (WGMessage *)[_messages objectAtIndex:indexPath.item];
    if (indexPath.item == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    WGMessage *previousMessage = (WGMessage *)[_messages objectAtIndex:indexPath.item - 1];
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
        // Do nothing?
    }];
    
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationController.navigationBar.translucent = YES;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showUser {
    FancyProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [profileViewController setStateWithUser: self.user];
    profileViewController.user = self.user;
    
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationController.navigationBar.translucent = YES;
    
    [self.navigationController pushViewController:profileViewController animated:YES];
}

-(void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    WGMessage *message = [[WGMessage alloc] init];
    message.message = text;
    message.created = date;
    message.toUser = self.user;
    message.user = [WGProfile currentUser];
    [message create:^(BOOL success, NSError *error) {
        if (error) {
            [_messages removeObject:message];
            [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            [self scrollToBottomAnimated:YES];
        });
    }];
    [_viewForEmptyConversation removeFromSuperview];
    self.inputToolbar.contentView.textView.text = @"";
    [_messages addObject:message];
    [self finishReceivingMessageAnimated:YES];
}

- (void) initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addMessage:)
                                                 name:@"updateConversation"
                                               object:nil];
}

- (void)addMessage:(NSNotification *)notification {
    NSNumber *fromUserID = [[notification userInfo] valueForKey:@"id"];
    if (fromUserID && [fromUserID isEqualToNumber:self.user.id]) {
        NSString *messageString = [[notification userInfo] valueForKey:@"message"];
        
        WGMessage *message = [[WGMessage alloc] init];
        message.message = messageString;
        message.created = [NSDate dateInLocalTimezone];
        message.user = self.user;
        message.toUser = [WGProfile currentUser];
        
        [_messages addObject:message];
        
        [self finishReceivingMessageAnimated:YES];
    }
}

- (void)initializeMessageForEmptyConversation {
    _viewForEmptyConversation = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    _viewForEmptyConversation.center = self.view.center;
    
    [self.view addSubview:_viewForEmptyConversation];
    
    UILabel *everyDayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 , self.view.frame.size.width, 30)];
    everyDayLabel.text = @"Start a new chat today.";
    everyDayLabel.textColor = [FontProperties getOrangeColor];
    everyDayLabel.textAlignment = NSTextAlignmentCenter;
    everyDayLabel.font = [FontProperties getBigButtonFont];
    [_viewForEmptyConversation addSubview:everyDayLabel];
}

# pragma mark - Network functions

- (void)fetchFirstPageMessages {
    fetching = NO;
    [self fetchMessages:YES];
}

- (void)fetchMessages:(BOOL)scrollToBottom {
    if (!fetching) {
        fetching = YES;
        [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
        if (!_messages) {
            [self.user getConversation:^(WGCollection *collection, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    fetching = NO;
                    return;
                }
                [collection reverse];
                _messages = collection;
                // [self addFirstPageMessages];
                [WiGoSpinnerView hideSpinnerForView:self.view];
                fetching = NO;
                
                if ([_messages count] == 0) {
                    [self initializeMessageForEmptyConversation];
                } else {
                    [_viewForEmptyConversation removeFromSuperview];
                }
                
                self.showLoadEarlierMessagesHeader = [[_messages hasNextPage] boolValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                    if (scrollToBottom) {
                        [self scrollToBottomAnimated:YES];
                    }
                });
            }];
        } else if ([_messages.hasNextPage boolValue]) {
            [_messages getNextPage:^(WGCollection *collection, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    fetching = NO;
                    return;
                }
                [collection reverse];
                [_messages addObjectsFromCollectionToBeginning:collection];
                _messages.hasNextPage = collection.hasNextPage;
                _messages.nextPage = collection.nextPage;
                
                [_viewForEmptyConversation removeFromSuperview];
                [WiGoSpinnerView hideSpinnerForView:self.view];
                fetching = NO;
                
                self.showLoadEarlierMessagesHeader = [[_messages hasNextPage] boolValue];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                    [self scrollToBottomAnimated:YES];
                });
            }];
        } else {
            fetching = NO;
            [WiGoSpinnerView hideSpinnerForView:self.view];
        }
    }
}

- (void)updateLastMessagesRead:(WGMessage *)message {
    if ([message.id intValue] > [[WGProfile currentUser].lastMessageRead intValue]) {
        [WGProfile currentUser].lastMessageRead = message.id;
    }
}

@end
