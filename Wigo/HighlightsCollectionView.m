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
    self.backgroundColor = UIColor.whiteColor;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    self.pagingEnabled = NO;
    [self registerClass:[HighlightCell class] forCellWithReuseIdentifier:highlightCellName];
    [self registerClass:[AddPhotoCell class] forCellWithReuseIdentifier:kAddPhotoCellName];
    
    self.dataSource = self;
    self.delegate = self;
    
    CGRect frame = self.bounds;
    frame.origin.y = -frame.size.height;
    UIView* whiteView = [[UIView alloc] initWithFrame:frame];
    whiteView.backgroundColor = UIColor.whiteColor;
    [self addSubview:whiteView];
    
    self.scrollEnabled = YES;
    self.showAddPhoto = YES;
}

- (void)setEvent:(WGEvent *)event {
    _event = event;
    [self fetchEventMessages];
}

#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1 +  self.eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        AddPhotoCell *cell  =[collectionView dequeueReusableCellWithReuseIdentifier:kAddPhotoCellName forIndexPath: indexPath];
        cell.contentView.frame = CGRectMake(0, 0, [HighlightCell height], [HighlightCell height]);
        return cell;
    }
    HighlightCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:highlightCellName forIndexPath: indexPath];
    indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];

    if (indexPath.row + 1 == self.eventMessages.count &&
        [self.eventMessages.hasNextPage boolValue]) {
        [self fetchEventMessages];
    }
    myCell.faceImageView.center = CGPointMake(myCell.contentView.center.x, myCell.faceImageView.center.y);
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
    self.backgroundColor = UIColor.whiteColor;
    self.frame = CGRectMake(0, 0, [HighlightCell height], [HighlightCell height]);
    self.contentView.frame = self.frame;
    
    self.controller = [[UIImagePickerController alloc] init];
    self.controller.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
    self.controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    self.controller.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    self.controller.showsCameraControls = NO;
    self.controller.delegate = self;

    CGFloat controllerHeight = [HighlightCell height];
    CGFloat controllerWidth = [HighlightCell height];
    CGFloat cameraWidth = controllerWidth;
    CGFloat cameraHeight = floor((4/3.0f) * cameraWidth);
    CGFloat scaleHeight = controllerHeight / cameraHeight;
    CGFloat scaleWidth = controllerWidth / cameraWidth;
    scaleHeight = scaleHeight/6;
    scaleWidth = scaleWidth/3;
    CGFloat delta = controllerHeight - cameraHeight;
    CGFloat yAdjust = delta / 2.0;
    NSLog(@"scale: %f", scaleHeight);
    NSLog(@"y Adjust: %f", yAdjust);
    yAdjust = -245.0f;
    CGFloat xAdjust = -140.0f;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(xAdjust, yAdjust); //This slots the preview exactly in the middle of the screen
    self.controller.cameraViewTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, scaleWidth/scaleHeight);
//    self.controller.cameraViewTransform = CGAffineTransformScale(translate, scale, scale);
    self.controller.view.transform = CGAffineTransformScale(translate, scaleWidth, scaleHeight);
    [self.contentView addSubview:self.controller.view];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

@end

@implementation HighlightCell

+ (CGFloat)height {
    return 80;
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
