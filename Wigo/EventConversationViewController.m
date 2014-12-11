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
#import "MediaScrollView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "EventMessagesConstants.h"


@interface EventConversationViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) UIImage *userProfileImage;
@property (nonatomic, strong) NSIndexPath *currentActiveCell;
@property (nonatomic, assign) CGPoint collectionViewPointNow;
@property (nonatomic, assign) CGPoint imagesScrollViewPointNow;
@property (nonatomic, assign) BOOL facesHidden;
@property (nonatomic, strong) UIButton * buttonCancel;
@property (nonatomic, strong) UIButton *buttonTrash;
@property (nonatomic, strong) UIImageView *gradientBackgroundImageView;
@end

@implementation EventConversationViewController


#pragma mark - ViewController Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.event.name;
    
    [self loadScrollView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationHighlightPage:)
                                                 name:@"notificationHighlightPage"
                                               object:nil];
}

- (void)notificationHighlightPage:(NSNotification *) notification {
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *pageNumber = (NSNumber *)[userInfo objectForKey:@"page"];
    [self highlightCellAtPage:[pageNumber integerValue]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    if (self.eventMessages.count > 0) {
        self.currentActiveCell = [NSIndexPath indexPathForItem:[self.index intValue] inSection:0];
    } else {
        self.currentActiveCell = nil;
    }
    
    [self highlightCellAtPage:[self.index intValue]];
    [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:YES];
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
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FaceCell" forIndexPath: indexPath];

    [myCell resetToInactive];

    myCell.leftLineEnabled = (indexPath.row > 0);
    myCell.rightLineEnabled = (indexPath.row < self.eventMessages.count - 1);
    User *user;
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:[indexPath row]];
    user = [[User alloc] initWithDictionary:[eventMessage objectForKey:@"user"]];
    if ([user isEqualToUser:[Profile user]]) {
        user = [Profile user];
    }
    if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kCameraType] ||
        [[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kFaceImage]
        ) {
        myCell.faceImageView.image = [UIImage imageNamed:@"plusStory"];
        myCell.mediaTypeImageView.hidden = YES;
    }
    else {
        if (user) [myCell.faceImageView setCoverImageForUser:user completed:nil];
        if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kImageEventType]) {
            myCell.mediaTypeImageView.image = [UIImage imageNamed:@"imageType"];
            myCell.mediaTypeImageView.hidden = NO;
        }
        else if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kVideoEventType]) {
            myCell.mediaTypeImageView.image = [UIImage imageNamed:@"videoType"];
            myCell.mediaTypeImageView.hidden = NO;
        }
    }
    
    myCell.timeLabel.text = [Time getUTCTimeStringToLocalTimeString:[eventMessage objectForKey:@"created"]];
    if ([indexPath compare:self.currentActiveCell] == NSOrderedSame) {
        myCell.isActive = YES;
    } else {
        myCell.isActive = NO;
    }
    return myCell;
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.facesCollectionView) {
        if (indexPath == self.currentActiveCell) {
            return;
        }
        
        FaceCell *cell = (FaceCell *)[collectionView cellForItemAtIndexPath: indexPath];
        
        if (self.currentActiveCell) {
            [(FaceCell *)[collectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:NO];
        }
        
        [cell setIsActive: YES];
        
        self.currentActiveCell = indexPath;
        
        [self highlightCellAtPage:indexPath.row ];
    }
}

