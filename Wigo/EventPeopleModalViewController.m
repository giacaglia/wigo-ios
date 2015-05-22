//
//  EventPeopleModalViewViewController.m
//  Wigo
//
//  Created by Adam Eagle on 2/1/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "EventPeopleModalViewController.h"
#import "ProfileViewController.h"

#define kNameBarHeight 48.5
#define kBorderWidth 10

int imageWidth;

@implementation EventPeopleModalViewController

- (id)initWithEvent:(WGEvent *)event startIndex:(int)index andBackgroundImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.event = event;
        self.backgroundImage = image;
        self.startIndex = index;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fetchingEventAttendees = NO;

    imageWidth = [UIScreen mainScreen].bounds.size.width - kBorderWidth * 2 - 40;
    
    self.view.backgroundColor = UIColor.clearColor;
    UIImageView* backView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backView.image = self.backgroundImage;
    [self.view addSubview:backView];
    
    AttendeesLayout *layout = [AttendeesLayout new];
    self.attendeesPhotosScrollView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [AttendeesPhotoCell height]) collectionViewLayout:layout];
    self.attendeesPhotosScrollView.center = CGPointMake(self.view.center.x, self.view.center.y + 10);
    self.attendeesPhotosScrollView.backgroundColor = UIColor.clearColor;
    self.attendeesPhotosScrollView.showsHorizontalScrollIndicator = NO;
    self.attendeesPhotosScrollView.pagingEnabled = NO;
    self.attendeesPhotosScrollView.delegate = self;
    self.attendeesPhotosScrollView.dataSource = self;
    [self.attendeesPhotosScrollView registerClass:[AttendeesPhotoCell class] forCellWithReuseIdentifier:kAttendeesCellName];
    [self.attendeesPhotosScrollView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kPeopleModalViewHeader];
     [self.attendeesPhotosScrollView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kPeopleModalViewFooter];
    [self.view addSubview:self.attendeesPhotosScrollView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.attendeesPhotosScrollView.frame.origin.y/2 - 23, self.view.frame.size.width - 30, 28)];
    CGSize size = [self.event.name sizeWithAttributes:
                   @{NSFontAttributeName:[FontProperties semiboldFont:22.0f]}];
    if (size.width > self.view.frame.size.width - 30) {
        titleLabel.frame = CGRectMake(15, MAX(20, self.attendeesPhotosScrollView.frame.origin.y/2 - 23 - 27), self.view.frame.size.width - 30, 55);
    }
    
    titleLabel.text = self.event.name;
    if (self.event.isExpired.boolValue) {
        titleLabel.textColor = RGB(121, 121, 121);
    }
    else {
        titleLabel.textColor = [FontProperties getBlueColor];
    }
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.font = [FontProperties semiboldFont:22.0f];
    [self.view addSubview:titleLabel];
    
    UILabel *numberOfPeopleGoing = [[UILabel alloc] initWithFrame:CGRectMake(15, titleLabel.frame.origin.y + titleLabel.frame.size.height + 6, self.view.frame.size.width - 30, 20)];
    if (self.event.isExpired.boolValue) numberOfPeopleGoing.text = [NSString stringWithFormat:@"%@ went", self.event.numAttending.stringValue];
    else numberOfPeopleGoing.text = [NSString stringWithFormat:@"%@ going", self.event.numAttending.stringValue];
    numberOfPeopleGoing.font = [FontProperties lightFont:16.0f];
    numberOfPeopleGoing.textColor = RGB(119, 119, 119);
    numberOfPeopleGoing.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:numberOfPeopleGoing];
    
    // IOS 4
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        titleLabel.frame = CGRectMake(15, 25, self.view.frame.size.width - 30, 20);
        if (size.width > self.view.frame.size.width - 30) {
            titleLabel.frame = CGRectMake(15, 20, self.view.frame.size.width - 30, 42);

        }
        numberOfPeopleGoing.frame = CGRectMake(15, titleLabel.frame.origin.y + titleLabel.frame.size.height + 6, self.view.frame.size.width - 30, 20);
        self.attendeesPhotosScrollView.center = CGPointMake(self.view.center.x, self.view.center.y + 25);
    }

    self.attendeesPhotosScrollView.contentOffset = CGPointMake((imageWidth + 10) * self.startIndex, 0);
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 25, self.view.frame.size.height - 58, 50, 50)];
    closeButton.center = CGPointMake(closeButton.center.x, self.view.frame.size.height/2 + self.attendeesPhotosScrollView.frame.size.height/2 + self.attendeesPhotosScrollView.frame.origin.y/2);
    closeButton.backgroundColor = UIColor.clearColor;
    UIImageView *closeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12.5, 12.5, 25, 25)];
    closeImageView.image = [UIImage imageNamed:@"closeProfile"];
    [closeButton addSubview:closeImageView];
    [closeButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    UIView *topTapView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.attendeesPhotosScrollView.frame.origin.y)];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissView)];
    [topTapView addGestureRecognizer:tapGestureRecognizer];
    [self.view addSubview:topTapView];
    
    UIView *bottomTapView = [[UIView alloc] initWithFrame:CGRectMake(0, self.attendeesPhotosScrollView.frame.origin.y + self.attendeesPhotosScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - (self.attendeesPhotosScrollView.frame.origin.y + self.attendeesPhotosScrollView.frame.size.height))];
    UITapGestureRecognizer *bottomTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissView)];
    [bottomTapView addGestureRecognizer:bottomTapGesture];
    [self.view addSubview:bottomTapView];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [WGAnalytics tagSubview:@"people_cards"
                     atView:@"where"
             withTargetUser:nil];
    self.placesDelegate.createButton.hidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.placesDelegate.createButton.hidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)reloadCards {
    [self.attendeesPhotosScrollView reloadData];
}

