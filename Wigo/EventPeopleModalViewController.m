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
        self.fetchingEventAttendees = NO;
        self.startIndex = index;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    imageWidth = [UIScreen mainScreen].bounds.size.width - kBorderWidth * 2 - 40;
    
    self.view.backgroundColor = UIColor.clearColor;
    UIImageView* backView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backView.image = self.backgroundImage;
    [self.view addSubview:backView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 24, self.view.frame.size.width - 30, 50)];
    titleLabel.text = self.event.name;
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.font = [FontProperties mediumFont:18.0f];
    [self.view addSubview:titleLabel];
    
    UILabel *numberOfPeopleGoing = [[UILabel alloc] initWithFrame:CGRectMake(15, 74 + 10, self.view.frame.size.width - 30, 20)];
    numberOfPeopleGoing.text = [NSString stringWithFormat:@"Going (%@)", self.event.numAttending.stringValue];
    numberOfPeopleGoing.font = [FontProperties lightFont:16.0f];
    numberOfPeopleGoing.textColor = UIColor.blackColor;
    numberOfPeopleGoing.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:numberOfPeopleGoing];
    
    AttendeesLayout *layout = [AttendeesLayout new];
    self.attendeesPhotosScrollView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, imageWidth + kNameBarHeight + 70) collectionViewLayout:layout];
    self.attendeesPhotosScrollView.center = CGPointMake(self.view.center.x, self.view.center.y + 10);
    self.attendeesPhotosScrollView.backgroundColor = UIColor.clearColor;
    self.attendeesPhotosScrollView.showsHorizontalScrollIndicator = NO;
    self.attendeesPhotosScrollView.pagingEnabled = YES;
    self.attendeesPhotosScrollView.delegate = self;
    self.attendeesPhotosScrollView.dataSource = self;
    [self.attendeesPhotosScrollView registerClass:[AttendeesPhotoCell class] forCellWithReuseIdentifier:kAttendeesCellName];
    [self.view addSubview:self.attendeesPhotosScrollView];

    self.attendeesPhotosScrollView.contentOffset = CGPointMake((imageWidth + 10) * self.startIndex - 20, 0);
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 25, self.view.frame.size.height - 58, 50, 50)];
    closeButton.backgroundColor = UIColor.clearColor;
    UIImageView *closeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12.5, closeButton.frame.size.height - 30, 25, 25)];
    closeImageView.image = [UIImage imageNamed:@"closeProfile"];
    [closeButton addSubview:closeImageView];
    [closeButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dismissView {
    [self.placesDelegate.eventOffsetDictionary setObject:@200
                                                  forKey:self.event.id.stringValue];
    self.placesDelegate.doNotReloadOffsets = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)presentUser:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:buttonSender.tag];
    if (attendee) [self.placesDelegate showUser:attendee.user];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)fetchEventAttendeesAsynchronous {
    if (!self.fetchingEventAttendees) {
        self.fetchingEventAttendees = YES;
        __weak typeof(self) weakSelf = self;
        if ([self.event.attendees.hasNextPage boolValue]) {
            [self.event.attendees addNextPage:^(BOOL success, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    strongSelf.fetchingEventAttendees = NO;
                    return;
                }
                [strongSelf.attendeesPhotosScrollView reloadData];
                strongSelf.fetchingEventAttendees = NO;
            }];
        } else {
            self.fetchingEventAttendees = NO;
        }
    }
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
    CGFloat pageWidth = imageWidth;
    fractionalPage = (self.attendeesPhotosScrollView.contentOffset.x) / pageWidth;
     NSInteger page;
    if (leftBoolean) {
        if (fractionalPage - floor(fractionalPage) < 0.95) {
            page = floor(fractionalPage);
        } else {
            page = ceil(fractionalPage);
        }
    } else {
        if (fractionalPage - floor(fractionalPage) < 0.05) {
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
        [self.attendeesPhotosScrollView setContentOffset:CGPointMake((imageWidth + 10) * page - 20, 0.0f) animated:animated];
    });
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
    attendeeCell.inviteView.alpha = 1.0f;
    attendeeCell.imageButton.tag = indexPath.item;
    [attendeeCell.imageButton addTarget:self action:@selector(presentUser:) forControlEvents:UIControlEventTouchUpInside];
    WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:indexPath.item];
    [attendeeCell setStateForUser:attendee.user];
    attendeeCell.chatButton.tag = indexPath.item;
    attendeeCell.eventPeopleModalDelegate = self;
    if (indexPath.item == self.event.attendees.count - 1) [self fetchEventAttendeesAsynchronous];
    if (self.isPeeking) {
        attendeeCell.chatButton.hidden = YES;
        attendeeCell.inviteView.alpha = 0.0f;
        attendeeCell.followButton.hidden = YES;
    }
    
    return attendeeCell;
}

#pragma mark - EventPeopleModal Delegate