- (void)focusOnContent {
    if (!self.facesHidden) {
        [UIView animateWithDuration:0.5 animations:^{
            self.facesCollectionView.alpha = 0;
            self.facesCollectionView.transform = CGAffineTransformMakeTranslation(0,-self.facesCollectionView.frame.size.height);
            self.buttonTrash.alpha = 0;
            self.buttonTrash.transform = CGAffineTransformMakeTranslation(0, self.buttonTrash.frame.size.height);
            self.buttonCancel.alpha = 0;
            self.buttonCancel.transform = CGAffineTransformMakeTranslation(0, self.buttonCancel.frame.size.height);
            self.gradientBackgroundImageView.alpha = 0;
        } completion:^(BOOL finished) {
            self.facesHidden = YES;
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            self.facesCollectionView.alpha = 1;
            self.facesCollectionView.transform = CGAffineTransformMakeTranslation(0,0);
            self.buttonTrash.alpha = 1;
            self.buttonTrash.transform = CGAffineTransformMakeTranslation(0, 0);
            self.buttonCancel.alpha = 1;
            self.buttonCancel.transform = CGAffineTransformMakeTranslation(0, 0);
            self.gradientBackgroundImageView.alpha = 1;
        } completion:^(BOOL finished) {
            self.facesHidden = NO;
        }];
    }
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
#pragma mark - Media Scroll View Delegate


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
    if (scrollView == self.mediaScrollView)
        _imagesScrollViewPointNow = scrollView.contentOffset;
    else _collectionViewPointNow = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    CGPoint pointNow;
    if (scrollView == self.mediaScrollView) pointNow = _imagesScrollViewPointNow;
    else pointNow = _collectionViewPointNow;
    if (decelerate) {
        if (scrollView.contentOffset.x < pointNow.x) {
            [self stoppedScrollingToLeft:YES forScrollView:scrollView];
        } else if (scrollView.contentOffset.x >= pointNow.x) {
            [self stoppedScrollingToLeft:NO forScrollView:scrollView];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint pointNow;
    if (scrollView == self.mediaScrollView) pointNow = _imagesScrollViewPointNow;
    else pointNow = _collectionViewPointNow;
    if (scrollView.contentOffset.x < pointNow.x) {
        [self stoppedScrollingToLeft:YES forScrollView:scrollView];
    } else if (scrollView.contentOffset.x >= pointNow.x) {
        [self stoppedScrollingToLeft:NO forScrollView:scrollView];
    }
}

- (void)stoppedScrollingToLeft:(BOOL)leftBoolean forScrollView:(UIScrollView *)scrollView
{
    float width;
    if (scrollView == self.mediaScrollView) {
        width = 320;
    }
    else {
        width = 100;
    }
    NSInteger page = [self getPageForScrollView:scrollView toLeft:leftBoolean];
    [self highlightCellAtPage:page];
}

- (NSInteger)getPageForScrollView:(UIScrollView *)scrollView toLeft:(BOOL)leftBoolean {
    float fractionalPage;
    if (scrollView == self.mediaScrollView) {
        CGFloat pageWidth = 320;
        fractionalPage = (self.mediaScrollView.contentOffset.x) / pageWidth;
    }
    else {
        CGFloat pageWidth = 100; // you need to have a **iVar** with getter for scrollView
        fractionalPage = (self.facesCollectionView.contentOffset.x + 100) / pageWidth;
    }
    
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
    return page;
}

- (void)highlightCellAtPage:(NSInteger)page {
    page = MAX(page, 0);
    page = MIN(page, self.eventMessages.count);
    [self.mediaScrollView scrolledToPage:(int)page];
    [self.facesCollectionView setContentOffset:CGPointMake((100) * (page - 1), 0.0f) animated:YES];
    [self.mediaScrollView setContentOffset:CGPointMake(320 * page, 0.0f) animated:YES];
    [self hideOrShowFacesForPage:page];
}

- (void)hideOrShowFacesForPage:(int)page {
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:page];
    if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kCameraType]) {
        self.facesHidden = YES;
        self.buttonCancel.hidden = YES;
        self.buttonCancel.enabled = NO;
        self.buttonTrash.hidden = YES;
        self.buttonTrash.enabled = NO;
        self.gradientBackgroundImageView.hidden = YES;
        [UIView animateWithDuration:0.5 animations:^{
            self.facesCollectionView.alpha = 0;
        }];
    }
    else if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kFaceImage]) {
        self.buttonTrash.hidden = YES;
        self.buttonTrash.enabled = NO;
        self.gradientBackgroundImageView.hidden = YES;
    }
    else {
        self.facesHidden = NO;
        User *user = [[User alloc] initWithDictionary:[eventMessage objectForKey:@"user"]];
        [UIView animateWithDuration:0.5 animations:^{
            self.facesCollectionView.alpha = 1;
        }];
        self.buttonCancel.hidden = NO;
        self.buttonCancel.enabled = YES;
        self.gradientBackgroundImageView.hidden = NO;
        if ([user isEqualToUser:[Profile user]]) {
            self.buttonTrash.hidden = NO;
            self.buttonTrash.enabled = YES;
        }
        else {
            self.buttonTrash.hidden = YES;
            self.buttonTrash.enabled = NO;
        }
        
    }
    NSIndexPath *activeIndexPath = [NSIndexPath indexPathForItem:page  inSection: 0];
    
    if (activeIndexPath != self.currentActiveCell) {
        
        if (self.currentActiveCell) {
            [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:NO];
        }
        
        [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: activeIndexPath] setIsActive: YES];
        
        self.currentActiveCell = activeIndexPath;
    }
}

#pragma mark - G's code