- (void)dismissView {
    [self.navigationController setNavigationBarHidden:NO];
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)presentUser:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    WGUser *attendee = (WGUser *)[self.event.attendees objectAtIndex:buttonSender.tag];
    if (attendee) [self.placesDelegate presentUserAferModalView:attendee forEvent:self.event withDelegate:self];
}

- (void)fetchEventAttendeesAsynchronous {
    if (self.fetchingEventAttendees) return;
    if (!self.event.attendees.nextPage) return;
    self.fetchingEventAttendees = YES;
    __weak typeof(self) weakSelf = self;
    [self.event.attendees addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.fetchingEventAttendees = NO;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        [strongSelf.attendeesPhotosScrollView reloadData];
    }];
    
    
}

#pragma mark - Paging

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _pointNow = scrollView.contentOffset;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint pointNow = _pointNow;
    if (scrollView.contentOffset.x < pointNow.x) {
        [self stoppedScrollingToLeft:YES forScrollView:scrollView];
    } else if (scrollView.contentOffset.x >= pointNow.x) {
        [self stoppedScrollingToLeft:NO forScrollView:scrollView];
    }
}

- (void)stoppedScrollingToLeft:(BOOL)leftBoolean forScrollView:(UIScrollView *)scrollView
{
    NSInteger page = [self getPageForScrollView:scrollView toLeft:leftBoolean];
    [self highlightCellAtPage:page animated:YES];
}

- (NSInteger)getPageForScrollView:(UIScrollView *)scrollView toLeft:(BOOL)leftBoolean {
    float fractionalPage;
    CGFloat pageWidth = imageWidth + 10;
    fractionalPage = (self.attendeesPhotosScrollView.contentOffset.x + 20) / pageWidth;
    NSInteger page;
    if (leftBoolean) {
        if (fractionalPage - floor(fractionalPage) < 0.9) {
            page = floor(fractionalPage);
        } else {
            page = ceil(fractionalPage);
        }
    } else {
        if (fractionalPage - floor(fractionalPage) < 0.1) {
            page = floor(fractionalPage);
        } else {
            page = ceil(fractionalPage);
        }
    }
    return page;
}

- (void)highlightCellAtPage:(NSInteger)page animated:(BOOL)animated {
    page = MAX(page, 0);
    page = MIN(page, self.event.attendees.count - 1);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.attendeesPhotosScrollView setContentOffset:CGPointMake((imageWidth + 10) * page, 0.0f) animated:animated];
    });
    WGUser *user = (WGUser *)[self.event.attendees objectAtIndex:page];
    [WGAnalytics tagViewAction:@"scroll"
                     atSubview:@"people_cards"
                        atView:@"where"
                withTargetUser:user];
}

