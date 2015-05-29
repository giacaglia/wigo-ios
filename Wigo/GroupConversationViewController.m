//
//  NSObject+GroupConversationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/6/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "GroupConversationViewController.h"
#import "ConversationViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import "ProfileViewController.h"

#define kTimeDifferenceToShowDate 1800 // 30 minutes

JSQMessagesBubbleImageFactory *bubbleFactory;
JSQMessagesBubbleImage *orangeBubble;
JSQMessagesBubbleImage *grayBubble;

@implementation GroupConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self initializeNotificationObservers];
    
    bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    orangeBubble = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    grayBubble = [bubbleFactory outgoingMessagesBubbleImageWithColor:[FontProperties getBlueColor]];
    
    [self initializeLeftBarButton];
    [self initializeBlueView];
    [self initializeTableView];
    self.showLoadEarlierMessagesHeader = NO;
    self.automaticallyScrollsToMostRecentMessage = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[[FontProperties getBlueColor] imageFromColor]
forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    
    self.tagUserArray = [NSMutableArray new];
    self.positionArray = [NSMutableArray new];
    self.title = self.event.name;
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

-(void) keyboardWillShow: (NSNotification *)notification {
    if (self.viewForEmptyConversation) {
        [UIView
         animateWithDuration:0.5
         animations:^{
             self.viewForEmptyConversation.frame = CGRectMake(self.viewForEmptyConversation.frame.origin.x, self.viewForEmptyConversation.frame.origin.y / 2, self.viewForEmptyConversation.frame.size.width, self.viewForEmptyConversation.frame.size.height);
         }];
    }
}

-(void) keyboardDidShow: (NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameEnd = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    self.positionOfKeyboard = [keyboardFrameEnd CGRectValue];
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
    return WGProfile.currentUser.fullName;
}

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%@", [WGProfile currentUser].id];
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


- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return (WGEventMessage *)[self.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    WGEventMessage *message = (WGEventMessage *)[self.messages objectAtIndex:indexPath.item];
    UIImage *avatarImage = message.user.avatarImage;
    avatarImage = [JSQMessagesAvatarImageFactory circularAvatarImage:avatarImage withDiameter:48];
    JSQMessagesAvatarImage *jsqImage = [[JSQMessagesAvatarImage alloc] initWithAvatarImage:avatarImage highlightedImage:message.user.avatarImage placeholderImage:[UIImage new]];
    return jsqImage;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    WGEventMessage *message = (WGEventMessage *)[self.messages objectAtIndex:indexPath.item];
    
    if ([message.user.id.stringValue isEqualToString:self.senderId]) {
        return grayBubble;
    }
    
    return orangeBubble;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    WGEventMessage *message = (WGEventMessage *)[self.messages objectAtIndex:indexPath.item];
    if (indexPath.item == 0) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.created];
    }
    WGEventMessage *previousMessage = (WGEventMessage *)[self.messages objectAtIndex:indexPath.item - 1];
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
    
    WGEventMessage *message = (WGEventMessage *)[self.messages objectAtIndex:indexPath.item];
    
    if ([message.user.id.stringValue isEqualToString:self.senderId]) {
        cell.textView.textColor = UIColor.whiteColor;
    }
    else {
        cell.textView.textColor = UIColor.blackColor;
    }
    
    
    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    
    return cell;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    WGEventMessage *message = (WGEventMessage *)[self.messages objectAtIndex:indexPath.item];
    if (indexPath.item == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    WGEventMessage *previousMessage = (WGEventMessage *)[self.messages objectAtIndex:indexPath.item - 1];
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
    [self.navigationController popViewControllerAnimated:YES];
}


-(void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    WGEventMessage *message = [[WGEventMessage alloc] init];
    message.message = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [message setObject:WGProfile.currentUser.id.stringValue forKey:@"user_id"];
    [message setObject:self.event.id forKey:@"event"];
    message.media = @"";
    message.mediaMimeType = kTextType;
    __weak typeof(self) weakSelf = self;
    [message postEventMessage:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [strongSelf.messages removeObject:message];
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.collectionView reloadData];
            [strongSelf scrollToBottomAnimated:YES];
        });
    }];
    self.viewForEmptyConversation.alpha = 0.0f;
    
    self.inputToolbar.contentView.textView.text = @"";
    self.inputToolbar.contentView.rightBarButtonItem.enabled = NO;
    message.user = WGProfile.currentUser;
    self.tagUserArray = [NSMutableArray new];
    self.positionArray = [NSMutableArray new];
    [self.messages addObject:message];
    [self finishReceivingMessageAnimated:YES];
}