- (void)chatPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:buttonSender.tag];
    if (attendee) [self.placesDelegate presentConversationForUser:attendee.user];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation AttendeesPhotoCell

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
    self.imageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    [self.contentView addSubview:self.imageButton];
   
    self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.imgView.contentMode = UIViewContentModeScaleAspectFill;
    self.imgView.clipsToBounds = YES;
    [self.imageButton addSubview:self.imgView];
    
    UIImageView *blackBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, imageWidth - kNameBarHeight + 15, imageWidth, kNameBarHeight - 15)];
    blackBackgroundImageView.image = [UIImage imageNamed:@"backgroundGradient"];
    [self.contentView addSubview:blackBackgroundImageView];
    
    self.profileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, imageWidth - kNameBarHeight + 15, imageWidth, kNameBarHeight - 15)];
    self.profileNameLabel.textColor = UIColor.whiteColor;
    self.profileNameLabel.textAlignment = NSTextAlignmentCenter;
    self.profileNameLabel.font = [FontProperties lightFont:24.0f];
    [self.contentView addSubview:self.profileNameLabel];
    
    UIView *backgroundWhiteView = [[UIView alloc] initWithFrame:CGRectMake(0, imageWidth, imageWidth, 70)];
    backgroundWhiteView.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:backgroundWhiteView];
    
    self.inviteView = [[InviteView alloc] initWithFrame:CGRectMake(0, 0, imageWidth/2, 70)];
//    self.inviteView.backgroundColor = UIColor.whiteColor;
//    [self.inviteView setup];
    [backgroundWhiteView addSubview:self.inviteView];
    
    self.chatButton = [[UIButton alloc] initWithFrame:CGRectMake(imageWidth/2, 0, imageWidth/2, 70)];
//    [self.chatButton addTarget:self action:@selector(chatPressed:) forControlEvents:UIControlEventTouchUpInside];
//    self.chatButton.backgroundColor = UIColor.whiteColor;
//    UIImageView *orangeChatBubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.chatButton.frame.size.width/2 - 10, 10 + 5, 20, 20)];
//    orangeChatBubbleImageView.image = [UIImage imageNamed:@"chatsIcon"];
//    [self.chatButton addSubview:orangeChatBubbleImageView];
//    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35 - 10 + 10, self.chatButton.frame.size.width, 20)];
//    chatLabel.textAlignment = NSTextAlignmentCenter;
//    chatLabel.text = @"chat";
//    chatLabel.textColor = [FontProperties getOrangeColor];
//    chatLabel.font = [FontProperties scMediumFont:16.0f];
//    [self.chatButton addSubview:chatLabel];
    [backgroundWhiteView addSubview:self.chatButton];
    
    self.layer.borderColor = RGBAlpha(225, 225, 225, 29).CGColor;
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 10.0f;
    
    self.followButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 80, 10, 160, 50)];
    self.followButton.backgroundColor = [UIColor clearColor];
    self.followButton.layer.cornerRadius = 15;
    self.followButton.layer.borderWidth = 1;
    self.followButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    [self.followButton addTarget:self action:@selector(followPressed:) forControlEvents:UIControlEventTouchUpInside];
    [backgroundWhiteView addSubview:self.followButton];
    [backgroundWhiteView bringSubviewToFront: self.followButton];
    
    UILabel *followLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.followButton.frame.size.width - 40, self.followButton.frame.size.height)];
    followLabel.text = @"Follow";
    followLabel.textAlignment = NSTextAlignmentLeft;
    followLabel.textColor = [FontProperties getOrangeColor];
    followLabel.font =  [FontProperties scMediumFont:24.0f];
    [self.followButton addSubview:followLabel];
    
    UIImageView *plusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plusPerson"]];
    plusImageView.frame = CGRectMake(self.followButton.frame.size.width - 28 - 20, self.followButton.frame.size.height/2 - 9, 28, 20);
    plusImageView.tintColor = [FontProperties getOrangeColor];
    [self.followButton addSubview:plusImageView];
}

- (void)followPressed:(id)sender {
    self.followButton.hidden = YES;
    self.followButton.enabled = NO;
}

- (void)chatPressed:(id)sender {
    [self.eventPeopleModalDelegate chatPressed:sender];
}

- (void)setStateForUser:(WGUser *)user {
    __weak typeof(self) weakSelf = self;
    __weak WGUser *weakUser = user;
    [self.imgView setSmallImageForUser:user completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
         dispatch_async(dispatch_get_main_queue(), ^{
             __strong typeof(weakSelf) strongSelf = weakSelf;
             __strong WGUser* strongUser = weakUser;
             [strongSelf.imgView setImageWithURL:strongUser.coverImageURL placeholderImage:image imageArea:strongUser.coverImageArea completed:nil];
         });
        
    }];
    
    if (user.isCurrentUser) {
        self.backgroundNameLabel.backgroundColor = [FontProperties getBlueColor];
        self.chatButton.hidden = YES;
        self.followButton.hidden = YES;
    }
    else {
        self.followButton.hidden = NO;
    }
//    else {
//        self.backgroundNameLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.5f);
//        self.chatButton.hidden = NO;
//    }
    self.profileNameLabel.text = user.fullName;
    [self.inviteView setLabelsForUser:user];
    
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
    self.itemSize = CGSizeMake(imageWidth, imageWidth + 70);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.minimumInteritemSpacing = 10.0;
    self.minimumLineSpacing = 10.0;
}


@end