#pragma mark - UICollectionView Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.event.attendees.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AttendeesPhotoCell *attendeeCell = [collectionView dequeueReusableCellWithReuseIdentifier:kAttendeesCellName forIndexPath:indexPath];
    attendeeCell.chatButton.hidden = NO;
    attendeeCell.imageButton.userInteractionEnabled = YES;
    attendeeCell.inviteView.alpha = 1.0f;
    attendeeCell.imageButton.tag = indexPath.item;
    [attendeeCell.imageButton addTarget:self action:@selector(presentUser:) forControlEvents:UIControlEventTouchUpInside];
    WGUser *attendee = (WGUser *)[self.event.attendees objectAtIndex:indexPath.item];
    attendeeCell.user = attendee;
    attendeeCell.chatButton.tag = indexPath.item;
    attendeeCell.eventPeopleModalDelegate = self;
    if (indexPath.item == self.event.attendees.count - 1) [self fetchEventAttendeesAsynchronous];
    if (self.isPeeking) {
        attendeeCell.chatButton.hidden = YES;
        attendeeCell.inviteView.alpha = 0.0f;
        attendeeCell.addFriendButton.hidden = YES;
    }
    
    return attendeeCell;
}

#pragma mark - UICollectionView Header
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kPeopleModalViewHeader
                                                                               forIndexPath:indexPath];
        return cell;
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kPeopleModalViewFooter
                                                                               forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(20, 1);
}


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(20, 1);
}



#pragma mark - EventPeopleModal Delegate

- (void)chatPressed:(id)sender {
    [self.navigationController setNavigationBarHidden:NO];
    UIButton *buttonSender = (UIButton *)sender;
    WGUser *attendee = (WGUser *)[self.event.attendees objectAtIndex:buttonSender.tag];
    if (attendee) [self.placesDelegate presentConversationForUser:attendee];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)followPressed:(id)sender {
    NSLog(@"followd");
}

@end

@implementation AttendeesPhotoCell

