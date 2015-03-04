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
    [self.placesDelegate showConversationForEvent:self.event
                                withEventMessages:self.eventMessages
                                          atIndex:(int)indexPath.row];
}


#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self.event isEqual:WGProfile.currentUser.eventAttending]) {
        return 1 + self.eventMessages.count;
    }
    else {
        return self.eventMessages.count; 
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && [self.event isEqual:WGProfile.currentUser.eventAttending]) {
        AddPhotoCell *cell  =[collectionView dequeueReusableCellWithReuseIdentifier:kAddPhotoCellName forIndexPath: indexPath];
        cell.contentView.frame = CGRectMake(0, 0, [HighlightCell height], [HighlightCell height]);
        [self performSelector:@selector(showNavigationBar:) withObject:cell.controller afterDelay:0];
        return cell;
    }
    HighlightCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:highlightCellName forIndexPath: indexPath];
    if ([self.event isEqual:WGProfile.currentUser.eventAttending]) {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];   
    }

    if (indexPath.row + 1 == self.eventMessages.count &&
        [self.eventMessages.hasNextPage boolValue]) {
        [self fetchEventMessages];
    }
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:[indexPath row]];
    
    NSString *contentURL;
    if (eventMessage.thumbnail) contentURL = eventMessage.thumbnail;
    else  contentURL = eventMessage.media;
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, contentURL]];
    [myCell.spinner startAnimating];
    __weak HighlightCell *weakCell = myCell;
    [myCell.faceImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakCell.spinner stopAnimating];
        });
    }];
    
    if (eventMessage.isRead) {
        if ([eventMessage.isRead boolValue]) {
            [myCell updateUIToRead:YES];
        }
        else [myCell updateUIToRead:NO];
    }
    return myCell;
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
    return [UIScreen mainScreen].bounds.size.width/2.9;
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
    
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0.9*[HighlightCell height], 0.9*[HighlightCell height])];
    self.faceImageView.center = self.contentView.center;
    self.faceImageView.backgroundColor = UIColor.blackColor;
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.faceImageView.layer.masksToBounds = YES;
    [self.contentView addSubview: self.faceImageView];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake([HighlightCell height]/4, [HighlightCell height]/4, [HighlightCell height]/2, [HighlightCell height]/2)];
    self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    [self.contentView addSubview:self.spinner];
    
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
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (read) {
//            self.faceAndMediaTypeView.alpha = 0.4f;
//        } else {
//            self.faceAndMediaTypeView.alpha = 1.0f;
//        }
//    });
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