- (void)loadScrollView {
    self.mediaScrollView = [[MediaScrollView alloc]
                            initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                            collectionViewLayout:[[MediaFlowLayout alloc] init]];
    self.mediaScrollView.eventMessages = self.eventMessages;
    self.mediaScrollView.event = self.event;
    self.mediaScrollView.controllerDelegate = self.controllerDelegate;
    self.mediaScrollView.mediaDelegate = self;
    self.mediaScrollView.eventConversationDelegate = self;
    self.mediaScrollView.storyDelegate = self.storyDelegate;
    if (self.index) [self.mediaScrollView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self.index intValue] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];

    self.mediaScrollView.delegate = self;
    [self.view addSubview:self.mediaScrollView];
    [self.view sendSubviewToBack:self.mediaScrollView];
    
    self.gradientBackgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.gradientBackgroundImageView.image = [UIImage imageNamed:@"storyBackground"];
    [self.view addSubview:self.gradientBackgroundImageView];
    
    self.facesCollectionView.backgroundColor = [UIColor clearColor];
    FaceFlowLayout *flow = [[FaceFlowLayout alloc] init];
    self.facesCollectionView.showsHorizontalScrollIndicator = NO;
    [self.facesCollectionView setCollectionViewLayout: flow];
    self.facesCollectionView.contentInset = UIEdgeInsetsMake(0, 100, 0, 100);
    self.facesCollectionView.pagingEnabled = NO;
    
    self.buttonCancel = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 86, 86, 66)];
    UIImageView *cancelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 30, 36, 36)];
    cancelImageView.image = [UIImage imageNamed:@"cancelCamera"];
    [self.buttonCancel addSubview:cancelImageView];
    [self.buttonCancel addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonCancel];
    
    self.buttonTrash = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 18, self.view.frame.size.height - 56, 36, 36)];
    UIImageView *trashImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    trashImageView.image = [UIImage imageNamed:@"trashIcon"];
    [self.buttonTrash addSubview:trashImageView];
    [self.buttonTrash addTarget:self action:@selector(trashPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonTrash.hidden = YES;
    self.buttonTrash.enabled = NO;
    [self.view addSubview:self.buttonTrash];
    
}

- (void)cancelPressed:(id)sender {
    [self.mediaScrollView closeView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Needs to load faster.
- (void)trashPressed:(id)sender {
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    // NEeds to be sequential.
    [self.mediaScrollView removeMediaAtPage:(int)page];
    [self.eventMessages removeObjectAtIndex:page];
    [self.facesCollectionView reloadData];
    self.mediaScrollView.eventMessages = self.eventMessages;
    [self.mediaScrollView reloadData];
    [self hideOrShowFacesForPage:(int)page];
}


#pragma mark -  EventConversation Delegate methods

- (void)addLoadingBanner {
    self.loadingBanner = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    self.loadingBanner.backgroundColor = UIColor.blackColor;
    [self.view addSubview:self.loadingBanner];
    
    self.postingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 60, 20)];
    self.postingLabel.text = @"Posting...";
    self.postingLabel.textColor = UIColor.whiteColor;
    self.postingLabel.font = [FontProperties mediumFont:13.0f];
    [self.view addSubview:self.postingLabel];
    
    [NSTimer scheduledTimerWithTimeInterval:0.2
                                     target:self
                                   selector:@selector(changePostingLabel)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)changePostingLabel {
    if ([self.postingLabel.text isEqualToString:@"Posting"]) {
        self.postingLabel.text = @"Posting.";
    }
    else if ([self.postingLabel.text isEqualToString:@"Posting."]) {
        self.postingLabel.text = @"Posting..";
    }
    else if ([self.postingLabel.text isEqualToString:@"Posting.."]) {
        self.postingLabel.text = @"Posting...";
    }
    else if ([self.postingLabel.text isEqualToString:@"Posting..."]) {
        self.postingLabel.text = @"Posting";
    }
}

- (void)showErrorMessage {
    self.loadingBanner.backgroundColor = RGB(196, 0, 0);
    self.postingLabel.text = @"Wasn't able to post :-(";
    
    [self performBlock:^(void){[self removeBanner];}
            afterDelay:5
 cancelPreviousRequest:YES];
    
}

- (void)showCompletedMessage {
    self.loadingBanner.backgroundColor = RGB(245, 142, 29);
    self.postingLabel.text = @"Posted!";
    [self performBlock:^(void){[self removeBanner];}
            afterDelay:5
 cancelPreviousRequest:YES];
}

- (void)removeBanner {
    [UIView animateWithDuration:15 animations:^{} completion:^(BOOL finished) {
        self.loadingBanner.hidden = YES;
        self.postingLabel.hidden = YES;
    }];
}

- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EventConversationDelegate

- (void)reloadUIForEventMessages:(NSMutableArray *)eventMessages {
    NSMutableArray *mutableEventMessages =  [NSMutableArray arrayWithArray:eventMessages];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    [mutableEventMessages addObject:@{
                                      @"user": [[Profile user] dictionary],
                                      @"created": [dateFormatter stringFromDate:[NSDate date]],
                                      @"media_mime_type": kCameraType,
                                      @"media": @""
                                      }];
    self.eventMessages = mutableEventMessages;
    [self.facesCollectionView reloadData];
    self.mediaScrollView.eventMessages = self.eventMessages;
    [self.mediaScrollView reloadData];
    
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    [self hideOrShowFacesForPage:(int)page];
}


@end

#pragma mark - Face Classes

@implementation FaceCell

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
    self.frame = CGRectMake(0, 0, 100,100);
    
    self.backgroundColor = UIColor.clearColor;
    
    self.rightLine = [[UIView alloc] initWithFrame: CGRectMake(self.center.x + 25, self.center.y, self.center.x - 25, 2)];
    self.rightLine.alpha = 0.5f;
    self.rightLine.backgroundColor = [UIColor whiteColor];
    [self addSubview: self.rightLine];
    
    self.leftLine = [[UIView alloc] initWithFrame: CGRectMake(0, self.center.y, self.center.x - 25, 2)];
    self.leftLine.alpha = 0.5f;
    self.leftLine.backgroundColor = [UIColor whiteColor];
    [self addSubview: self.leftLine];
    
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(25, 25, 50, 50)];
    self.faceImageView.layer.masksToBounds = YES;
    self.faceImageView.backgroundColor = [UIColor blackColor];
    self.faceImageView.layer.cornerRadius = 25;
    self.faceImageView.layer.borderWidth = 1.0;
    self.faceImageView.alpha = 0.5f;
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview: self.faceImageView];
    
    self.spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.frame = CGRectMake(self.faceImageView.frame.size.width/4, self.faceImageView.frame.size.height/4, self.faceImageView.frame.size.width/2,  self.faceImageView.frame.size.height/2);
    self.spinner.hidesWhenStopped = YES;
    self.spinner.hidden = YES;
    [self.faceImageView addSubview:self.spinner];
    
    self.mediaTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(62, 20, 15, 15)];
    self.mediaTypeImageView.layer.masksToBounds = YES;
    self.mediaTypeImageView.backgroundColor = [UIColor blackColor];
    self.mediaTypeImageView.layer.cornerRadius = 7;
    self.mediaTypeImageView.layer.borderWidth = 1.0;
    self.mediaTypeImageView.layer.borderColor = UIColor.blackColor.CGColor;
    self.mediaTypeImageView.alpha = 0.5f;
    self.mediaTypeImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:self.mediaTypeImageView];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(23, 82, 60, 20)];
    self.timeLabel.numberOfLines = 0;
    self.timeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.font = [FontProperties lightFont:12];
    [self addSubview:self.timeLabel];
    

    _isActive = NO;
}