+ (CGFloat)height {
    return imageWidth + 120.0f;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.clipsToBounds = YES;
    self.layer.borderColor = RGBAlpha(225, 225, 225, 29).CGColor;
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 14.0f;
    
    self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.imgView.contentMode = UIViewContentModeScaleAspectFill;
    self.imgView.clipsToBounds = YES;
    self.imgView.userInteractionEnabled = NO;
    [self.contentView addSubview:self.imgView];
    
    self.imageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.imageButton.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.imageButton];

    self.backgroundWhiteView = [[UIView alloc] initWithFrame:CGRectMake(0, imageWidth, imageWidth, 120)];
    self.backgroundWhiteView.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:self.backgroundWhiteView];
    
    self.profileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, imageWidth, kNameBarHeight - 25)];
    self.profileNameLabel.textColor = UIColor.blackColor;
    self.profileNameLabel.textAlignment = NSTextAlignmentCenter;
    self.profileNameLabel.font = [FontProperties lightFont:16.0f];
    [self.backgroundWhiteView addSubview:self.profileNameLabel];
    
    self.mutualFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kNameBarHeight - 25, imageWidth, 20)];
    self.mutualFriendsLabel.textColor = RGB(180, 180, 180);
    self.mutualFriendsLabel.textAlignment = NSTextAlignmentCenter;
    self.mutualFriendsLabel.font = [FontProperties lightFont:12.0f];
    [self.backgroundWhiteView addSubview:self.mutualFriendsLabel];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 49, imageWidth, 0.5)];
    lineView.backgroundColor = RGB(214, 214, 214);
    [self.backgroundWhiteView addSubview:lineView];

    self.chatButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 50, imageWidth/2, 70)];
    [self.chatButton addTarget:self action:@selector(chatPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.chatButton.backgroundColor = UIColor.whiteColor;
    UIImageView *blueChatImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.chatButton.frame.size.width/2 - 16, 10, 32, 32)];
    blueChatImageView.image = [UIImage imageNamed:@"blueCardChat"];
    [self.chatButton addSubview:blueChatImageView];
    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35 + 10, self.chatButton.frame.size.width, 20)];
    chatLabel.textAlignment = NSTextAlignmentCenter;
    chatLabel.text = @"CHAT";
    chatLabel.textColor = RGB(210, 210, 210);
    chatLabel.font = [FontProperties mediumFont:12.0f];
    [self.chatButton addSubview:chatLabel];
    [self.backgroundWhiteView addSubview:self.chatButton];
    
    self.dividerLineView = [[UIView alloc] initWithFrame:CGRectMake(imageWidth/2, 50, 0.5, 70)];
    self.dividerLineView.backgroundColor = RGB(214, 214, 214);
    [self.backgroundWhiteView addSubview:self.dividerLineView];
    
    self.inviteView = [[InviteView alloc] initWithFrame:CGRectMake(imageWidth/2 + 0.5, 50, imageWidth/2, 70)];
    self.inviteView.backgroundColor = UIColor.whiteColor;
    [self.inviteView setup];
    self.inviteView.delegate = self;
    [self.backgroundWhiteView addSubview:self.inviteView];
    
    //Follow button
    self.addFriendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 50, imageWidth, 70)];
    self.addFriendButton.backgroundColor = [FontProperties getOrangeColor];
    [self.addFriendButton addTarget:self action:@selector(followPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIImageView *whiteOrangeFollowImage = [[UIImageView alloc] initWithFrame:CGRectMake(imageWidth/2 - 60, 35 - 10, 30, 20)];
    whiteOrangeFollowImage.image = [UIImage imageNamed:@"whiteOrangeFollow"];
    [self.addFriendButton addSubview:whiteOrangeFollowImage];
    UILabel *addFriendLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageWidth/2 - 20, 35 - 10, 90, 20)];
    addFriendLabel.text = @"Add Friend";
    addFriendLabel.textColor = UIColor.whiteColor;
    addFriendLabel.textAlignment = NSTextAlignmentLeft;
    addFriendLabel.font = [FontProperties mediumFont:18.0f];
    [self.addFriendButton addSubview:addFriendLabel];
    [self.backgroundWhiteView addSubview:self.addFriendButton];
    [self.backgroundWhiteView bringSubviewToFront: self.addFriendButton];
    
    self.pendingLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 50, imageWidth, 70)];
    self.pendingLabel.backgroundColor = RGB(247, 247, 247);
    self.pendingLabel.text = @"Pending";
    self.pendingLabel.textColor = RGB(187, 187, 187);
    self.pendingLabel.textAlignment = NSTextAlignmentCenter;
    self.pendingLabel.font = [FontProperties mediumFont:20.0f];
    [self.backgroundWhiteView addSubview:self.pendingLabel];
    
    self.acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(imageWidth - 74 - 15, 35 - 18.5, 37, 37)];
    UIImageView *acceptImgView = [[UIImageView alloc] initWithFrame:CGRectMake(8.5, 8.5, 20, 20)];
    acceptImgView.image = [UIImage imageNamed:@"acceptButton"];
    [self.acceptButton addSubview:acceptImgView];
    [self.acceptButton addTarget:self action:@selector(acceptPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.backgroundWhiteView addSubview:self.acceptButton];
    
    self.rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(imageWidth - 37 - 10, 35 - 18.5, 37, 37)];
    UIImageView *rejectImgView = [[UIImageView alloc] initWithFrame:CGRectMake(8.5, 8.5, 20, 20)];
    rejectImgView.image = [UIImage imageNamed:@"rejectButton"];
    [self.rejectButton addSubview:rejectImgView];
    [self.rejectButton addTarget:self action:@selector(rejectPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.backgroundWhiteView addSubview:self.rejectButton];

}

- (void)followPressed:(id)sender {
    self.addFriendButton.hidden = YES;
    self.addFriendButton.enabled = NO;
    self.user.friendRequest = kFriendRequestSent;
    [WGProfile.currentUser friendUser:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
        }
    }];
    [self reloadView];
}

- (void)chatPressed:(id)sender {
    [self.eventPeopleModalDelegate chatPressed:sender];
}

- (void)acceptPressed:(id)sender {
    self.user.isFriend = @YES;
    [WGProfile.currentUser acceptFriendRequestFromUser:self.user withHandler:^(BOOL success, NSError *error) {}];
    [self reloadView];
}

