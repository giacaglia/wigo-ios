//
//  EventPeopleModalViewViewController.m
//  Wigo
//
//  Created by Adam Eagle on 2/1/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "EventPeopleModalViewController.h"

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
    
    imageWidth = [UIScreen mainScreen].bounds.size.width - kBorderWidth * 2;
    
    self.view.backgroundColor = [UIColor clearColor];
    UIImageView* backView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backView.image = self.backgroundImage;
    [self.view addSubview:backView];
    
    AttendeesLayout *layout = [AttendeesLayout new];
    self.attendeesPhotosScrollView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, imageWidth + kNameBarHeight) collectionViewLayout:layout];
    self.attendeesPhotosScrollView.center = self.view.center;
    self.attendeesPhotosScrollView.backgroundColor = UIColor.clearColor;
    self.attendeesPhotosScrollView.showsHorizontalScrollIndicator = NO;
    self.attendeesPhotosScrollView.pagingEnabled = YES;
    self.attendeesPhotosScrollView.delegate = self;
    self.attendeesPhotosScrollView.dataSource = self;
    [self.attendeesPhotosScrollView registerClass:[AttendeesPhotoCell class] forCellWithReuseIdentifier:kAttendeesCellName];
    [self.view addSubview:self.attendeesPhotosScrollView];
    
    [self.attendeesPhotosScrollView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.startIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    CGPoint newOffset = self.attendeesPhotosScrollView.contentOffset;
    newOffset = CGPointMake(newOffset.x - 10, newOffset.y);
    self.attendeesPhotosScrollView.contentOffset = newOffset;
    
//    UIButton *backButtonModal = [[UIButton alloc] initWithFrame:CGRectMake(0, 35, 50, 50)];
//    backButtonModal.backgroundColor = UIColor.clearColor;
//    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 1, 8.75, 15)];
//    backImageView.image = [UIImage imageNamed:@"backButtonModal"];
//    [backButtonModal addSubview:backImageView];
//    [backButtonModal addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:backButtonModal];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 54, self.view.frame.size.width - 30, 50)];
    titleLabel.text = self.event.name;
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.font = [FontProperties openSansRegular:20.0f];
    [self.view addSubview:titleLabel];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 80, 50, 50)];
    closeButton.center = CGPointMake(self.view.center.x, closeButton.center.y);
    closeButton.backgroundColor = UIColor.clearColor;
    UIImageView *closeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(25 - 7.5, 50 - 15, 15, 15)];
    closeImageView.image = [UIImage imageNamed:@"closeModalView"];
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


//-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    _pointNow = scrollView.contentOffset;
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
//                  willDecelerate:(BOOL)decelerate
//{
//    CGPoint pointNow = _pointNow;
//    if (decelerate) {
//        if (scrollView.contentOffset.x < pointNow.x) {
//            [self stoppedScrollingToLeft:YES forScrollView:scrollView];
//        } else if (scrollView.contentOffset.x >= pointNow.x) {
//            [self stoppedScrollingToLeft:NO forScrollView:scrollView];
//        }
//    }
//}
//
//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
//                     withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
//    CGPoint pointNow = _pointNow;
//    if (scrollView.contentOffset.x < pointNow.x) {
//        [self stoppedScrollingToLeft:YES forScrollView:scrollView];
//    } else if (scrollView.contentOffset.x >= pointNow.x) {
//        [self stoppedScrollingToLeft:NO forScrollView:scrollView];
//    }
//}
//
//- (void)stoppedScrollingToLeft:(BOOL)leftBoolean forScrollView:(UIScrollView *)scrollView
//{
//    NSInteger page = [self getPageForScrollView:scrollView toLeft:leftBoolean];
//    [self highlightCellAtPage:page animated:YES];
//}
//
//- (NSInteger)getPageForScrollView:(UIScrollView *)scrollView toLeft:(BOOL)leftBoolean {
//    float fractionalPage;
//    CGFloat pageWidth = [[UIScreen mainScreen] bounds].size.width;
//    fractionalPage = (self.attendeesPhotosScrollView.contentOffset.x) / pageWidth;
//     NSInteger page;
//    if (leftBoolean) {
//        if (fractionalPage - floor(fractionalPage) < 0.95) {
//            page = floor(fractionalPage);
//        } else {
//            page = ceil(fractionalPage);
//        }
//    } else {
//        if (fractionalPage - floor(fractionalPage) < 0.05) {
//            page = floor(fractionalPage);
//        } else {
//            page = ceil(fractionalPage);
//        }
//    }
//    return page;
//}
//
//- (void)highlightCellAtPage:(NSInteger)page animated:(BOOL)animated {
//    page = MAX(page, 0);
//    page = MIN(page, self.event.attendees.count - 1);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.attendeesPhotosScrollView setContentOffset:CGPointMake(([UIScreen mainScreen].bounds.size.width) * page, 0.0f) animated:animated];
//    });
//}

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
    attendeeCell.imageButton.tag = indexPath.item;
    [attendeeCell.imageButton addTarget:self action:@selector(presentUser:) forControlEvents:UIControlEventTouchUpInside];
    WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:indexPath.item];
    [attendeeCell setStateForUser:attendee.user];
    if (indexPath.item == self.event.attendees.count - 1) [self fetchEventAttendeesAsynchronous];
    return attendeeCell;
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
    self.imageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    [self.contentView addSubview:self.imageButton];
   
    self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.imgView.contentMode = UIViewContentModeScaleAspectFill;
    self.imgView.clipsToBounds = YES;
    [self.imageButton addSubview:self.imgView];
    
    self.backgroundNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, imageWidth, imageWidth, kNameBarHeight)];
    [self.contentView addSubview:self.backgroundNameLabel];
    
    self.profileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, imageWidth, imageWidth, kNameBarHeight - 15)];
    self.profileNameLabel.textColor = UIColor.whiteColor;
    self.profileNameLabel.textAlignment = NSTextAlignmentCenter;
    self.profileNameLabel.font = [FontProperties mediumFont:21.0f];
    [self.contentView addSubview:self.profileNameLabel];
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
    } else {
        self.backgroundNameLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.5f);
    }
    self.profileNameLabel.text = user.firstName;
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
    self.itemSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.minimumInteritemSpacing = 0.0;
    self.minimumLineSpacing = 0.0;
}


@end

