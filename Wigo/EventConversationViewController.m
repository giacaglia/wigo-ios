//
//  EventConversationViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventConversationViewController.h"
#import "FontProperties.h"
#import "EventMessage.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Profile.h"

@interface EventConversationViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) UIImage *userProfileImage;
@property (nonatomic, strong) NSIndexPath *currentActiveCell;
@property (nonatomic, assign) CGPoint pointNow;
@end

@implementation EventConversationViewController



#pragma mark - ViewController Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.event.name;
    //self.facesCollectionView.backgroundColor = [UIColor clearColor];
    FaceFlowLayout *flow = [[FaceFlowLayout alloc] init];
    [self.facesCollectionView setCollectionViewLayout: flow];
    self.facesCollectionView.contentInset = UIEdgeInsetsMake(0, 100, 0, 100);
    self.facesCollectionView.pagingEnabled = NO;
}

- (void)loadMessages {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    self.currentActiveCell = [NSIndexPath indexPathForItem:self.eventMessages.count - 1 inSection:0];

    
    [self.facesCollectionView scrollToItemAtIndexPath: self.currentActiveCell atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
    
    [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive: YES];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FaceCell"forIndexPath: indexPath];

    [myCell resetToInactive];

    myCell.rightLineEnabled = (indexPath.row < self.eventMessages.count - 1);
    myCell.faceImageView.image = [UIImage imageNamed: @"jobs.jpg"];
    if (indexPath == self.currentActiveCell) {
        myCell.isActive = YES;
    } else {
        myCell.isActive = NO;
    }
    return myCell;
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath == self.currentActiveCell) {
        return;
    }
    
    FaceCell *cell = (FaceCell *)[collectionView cellForItemAtIndexPath: indexPath];
    
    if (self.currentActiveCell) {
        [(FaceCell *)[collectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:NO];
    }
    
    [cell setIsActive: YES];
    
    self.currentActiveCell = indexPath;
    
    [self highlightCellAtPage:(indexPath.row - 2)];
}

#define kActionPhotoVideo 0
#define kActionLibrary 1
#define kActionCancel 2

- (IBAction)tapPhotoVideoButton: (id) sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: @"Add some fun media" delegate: self cancelButtonTitle: @"Cancel" destructiveButtonTitle: nil otherButtonTitles: @"Take a Photo or Video", @"Photo Library", nil];
    
    [actionSheet showInView: self.view];
}

    
#pragma mark - ActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == kActionCancel) {
        return;
    }
    
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    if (buttonIndex == kActionPhotoVideo) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: picker.sourceType];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Image Picker {
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    //video
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        [self generateThumbnailAndSendVideo: videoUrl];
    }
    //image
    else if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {

        UIImage *image = [info objectForKey: UIImagePickerControllerEditedImage];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        [self sendImage: imageData];
    }
    
    [picker dismissViewControllerAnimated: YES completion:nil];
}

- (void) sendImage: (NSData *) data{

}

- (void) sendVideo: (NSData *) data withThumbnail: (UIImage *) thumb {

}
#pragma mark - Helpers

-(void)generateThumbnailAndSendVideo: (NSURL *) videoUrl
{
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL: videoUrl options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        UIImage *thumb =[UIImage imageWithCGImage:im];
        NSData *videoData = [NSData dataWithContentsOfURL: videoUrl];
        [self sendVideo: videoData withThumbnail: thumb];

    };
    
    CGSize maxSize = CGSizeMake(320, 180);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
}


#pragma mark - ScrollViewDelegate



-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _pointNow = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        if (scrollView.contentOffset.x < _pointNow.x) {
            [self stoppedScrollingToLeft:YES];
        } else if (scrollView.contentOffset.x >= _pointNow.x) {
            [self stoppedScrollingToLeft:NO];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView.contentOffset.x < _pointNow.x) {
        [self stoppedScrollingToLeft:YES];
    } else if (scrollView.contentOffset.x >= _pointNow.x) {
        [self stoppedScrollingToLeft:NO];
    }
}