- (void)rejectPressed:(id)sender {
    self.user.isFriend = @NO;
    self.user.friendRequest = kFriendRequestReceived;
    [WGProfile.currentUser rejectFriendRequestForUser:self.user withHandler:^(BOOL success, NSError *error) {}];
    [self reloadView];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    __weak typeof(self) weakSelf = self;
    __weak WGUser *weakUser = _user;
    [self.imgView setSmallImageForUser:_user completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong WGUser* strongUser = weakUser;
            [strongSelf.imgView setImageWithURL:strongUser.coverImageURL placeholderImage:image imageArea:strongUser.coverImageArea completed:nil];
        });
        
    }];
    if ((!user.isFriend || !user.isFriend.boolValue) && !user.isCurrentUser) {
        [_user getMeta:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) return;
            [strongSelf reloadView];
        }];
        [user getNumMutualFriends:^(NSNumber *numMutualFriends, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (numMutualFriends.intValue == 0) strongSelf.mutualFriendsLabel.text = @"No mutual friends";
                else if (numMutualFriends.intValue == 1) strongSelf.mutualFriendsLabel.text = @"1 mutual friend";
                else {
                    strongSelf.mutualFriendsLabel.text = [NSString stringWithFormat:@"%@ mutual friends", numMutualFriends];
                }
            });
        }];
    }
  
    
    if (user.isCurrentUser || (user.isFriend && user.isFriend.boolValue)) {
        self.profileNameLabel.frame = CGRectMake(self.profileNameLabel.frame.origin.x, 25 - self.profileNameLabel.frame.size.height/2, self.profileNameLabel.frame.size.width, self.profileNameLabel.frame.size.height);
    }
    else {
        self.profileNameLabel.frame = CGRectMake(0, 5, imageWidth, kNameBarHeight - 25);
    }
    if (user.age.length > 0) self.profileNameLabel.text = [NSString stringWithFormat:@"%@, %@", user.fullName, user.age];
    else self.profileNameLabel.text = user.fullName;
    self.inviteView.user = user;
    [self reloadView];
}


- (void)reloadView {
    self.addFriendButton.hidden = YES;
    self.chatButton.hidden = YES;
    self.inviteView.alpha = 0.0f;
    self.pendingLabel.hidden = YES;
    self.dividerLineView.hidden = YES;
    self.mutualFriendsLabel.hidden = YES;
    self.acceptButton.hidden = YES;
    self.rejectButton.hidden = YES;
    if (self.user.isCurrentUser || self.user.state == OTHER_SCHOOL_USER_STATE) {
        // Don't show anything
    }
    else if (self.user.state == FRIEND_USER_STATE ||
             self.user.state == CURRENT_USER_STATE) {
        self.dividerLineView.hidden = NO;
        self.chatButton.hidden = NO;
        self.inviteView.alpha = 1.0f;
    }
    else if (self.user.state == NOT_FRIEND_STATE ||
             self.user.state == BLOCKED_USER_STATE) {
        self.addFriendButton.hidden = NO;
        self.mutualFriendsLabel.hidden = NO;
    }
    else if (self.user.state == SENT_REQUEST_USER_STATE) {
        self.pendingLabel.hidden = NO;
        self.mutualFriendsLabel.hidden = NO;
    }
    else if (self.user.state == RECEIVED_REQUEST_USER_STATE) {
        self.acceptButton.hidden = NO;
        self.rejectButton.hidden = NO;
    }
}

#pragma mark - InviteView Delegate

- (void)inviteTapped {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Profile Card", @"Tap Source", nil];
    [WGAnalytics tagEvent:@"Tap User" withDetails:options];
    // self.user??
    [WGAnalytics tagAction:@"event_invite"
                 atSubview:@"people_cards"
                    atView:@"where"
            withTargetUser:self.user];
    
    self.user.isTapped = @YES;
    [WGProfile.currentUser tapUser:self.user withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
            return;
        }
    }];

}

@end

@implementation AttendeesLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.itemSize = CGSizeMake(imageWidth, [AttendeesPhotoCell height]);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.minimumInteritemSpacing = 10.0;
    self.minimumLineSpacing = 10.0;
}


@end

