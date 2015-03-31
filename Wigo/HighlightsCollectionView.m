//
//  HighlightsCollectionView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/20/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "HighlightsCollectionView.h"

#define kHighlightCellName @"HighLightCellName"
#define kAddPhotoCellName @"AddPhotoCellName"
#define kAddPhotoSection 0
#define kHighlightSection 1

@implementation HighlightsCollectionView

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = UIColor.clearColor;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    self.pagingEnabled = NO;
    [self registerClass:[HighlightCell class] forCellWithReuseIdentifier:kHighlightCellName];
    [self registerClass:[AddPhotoCell class] forCellWithReuseIdentifier:kAddPhotoCellName];
    [self registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kHighlightsHeader];
    
    self.dataSource = self;
    self.delegate = self;
    self.scrollEnabled = YES;
    self.showAddPhoto = YES;
}

- (void)setEvent:(WGEvent *)event {
    _event = event;
    self.eventMessages = [WGCollection serializeResponse:event.messages andClass:[WGEventMessage class]];
    self.contentSize = CGSizeMake(self.eventMessages.count *[HighlightCell height], [HighlightCell height]);
    [self reloadData];
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![self.event isEqual:WGProfile.currentUser.eventAttending] && self.eventMessages.count == 0 && !WGProfile.currentUser.crossEventPhotosEnabled) return;
    if (indexPath.section == kAddPhotoSection && self.isPeeking) return;
    if (self.isPeeking){
        indexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:indexPath.section];
    }
    if (indexPath.section != kAddPhotoSection || !self.isPeeking || (WGProfile.currentUser.crossEventPhotosEnabled || [self.event isEqual:WGProfile.currentUser.eventAttending])) {
        int index = indexPath.item + 1;
        if (indexPath.section == kAddPhotoSection) index -= 1;
        [self.placesDelegate showConversationForEvent:self.event
                                    withEventMessages:self.eventMessages
                                              atIndex:index];
    }
}


#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section {
    if (section == kAddPhotoSection)  {
        if (self.event.isExpired.boolValue) return 0;
       return 1;
    }
    if (section == kHighlightSection) return self.eventMessages.count;
    return 0;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kAddPhotoSection) {
        AddPhotoCell *addPhotoCell = [collectionView dequeueReusableCellWithReuseIdentifier:kAddPhotoCellName forIndexPath: indexPath];
        if (self.isPeeking) addPhotoCell.alpha = 0.7f;
        else addPhotoCell.alpha = 1.0f;
        return addPhotoCell;
    }
    HighlightCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kHighlightCellName forIndexPath: indexPath];
    cell.alpha = 1.0f;
    
    cell.faceImageView.alpha = 1.0f;
    cell.orangeDotView.hidden = YES;

    if (indexPath.row == self.eventMessages.count) {
        [self fetchEventMessages];
    }
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:[indexPath row]];
    
    NSString *contentURL;
    if (eventMessage.thumbnail) contentURL = eventMessage.thumbnail;
    else  contentURL = eventMessage.media;
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", WGProfile.currentUser.cdnPrefix, contentURL]];
    [cell.faceImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {}];
    
    if (eventMessage.isRead) {
        if (eventMessage.isRead.boolValue) [cell updateUIToRead:YES];
        else [cell updateUIToRead:NO];
    }
    
    return cell;
}

- (void)showNavigationBar:(UIImagePickerController*)imagePicker {
    [imagePicker setNavigationBarHidden:NO];
}

- (void)fetchEventMessages {
    self.cancelFetchMessages = YES;
    __weak typeof(self) weakSelf = self;
    if (!self.eventMessages.hasNextPage.boolValue) return;
    
    [self.eventMessages addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.cancelFetchMessages = NO;
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        strongSelf.contentSize = CGSizeMake(strongSelf.eventMessages.count *[HighlightCell height], [HighlightCell height]);
        [strongSelf reloadData];
    }];
}

#pragma mark - UICollectionView Header
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kHighlightsHeader
                                                                               forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(5, 1);
}


@end

