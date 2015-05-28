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
#import "WGUserParser.h"
#define kTimeDifferenceToShowDate 1800 // 30 minutes

@interface ConversationViewController ()

@property WGUser *user;

@end

JSQMessagesBubbleImageFactory *bubbleFactory;
JSQMessagesBubbleImage *orangeBubble;
JSQMessagesBubbleImage *grayBubble;

@implementation ConversationViewController

- (id)initWithUser: (WGUser *)user
{
    self = [super init];
    if (self) {
        self.user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self initializeMessageForEmptyConversation];
    
    bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    orangeBubble = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    grayBubble = [bubbleFactory outgoingMessagesBubbleImageWithColor:[FontProperties getBlueColor]];
    [self initializeNotificationObservers];
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    [self initializeBlueView];
    
    self.showLoadEarlierMessagesHeader = NO;
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.automaticallyScrollsToMostRecentMessage = YES;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = self.user.fullName;
    [self.navigationController.navigationBar setBackgroundImage:[[FontProperties getBlueColor] imageFromColor]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    self.blueBannerView.hidden = NO;
    
    [WGSpinnerView addDancingGToCenterView:self.view];
    [self fetchFirstPageMessages];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController.navigationBar setBackgroundImage:[[FontProperties getBlueColor] imageFromColor] forBarMetrics:UIBarMetricsDefault];

    [WGAnalytics tagEvent:@"Conversation View"];
    [WGAnalytics tagView:@"conversation" withTargetUser:nil];
}

-(void) viewWillDisappear:(BOOL)animated {
    self.blueBannerView.hidden = YES;
}

-(void) initializeBlueView {
    self.blueBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    self.blueBannerView.backgroundColor = [FontProperties getBlueColor];
    [self.navigationController.view addSubview:self.blueBannerView];
}

-(void) textChanged:(id)sender {
    if ([self.inputToolbar.contentView.textView.text hasSuffix:@"\n"] && self.inputToolbar.contentView.rightBarButtonItem.enabled) {
        [self.inputToolbar.contentView.textView resignFirstResponder];
        [self.inputToolbar.delegate messagesInputToolbar:self.inputToolbar didPressRightBarButton:nil];
    }
}

-(void) keyboardWillShow:(NSNotification *)notification {
    if (!self.viewForEmptyConversation) return;
    
    [UIView
     animateWithDuration:0.5
     animations:^{
         self.viewForEmptyConversation.frame = CGRectMake(self.viewForEmptyConversation.frame.origin.x, self.viewForEmptyConversation.frame.origin.y / 2, self.viewForEmptyConversation.frame.size.width, self.viewForEmptyConversation.frame.size.height);
     }];
    
}

-(void) keyboardWillHide:(NSNotification *)notification {
    if (!self.viewForEmptyConversation) return;
    [UIView
     animateWithDuration:0.5
     animations:^{
         self.viewForEmptyConversation.frame = CGRectMake(self.viewForEmptyConversation.frame.origin.x, self.viewForEmptyConversation.frame.origin.y * 2, self.viewForEmptyConversation.frame.size.width, self.viewForEmptyConversation.frame.size.height);
     }];
}

