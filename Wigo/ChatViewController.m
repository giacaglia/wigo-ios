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
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.contentView.backgroundColor = [UIColor whiteColor];

    if ([indexPath row] == [_messages count]) {
        [self fetchMessages];
        return cell;
    }
    
    if ([_messages count] == 0) return cell;
    WGMessage *message = (WGMessage *)[_messages objectAtIndex:[indexPath row]];
    WGUser *user = [message otherUser];
    
    UIImageView *profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[user smallCoverImageURL] imageArea:[user smallCoverImageArea]];
    [cell.contentView addSubview:profileImageView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 150, 20)];
    textLabel.text = [user fullName];
    textLabel.font = [FontProperties getSubtitleFont];
    [cell.contentView addSubview:textLabel];
    
    UIImageView *lastMessageImageView = [[UIImageView alloc] initWithFrame:CGRectMake(85, 25, 150, 40)];
    UILabel *lastMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
    lastMessageLabel.text = [message message];
    lastMessageLabel.font = [FontProperties lightFont:13.0f];
    lastMessageLabel.textColor = [UIColor blackColor];
    lastMessageLabel.textAlignment = NSTextAlignmentLeft;
    lastMessageLabel.numberOfLines = 2;
    lastMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;

    if ([message expired]) {
        lastMessageLabel.textColor = RGB(150, 150, 150);
        lastMessageLabel.text = [message message];
        [lastMessageImageView addSubview:lastMessageLabel];
        UIImage *blurredImage = [[[SDWebImageManager sharedManager] imageCache] imageFromMemoryCacheForKey:[message message]];
        if (!blurredImage) {
            blurredImage = [UIImageCrop blurredImageFromImageView:lastMessageImageView withRadius:3.0f];
            [[[SDWebImageManager sharedManager] imageCache] storeImage:blurredImage forKey:[message message]];
        }
        lastMessageImageView.image = blurredImage;
        [lastMessageLabel removeFromSuperview];
    } else {
        [lastMessageImageView addSubview:lastMessageLabel];
    }
    [cell.contentView addSubview:lastMessageImageView];

    UILabel *timeStampLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 90, 10, 80, 20)];
    timeStampLabel.font = [FontProperties lightFont:15.0f];
    timeStampLabel.text = [message.created getUTCTimeStringToLocalTimeString];
    timeStampLabel.textColor = RGB(179, 179, 179);
    timeStampLabel.textAlignment = NSTextAlignmentRight;
    [cell.contentView addSubview:timeStampLabel];

    if (![message.isRead boolValue]) cell.contentView.backgroundColor = [FontProperties getBackgroundLightOrange];
    
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
