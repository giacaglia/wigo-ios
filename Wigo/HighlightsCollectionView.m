//
//  HighlightsCollectionView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/20/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "HighlightsCollectionView.h"

#define highlightCellName @"HighLightCellName"
#define kAddPhotoCellName @"AddPhotoCellName"

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
    [self registerClass:[HighlightCell class] forCellWithReuseIdentifier:highlightCellName];
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
    if (indexPath.row == 0 && self.isPeeking) return;
    if (self.isPeeking){
        indexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
    }
    if (indexPath.row != 0 || !self.isPeeking || (WGProfile.currentUser.crossEventPhotosEnabled || [self.event isEqual:WGProfile.currentUser.eventAttending])) {
        [self.placesDelegate showConversationForEvent:self.event
                                    withEventMessages:self.eventMessages
                                              atIndex:(int)indexPath.row];        
    }
}


#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section {
    return 1 + self.eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HighlightCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:highlightCellName forIndexPath: indexPath];
    if (self.isPeeking && indexPath.row == 0) cell.alpha = 0.7f;
    else cell.alpha = 1.0f;

    if (indexPath.row == 0) {
        cell.contentView.frame = CGRectMake(0, 0, [HighlightCell height], [HighlightCell height]);
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.faceImageView.image = nil;
        });
//        [cell.faceImageView setSmallImageForUser:WGProfile.currentUser completed:nil];
        cell.blackOverlayView.hidden = NO;
        cell.faceImageView.alpha = 1.0f;
        cell.orangeDotView.hidden = YES;
        return cell;
    }
    cell.blackOverlayView.hidden = YES;
    indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];
    
    cell.faceImageView.alpha = 1.0f;
    cell.orangeDotView.hidden = YES;

    if (indexPath.row + 1 == self.eventMessages.count &&
        [self.eventMessages.hasNextPage boolValue]) {
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
    if (!self.eventMessages) {
        [self.event getMessages:^(WGCollection *collection, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.cancelFetchMessages = NO;
            [strongSelf didFinishPullToRefresh];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.eventMessages = collection;
            strongSelf.contentSize = CGSizeMake(strongSelf.eventMessages.count *[HighlightCell height], [HighlightCell height]);
            [strongSelf reloadData];
        }];
    } else if ([self.eventMessages.hasNextPage boolValue]) {
        [self.eventMessages addNextPage:^(BOOL success, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.cancelFetchMessages = NO;
            [strongSelf didFinishPullToRefresh];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.contentSize = CGSizeMake(strongSelf.eventMessages.count *[HighlightCell height], [HighlightCell height]);
            [strongSelf reloadData];
        }];
    } else {
        self.cancelFetchMessages = NO;
        [self didFinishPullToRefresh];
    }

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
    
//    self.controller = [[UIImagePickerController alloc] init];
//    self.controller.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
//    self.controller.sourceType = UIImagePickerControllerSourceTypeCamera;
//    self.controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
//    self.controller.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
//    self.controller.showsCameraControls = NO;
//    self.controller.delegate = self;
//
//    float sizeOfCell = 0.9 * (float)[HighlightCell height];
//    NSLog(@"total height: %f, size of cell: %f", [HighlightCell height], sizeOfCell);
//    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
//    CGFloat controllerWidth = sizeOfCell;
//    CGFloat controllerHeight = sizeOfCell;
//    CGFloat cameraWidth =  screenWidth;
//    CGFloat cameraHeight = floor((4/3.0f) * cameraWidth);
//    CGFloat scaleWidth = (controllerWidth / cameraWidth);
//    CGFloat scaleHeight = (controllerHeight / cameraHeight);
//   
//    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 0.0);
//    self.controller.view.transform = CGAffineTransformScale(translate, scaleWidth, scaleHeight);
//    self.controller.view.frame = CGRectMake(0, 0, self.controller.view.frame.size.width, self.controller.view.frame.size.height);
//    self.controller.cameraViewTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, scaleWidth/scaleHeight);
//    [self.contentView addSubview:self.controller.view];

    self.colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.9f * (float) [HighlightCell height], 0.9f * (float) [HighlightCell height])];
    self.colorView.center = self.contentView.center;
    self.colorView.backgroundColor = [FontProperties getBlueColor];
    [self.contentView addSubview:self.colorView];
    
    self.addPhotoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.colorView.frame.size.width, self.colorView.frame.size.height)];
    self.addPhotoLabel.font = [FontProperties montserratRegular:20.0f];
    self.addPhotoLabel.numberOfLines = 0;
    self.addPhotoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.addPhotoLabel.textAlignment = NSTextAlignmentCenter;
    self.addPhotoLabel.text = @"Add\nPhoto";
    self.addPhotoLabel.textColor = UIColor.whiteColor;
    [self.colorView addSubview:self.addPhotoLabel];
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
    
    self.blackOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.faceImageView.frame.size.width, self.faceImageView.frame.size.height)];
    self.blackOverlayView.hidden = YES;
    self.blackOverlayView.backgroundColor = RGB(242, 247, 252);
    self.blackOverlayView.layer.borderColor = [FontProperties getBlueColor].CGColor;
    self.blackOverlayView.layer.borderWidth = 1.0f;
    self.blackOverlayView.layer.cornerRadius = 10.0f;
    [self.faceImageView addSubview:self.blackOverlayView];
    
    UILabel *addPhotoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, self.faceImageView.frame.size.width, 13)];
    addPhotoLabel.center = CGPointMake(addPhotoLabel.center.x, self.faceImageView.center.y + 15);
    addPhotoLabel.text = @"Add Buzz";
    addPhotoLabel.textColor = [FontProperties getBlueColor];;
    addPhotoLabel.textAlignment = NSTextAlignmentCenter;
    addPhotoLabel.font = [FontProperties scMediumFont:16.0f];
    [self.blackOverlayView addSubview:addPhotoLabel];
    
    UIImageView *cameraImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 32)];
    cameraImageView.center = CGPointMake(self.blackOverlayView.center.x, self.faceImageView.center.y - 15);
    cameraImageView.image = [UIImage imageNamed:@"cameraPhoto"];
    [self.blackOverlayView addSubview:cameraImageView];

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