- (NSString *)senderDisplayName {
    return WGProfile.currentUser.fullName;
}

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%@", WGProfile.currentUser.id];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"whiteBackIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
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
    profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    profileImageView.layer.borderWidth = 1.0f;
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2;
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
    return self.messages.count;
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    WGMessage *message = (WGMessage *)[self.messages objectAtIndex:indexPath.item];
    
    if (!message.isMediaMessage) {
        
        if ([message.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = UIColor.whiteColor;
        }
        else {
            cell.textView.textColor = UIColor.blackColor;
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
    self.navigationController.navigationBarHidden = self.hideNavBar;

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showUser {
    ProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    self.user.isFriend = @YES;
    profileViewController.user = self.user;
        
    [self.navigationController pushViewController:profileViewController animated:YES];
}

-(void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    WGMessage *message = [[WGMessage alloc] init];
    message.message = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    message.created = date;
    message.toUser = self.user;
    message.user = WGProfile.currentUser;
    [WGAnalytics tagAction:@"message_sent"
                    atView:@"conversation"
             andTargetUser:self.user
                   atEvent:nil
           andEventMessage: nil];
    [message sendMessage:^(WGMessage *newMessage, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            WGProfile.currentUser.lastMessageRead = newMessage.created;
        });
    }];
    
    [self updateLastMessagesRead:message];
    self.viewForEmptyConversation.alpha = 0.0f;
    
    self.inputToolbar.contentView.textView.text = @"";
    self.inputToolbar.contentView.rightBarButtonItem.enabled = NO;
    message.id = [NSNumber numberWithInt:(arc4random() % 500000) + 1];
    [self.messages addObject:message];
    [self finishReceivingMessageAnimated:YES];
}

- (void) initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchFirstPageMessages)
                                                 name:@"updateConversation"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textChanged:)
                                                 name:UITextViewTextDidChangeNotification
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
    self.viewForEmptyConversation = [[UIView alloc] initWithFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width, 90)];
    self.viewForEmptyConversation.center = CGPointMake(self.viewForEmptyConversation.center.x, self.view.center.y);
    [self.view addSubview:self.viewForEmptyConversation];
    
    UILabel *startANewChat = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 , [UIScreen mainScreen].bounds.size.width, 30)];
    startANewChat.text = @"Start a new chat today";
    startANewChat.textColor = UIColor.grayColor;
    startANewChat.textAlignment = NSTextAlignmentCenter;
    startANewChat.font = [FontProperties getBigButtonFont];
    self.viewForEmptyConversation.hidden = YES;
    [self.viewForEmptyConversation addSubview:startANewChat];
}

# pragma mark - Network functions

- (void)fetchFirstPageMessages {
    self.isFetching = NO;

    __weak typeof(self) weakSelf = self;
    [self.user getConversation:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        strongSelf.isFetching = NO;

        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        [collection reverse];
        strongSelf.messages = collection;
        if (strongSelf.messages.count == 0) {
            strongSelf.viewForEmptyConversation.hidden = NO;
        } else {
            strongSelf.viewForEmptyConversation.hidden = YES;
        }
        
        strongSelf.showLoadEarlierMessagesHeader = (strongSelf.messages.nextPage != nil);
        [strongSelf.collectionView reloadData];
        [strongSelf scrollToBottomAnimated:YES];
    }];
}

- (void)fetchMessages:(BOOL)scrollToBottom {
    if (!self.messages.nextPage) return;
    if (self.isFetching) return;
    self.isFetching = YES;
    
    __weak typeof(self) weakSelf = self;
    [self.messages getNextPage:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isFetching = NO;

        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        [collection reverse];
        [strongSelf.messages addObjectsFromCollectionToBeginning:collection notInCollection:self.messages];
        strongSelf.messages.nextPage = collection.nextPage;
        strongSelf.showLoadEarlierMessagesHeader = (strongSelf.messages.nextPage != nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.collectionView reloadData];
        });
    }];
   
    
}

- (void)updateLastMessagesRead:(WGMessage *)message {
    if ([message.date compare:WGProfile.currentUser.lastMessageRead] == NSOrderedDescending) {
        WGProfile.currentUser.lastMessageRead = message.created;
    }
}

#pragma mark - UITextField Delegate 

- (void)textViewDidChange:(UITextView *)textView {
    [super textViewDidChange:textView];
//    NSArray *arrayStrings = [textView.text componentsSeparatedByString:@" "];
//    NSString *string = (NSString *)arrayStrings.lastObject;
//    if (string.length == 0) return;
//    if ([[string substringWithRange:NSMakeRange(0, 1)] isEqual:@"@"]) {
//        NSString *text = [string substringWithRange:NSMakeRange(1, string.length - 1)];
//        WGCollection *usersFromText = [WGUserParser usersFromText:text];
//        NSLog(@"tagged: %@", text);
//    }
}


@end