- (void) initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchFirstPageMessages)
                                                 name:@"updateConversation"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textChanged:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
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
    if (self.isFetching) return;
    self.isFetching = YES;

    __weak typeof(self) weakSelf = self;
    [self.event getMessages:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        strongSelf.isFetching = NO;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        [collection reverse];
        strongSelf.messages = collection;
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

#pragma mark - Tagging people

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
//    if (range.length == 1)
    NSLog(@"range: %lu, %lu", (unsigned long)range.location, (unsigned long)range.length);
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [super textViewDidChange:textView];
    NSString *text = textView.text;
    if (text.length == 0) return;
    NSString *lastString = [text substringFromIndex: text.length - 1];
    if ([text rangeOfString:@"@"].location == NSNotFound) {
        self.position = nil;
        self.tagTableView.hidden = YES;
        return;
    }
    if ([lastString isEqual:@"@"]) {
        self.tagTableView.hidden = NO;
        self.position = [NSNumber numberWithUnsignedInteger:text.length];
        [self.positionArray addObject:self.position];
        return;
    }
    if (self.position && text.length > self.position.intValue) {
        self.tagTableView.frame = CGRectMake(0, self.positionOfKeyboard.origin.y - 3*[TagPeopleCell height] - self.inputToolbar.frame.size.height, self.view.frame.size.width, 3*[TagPeopleCell height]);
        NSString *searchString = [text substringFromIndex: self.position.intValue];
        if (searchString.length > 0) [self searchText:searchString];
    }
    
}


- (void)searchText:(NSString *)searchString {
    searchString = [searchString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    __weak typeof(self) weakSelf = self;
    [WGUser searchUsers:searchString withHandler:^(NSURL *url, WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.tagPeopleUsers = collection;
                if (collection.count == 1) {
                    strongSelf.tagTableView.frame = CGRectMake(0, strongSelf.positionOfKeyboard.origin.y - [TagPeopleCell height] - strongSelf.inputToolbar.frame.size.height, strongSelf.view.frame.size.width, [TagPeopleCell height]);
                }
                else if (collection.count == 2) {
                    strongSelf.tagTableView.frame = CGRectMake(0, strongSelf.positionOfKeyboard.origin.y - 2*[TagPeopleCell height] - strongSelf.inputToolbar.frame.size.height, strongSelf.view.frame.size.width, 2*[TagPeopleCell height]);
                }
                else {
                    strongSelf.tagTableView.frame = CGRectMake(0, strongSelf.positionOfKeyboard.origin.y - 3*[TagPeopleCell height] - strongSelf.inputToolbar.frame.size.height, strongSelf.view.frame.size.width, 3*[TagPeopleCell height]);
                }
                [strongSelf.tagTableView reloadData];
                [strongSelf.view bringSubviewToFront:strongSelf.tagTableView];
                [strongSelf scrollToBottomAnimated:YES];
            });
        });
    }];
}

-(void)initializeTableView {
    self.tagTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 112)];
    [self.tagTableView registerClass:[TagPeopleCell class] forCellReuseIdentifier:kTagPeopleCellName];
    self.tagTableView.delegate = self;
    self.tagTableView.dataSource = self;
    self.tagTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tagTableView.showsVerticalScrollIndicator = NO;
    self.tagTableView.hidden = YES;
    [self.view addSubview:self.tagTableView];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (int)self.tagPeopleUsers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TagPeopleCell *tagPeopleCell = (TagPeopleCell *)[tableView dequeueReusableCellWithIdentifier:kTagPeopleCellName forIndexPath:indexPath];
    WGUser *user = (WGUser *)[self.tagPeopleUsers objectAtIndex:indexPath.row];
    if (!user) return tagPeopleCell;
    tagPeopleCell.user = user;
    return tagPeopleCell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WGUser *user = (WGUser *)[self.tagPeopleUsers objectAtIndex:indexPath.row];
    if (!user) return;
    [self.tagUserArray addObject:user];
    self.tagTableView.hidden = YES;
    NSString *beforeString = [self.inputToolbar.contentView.textView.text substringToIndex: self.position.intValue];
    self.position = nil;
    self.inputToolbar.contentView.textView.text = [NSString stringWithFormat:@"%@%@", beforeString, user.fullName];
}

@end

@implementation TagPeopleCell

+ (CGFloat) height {
    return 50;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [TagPeopleCell height]);
    self.contentView.frame = self.frame;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 32, 32)];
    self.profileImageView.center = CGPointMake(self.profileImageView.center.x, self.center.y);
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    [self.contentView addSubview:self.profileImageView];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, 150, 20)];
    self.nameLabel.center = CGPointMake(self.nameLabel.center.x, self.center.y);
    self.nameLabel.font = [FontProperties lightFont:12.0f];
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.userInteractionEnabled = NO;
    [self.contentView addSubview:self.nameLabel];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text =  user.fullName;
}

@end
