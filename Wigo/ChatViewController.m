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

@interface ChatViewController () {
    UIView *_lineView;
}

@property UITableView *tableViewOfPeople;
@property WGCollection *messages;
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
    
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [self initializeNewChatButton];
    [self initializeTableOfChats];
    [self initializeLeftBarButton];
    [self initializeRightBarButtonItem];
}

- (void) viewWillAppear:(BOOL)animated {
    [self fetchFirstPageMessages];
    
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
    
    self.navigationItem.title = @"Chats";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    _lineView= [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 1, self.view.frame.size.width, 1)];
    _lineView.backgroundColor = RGBAlpha(122, 193, 226, 0.1f);

    [self.navigationController.navigationBar addSubview: _lineView];
}


- (void) viewDidAppear:(BOOL)animated {
    [WGAnalytics tagEvent:@"Chat View"];

}

- (void) goBack {
    [self.navigationController popViewControllerAnimated: YES];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_lineView removeFromSuperview];
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
    _tableViewOfPeople = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    _tableViewOfPeople.delegate = self;
    _tableViewOfPeople.dataSource = self;
    _tableViewOfPeople.backgroundColor = [UIColor clearColor];
    _tableViewOfPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [_tableViewOfPeople registerClass:[ChatCell class] forCellReuseIdentifier:kChatCellName];
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
        [self fetchMessages];
    }
}

- (void)fetchMessages {
    __weak typeof(self) weakSelf = self;
    if (_fetchingFirstPage) {
        [WGMessage getConversations:^(WGCollection *collection, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            [WiGoSpinnerView removeDancingGFromCenterView:strongSelf.view];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                return;
            }
            strongSelf.messages = collection;
            strongSelf.fetchingFirstPage = NO;
            
            if ([strongSelf.messages count] == 0) {
                strongSelf.tableViewOfPeople.hidden = YES;
                newChatButton.hidden = NO;
            } else {
                strongSelf.tableViewOfPeople.hidden = NO;
                newChatButton.hidden = YES;
            }
            _fetchingFirstPage = NO;
            [strongSelf.tableViewOfPeople reloadData];
            [strongSelf.tableViewOfPeople didFinishPullToRefresh];
        }];
    } else if ([_messages.hasNextPage boolValue]) {
        [_messages addNextPage:^(BOOL success, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.tableViewOfPeople.hidden = NO;
            newChatButton.hidden = YES;
            [strongSelf.tableViewOfPeople reloadData];
            [strongSelf.tableViewOfPeople didFinishPullToRefresh];
        }];
    }
}

- (void)deleteConversationAsynchronusly:(WGMessage *)message {
    [message.otherUser deleteConversation:^(BOOL success, NSError *error) {
        // Do nothing
    }];
}

- (void)markMessageAsRead:(WGMessage *)message {
    [message.otherUser readConversation:^(BOOL success, NSError *error) {
        // Do nothing!
    }];
}


#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int hasNextPage = ([_messages.hasNextPage boolValue] ? 1 : 0);
    return [_messages count] + hasNextPage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:kChatCellName forIndexPath:indexPath];
    
    if ([indexPath row] == [_messages count]) {
        [self fetchMessages];
        return cell;
    }
    
    if ([_messages count] == 0) return cell;
    WGMessage *message = (WGMessage *)[_messages objectAtIndex:[indexPath row]];
    WGUser *user = [message otherUser];
   
    [cell.profileImageView setSmallImageForUser:user completed:nil];
    cell.nameLabel.text = user.fullName;
    cell.timeLabel.text = [message.created getUTCTimeStringToLocalTimeString];

    cell.lastMessageLabel.text = message.message;
    if (message.expired) {
        cell.lastMessageLabel.textColor = RGB(150, 150, 150);
        UIImage *blurredImage = [[[SDWebImageManager sharedManager] imageCache] imageFromMemoryCacheForKey:[message message]];
        if (!blurredImage) {
            blurredImage = [UIImageCrop blurredImageFromImageView:cell.lastMessageImageView withRadius:3.0f];
            [[[SDWebImageManager sharedManager] imageCache] storeImage:blurredImage forKey:[message message]];
        }
        cell.lastMessageImageView.image = blurredImage;
        cell.lastMessageLabel.hidden = YES;
    } else {
        cell.lastMessageLabel.textColor = UIColor.blackColor;
        cell.lastMessageLabel.hidden = NO;
    }
 
    if (![message.isRead boolValue]) cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    else cell.contentView.backgroundColor = UIColor.whiteColor;
    
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
    if (![_messages count] == 0) {
        WGMessage *message = (WGMessage *)[_messages objectAtIndex:[indexPath row]];
        message.isRead = @YES;
        [self markMessageAsRead:message];
        WGUser *user = [message otherUser];
        self.conversationViewController = [[ConversationViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:self.conversationViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WGMessage *message = (WGMessage *)[_messages objectAtIndex:[indexPath row]];
        [self deleteConversationAsynchronusly:message];
        [_messages removeObjectAtIndex:[indexPath row]];
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
    [self.contentView addSubview:self.profileImageView];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
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
}

@end