- (void)setRightLineEnabled:(BOOL)rightLineEnabled {
    self.rightLine.hidden = !rightLineEnabled;
}

- (void)setLeftLineEnabled:(BOOL)leftLineEnabled {
    self.leftLine.hidden = !leftLineEnabled;
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
                self.faceImageView.frame = CGRectMake(20, 20, 60, 60);
                self.faceImageView.alpha = 1.0f;
                self.faceImageView.layer.cornerRadius = 30;
                
                self.mediaTypeImageView.frame = CGRectMake(65, 15, 20, 20);
                self.mediaTypeImageView.alpha = 1.0f;
                self.mediaTypeImageView.layer.cornerRadius = 10;
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

- (void)setToActiveWithNoAnimation {
    self.faceImageView.frame = CGRectMake(20, 20, 60, 60);
    self.faceImageView.alpha = 1.0f;
    self.faceImageView.layer.cornerRadius = 30;
    
    self.mediaTypeImageView.frame = CGRectMake(65, 15, 20, 20);
    self.mediaTypeImageView.alpha = 1.0f;
    self.mediaTypeImageView.layer.cornerRadius = 10;
}

- (void) resetToInactive {
    self.faceImageView.frame = CGRectMake(25, 25, 50, 50);
    self.faceImageView.alpha = 0.5f;
    self.faceImageView.layer.cornerRadius = 25;
    
    self.mediaTypeImageView.frame = CGRectMake(62, 20, 15, 15);
    self.mediaTypeImageView.alpha = 0.5f;
    self.mediaTypeImageView.layer.cornerRadius = 7;
}

- (void)updateUIToRead:(BOOL)read {
    if (read) {
        self.faceImageView.alpha = 0.4f;
        self.mediaTypeImageView.alpha = 0.4f;
    }
    else {
        self.faceImageView.alpha = 1.0f;
        self.mediaTypeImageView.alpha = 1.0f;
    }
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


@end