- (void)stoppedScrollingToLeft:(BOOL)leftBoolean
{
    CGFloat pageWidth = 100; // you need to have a **iVar** with getter for scrollView
    float fractionalPage = (self.facesCollectionView.contentOffset.x - 100) / pageWidth;
    NSInteger page;
    if (leftBoolean) {
        if (fractionalPage - floor(fractionalPage) < 0.8) {
            page = floor(fractionalPage);
        }
        else {
            page = ceil(fractionalPage);
        }
    }
    else {
        if (fractionalPage - floor(fractionalPage) < 0.2) {
            page = floor(fractionalPage);
        }
        else {
            page = ceil(fractionalPage);
        }
    }
    [self highlightCellAtPage:page];
}

- (void)highlightCellAtPage:(NSInteger)page {
    page = MAX(page, -2);
    [self.facesCollectionView setContentOffset:CGPointMake((100) * page + 100, 0.0f) animated:YES];
    
    
    
    NSIndexPath *activeIndexPath = [NSIndexPath indexPathForItem: MIN(page+2, self.eventMessages.count - 1) inSection: 0];
    
    if (activeIndexPath != self.currentActiveCell) {
        
        if (self.currentActiveCell) {
            [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:NO];
        }
        
        [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: activeIndexPath] setIsActive: YES];
        
        self.currentActiveCell = activeIndexPath;
    }
}
@end

#pragma mark - Face Classes

@implementation FaceCell

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        self.frame = CGRectMake(0, 0, 100,100);

        self.backgroundColor = UIColor.clearColor;
    
        self.rightLine = [[UIView alloc] initWithFrame: CGRectMake(self.center.x, self.center.y, self.frame.size.width, 2)];
        self.rightLine.alpha = 0.5f;
        self.rightLine.backgroundColor = [UIColor whiteColor];
        [self addSubview: self.rightLine];
        
        self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 25, 50, 50)];
        self.faceImageView.layer.masksToBounds = YES;
        self.faceImageView.backgroundColor = [UIColor blackColor];
        self.faceImageView.layer.cornerRadius = 25;
        self.faceImageView.layer.borderWidth = 2.0;
        self.faceImageView.alpha = 0.5f;
        self.faceImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview: self.faceImageView];
        
        _isActive = NO;
    }
        
    return self;
}


- (void)setRightLineEnabled:(BOOL)rightLineEnabled {
    self.rightLine.hidden = !rightLineEnabled;
}

- (void) setIsActive:(BOOL)isActive {
    if (_isActive == isActive) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isActive) {
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.fromValue = [NSNumber numberWithFloat:25.0f];
            animation.toValue = [NSNumber numberWithFloat:30.0f];
            animation.duration = 0.5;
            [self.faceImageView.layer addAnimation: animation forKey:@"cornerRadius"];
            
            [UIView animateWithDuration: 0.5 delay: 0.0 options: UIViewAnimationOptionCurveLinear animations:^{
                self.faceImageView.frame = CGRectMake(0, 20, 60, 60);
                self.faceImageView.alpha = 1.0f;
                self.faceImageView.layer.cornerRadius = 30;
            } completion:^(BOOL finished) {

            }];
        } else {
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.fromValue = [NSNumber numberWithFloat:30.0f];
            animation.toValue = [NSNumber numberWithFloat:25.0f];
            animation.duration = 0.5;
            [self.faceImageView.layer addAnimation: animation forKey:@"cornerRadius"];
            
            
            [UIView animateWithDuration: 0.5 animations:^{
                [self resetToInactive];
            }];
        }
    });
    
    _isActive = isActive;

}

- (void) resetToInactive {
    self.faceImageView.frame = CGRectMake(0, 25, 50, 50);
    self.faceImageView.alpha = 0.5f;
    self.faceImageView.layer.cornerRadius = 25;
}

@end

@implementation FaceFlowLayout

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
    self.itemSize = CGSizeMake(100, 100);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(10, 10, 10,10);
    self.minimumInteritemSpacing = 0.0;
    self.minimumLineSpacing = 0.0;
}

//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
//{
//    CGFloat offsetAdjustment = MAXFLOAT;
//    CGFloat horizontalOffset = proposedContentOffset.x + 5;
//    
//    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
//    
//    NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
//    
//    for (UICollectionViewLayoutAttributes *layoutAttributes in array) {
//        CGFloat itemOffset = layoutAttributes.frame.origin.x;
//        if (ABS(itemOffset - horizontalOffset) < ABS(offsetAdjustment)) {
//            offsetAdjustment = itemOffset - horizontalOffset;
//        }
//    }
//    
//    return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
//}

@end