@implementation AddPhotoCell

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
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

- (void) setup {
    self.backgroundColor = UIColor.clearColor;
    self.frame = CGRectMake(0, 0, [HighlightCell height], [HighlightCell height]);
    self.contentView.frame = self.frame;
    
    UIImageView *cameraImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 62, 62)];
    cameraImageView.image = [UIImage imageNamed:@"addPhoto"];
    cameraImageView.center = CGPointMake(self.contentView.center.x, self.contentView.center.y - 10);
    [self.contentView addSubview:cameraImageView];
    
    UILabel *addBuzzLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, 15)];
    addBuzzLabel.center = CGPointMake(self.contentView.center.x, self.contentView.center.y + 33);
    addBuzzLabel.text = @"Add Buzz";
    addBuzzLabel.textAlignment = NSTextAlignmentCenter;
    addBuzzLabel.textColor = RGB(90, 90, 90);
    addBuzzLabel.font = [FontProperties lightFont:13.0f];
    [self.contentView addSubview:addBuzzLabel];
}

-(BOOL)prefersStatusBarHidden   // iOS8 definitely needs this one. checked.
{
    return NO;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

@end

@implementation HighlightCell

+ (CGFloat)height {
    return [UIScreen mainScreen].bounds.size.width/3.3;
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

- (void) setup {
    self.frame = CGRectMake(0, 0, [HighlightCell height], [HighlightCell height]);
    self.contentView.frame = self.frame;
    
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 3, 0.9*[HighlightCell height], 0.9*[HighlightCell height])];
    self.faceImageView.center = self.contentView.center;
    self.faceImageView.backgroundColor = UIColor.clearColor;
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.faceImageView.layer.masksToBounds = YES;
    self.faceImageView.layer.cornerRadius = 10.0f;
    self.faceImageView.layer.borderWidth = 1.0f;
    self.faceImageView.layer.borderColor = UIColor.clearColor.CGColor;
    [self.contentView addSubview: self.faceImageView];
    
    self.orangeDotView = [[UIView alloc] initWithFrame:CGRectMake(0.9*[HighlightCell height] - 3, 0, 15, 15)];
    self.orangeDotView.backgroundColor = [FontProperties getOrangeColor];
    self.orangeDotView.layer.borderColor = [UIColor clearColor].CGColor;
    self.orangeDotView.clipsToBounds = YES;
    self.orangeDotView.layer.borderWidth = 3;
    self.orangeDotView.layer.cornerRadius = 7.5;
    [self.contentView addSubview:self.orangeDotView];

    _isActive = NO;
}


- (void) setIsActive:(BOOL)isActive {
    if (_isActive == isActive) {
        return;
    }
    if (isActive) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 delay: 0.0 options: UIViewAnimationOptionCurveLinear animations:^{
                [self setToActiveWithNoAnimation];
            } completion:^(BOOL finished) {}];
        });
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration: 0.5    animations:^{
                [self resetToInactive];
            }];
        });
    }
    _isActive = isActive;
    
}

- (void)setToActiveWithNoAnimation {
    
    self.faceImageView.transform = CGAffineTransformIdentity;
    
}

- (void) resetToInactive {
//    self.faceAndMediaTypeView.alpha = 0.5f;
//    
//    self.faceImageView.transform = CGAffineTransformMakeScale(0.75, 0.75);
}

- (void)updateUIToRead:(BOOL)read {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (read) {
//            self.faceImageView.alpha = 1.0f;
            self.orangeDotView.hidden = YES;
        } else {
//            self.faceImageView.alpha = 1.0f;
            self.orangeDotView.hidden = NO;
        }
    });
}

- (void)setStateForUser:(WGUser *)user {
    [self.faceImageView setSmallImageForUser:user completed:nil];
    self.user = user;
}

@end


@implementation HighlightsFlowLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}


- (void)setup
{
    self.itemSize = CGSizeMake([HighlightCell height], [HighlightCell height]);
//    self.sectionInset = UIEdgeInsetsMake(0, 10, 10, 10);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

@end
