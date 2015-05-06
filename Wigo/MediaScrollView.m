//
//  ImagesScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <ImageIO/ImageIO.h>

#import "MediaScrollView.h"
#import "Globals.h"
#import "EventMessagesConstants.h"
#import "WGEventMessage.h"
#import "WGCollection.h"

#import "WGCameraViewController.h"
#import "UIImage+Rotation.h"

#import <AVFoundation/AVFoundation.h>
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define kMediaMimeTypeKey @"media_mime_type"
#define kThumbnailDataKey @"thumbnailData"
#define kThumbnailImageKey @"thumbnailImage"

#define kVideoMetaDataCurrentThumbImage     @"current_thumb_image"
#define kVideoMetaDataCurrentTime           @"current_time"

@interface MediaScrollView() {}
@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, strong) WGCollection *eventMessagesRead;
@property (nonatomic, strong) NSMutableDictionary *thumbnails;
@property (nonatomic, strong) UIView *chatTextFieldWrapper;
@property (nonatomic, strong) UILabel *addYourVerseLabel;
@property (nonatomic, assign) BOOL shownCurrentImage;

@property (nonatomic, strong) NSMutableSet *moviePlayerPool;

@property (nonatomic, strong) WGCameraViewController *internalCameraController;

@end

@implementation MediaScrollView

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.backgroundColor = RGB(23, 23, 23);
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.dataSource = self;
    self.filenameString = @"0.jpg";
    self.tasksStillBeingUploaded = [NSMutableSet new];
    [self registerClass:[VideoCell class] forCellWithReuseIdentifier:@"VideoCell"];
    [self registerClass:[ImageCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [self registerClass:[PromptCell class] forCellWithReuseIdentifier:@"PromptCell"];
    [self registerClass:[CameraCell class] forCellWithReuseIdentifier:@"CameraCell"];
    
    
//    MPMoviePlayerController *playerA = [self videoCellMoviePlayer];
//    MPMoviePlayerController *playerB = [self videoCellMoviePlayer];
//    self.moviePlayerPool = [NSMutableSet setWithObjects:playerA, playerB, nil];
    
    self.sharedMoviePlayer = [self videoCellMoviePlayer];
    
    self.videoPlayerIsSavingThumbnail = NO;
    self.videoIsWaitingToPrepare = NO;
    
    self.videoMetaDataInternal = [NSMutableDictionary dictionary];
    
    
    
    self.internalCameraController = [[WGCameraViewController alloc] init];
    
    self.currentVideoIndex = -1;
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (MPMoviePlayerController *)videoCellMoviePlayer {
    
    MPMoviePlayerController *ret = [[MPMoviePlayerController alloc] init];
    ret.movieSourceType = MPMovieSourceTypeStreaming;
    
    ret.scalingMode = MPMovieScalingModeAspectFill;
    [ret setControlStyle: MPMovieControlStyleNone];
    ret.repeatMode = MPMovieRepeatModeOne;
    ret.shouldAutoplay = YES;
    
    return ret;
}


#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
    }
    while ([self.pageViews count] - 1 < indexPath.row) {
        [self.pageViews addObject:[NSNull null]];
    }
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:indexPath.row];
    NSString *mimeType = eventMessage.mediaMimeType;
    NSString *contentURL = eventMessage.media;
    self.eventConversationDelegate.buttonCancel.hidden = NO;

    if ([mimeType isEqualToString:kCameraType]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusDenied) {
            PromptCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PromptCell" forIndexPath: indexPath];
            [myCell.imageView setCoverImageForUser:WGProfile.currentUser completed:nil];
             myCell.titleTextLabel.frame = CGRectMake(15, 160, self.frame.size.width - 30, 60);
            myCell.titleTextLabel.text = @"Please Give WiGo an access to camera to add to the story:";
            myCell.avoidAction.hidden = YES;
            myCell.cameraAccessView.hidden = NO;
            myCell.isPeeking = self.isPeeking;
            return myCell;
        } else {
            CameraCell *cameraCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CameraCell" forIndexPath: indexPath];
            cameraCell.mediaScrollDelegate = self;
            [cameraCell setupCameraController:self.internalCameraController];
            if ([cameraCell.info.allKeys containsObject:UIImagePickerControllerMediaType]) {
                NSString *typeString = [cameraCell.info objectForKey:UIImagePickerControllerMediaType];
                if ([typeString isEqual:@"public.movie"]) {
                    
                    // this is a no-op unless the user has a preview video, ready to upload or cancel
                    [cameraCell.previewMoviePlayer play];
                }
            }
            [self.pageViews setObject:cameraCell atIndexedSubscript:indexPath.row];
            return cameraCell;
        }
    }
    else if ([mimeType isEqualToString:kImageEventType]) {
        ImageCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath: indexPath];
        myCell.mediaScrollDelegate = self;
        myCell.eventMessage = eventMessage;
        myCell.isPeeking = self.isPeeking;
        [myCell updateUI];
        if ([contentURL isKindOfClass:[UIImage class]]) {
            myCell.imageView.image = (UIImage *)contentURL;
        } else {
            NSString *thumbnailURL = [eventMessage objectForKey:@"thumbnail"];
            __weak ImageCell *weakCell = myCell;
            if (![thumbnailURL isKindOfClass:[NSNull class]]) {
                NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, thumbnailURL]];
                [myCell.imageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                         NSURL *realURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, contentURL]];
                        NSLog(@"image URL: %@", realURL.absoluteString);
                        [weakCell.spinner startAnimating];
                        [weakCell.imageView setImageWithURL:realURL
                                           placeholderImage:image
                                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                                      NSLog(@"image size: %@", NSStringFromCGSize(image.size));
                                                    [weakCell.spinner stopAnimating];
                                                }];
                    });
                }];
            }
        }
        
        [self.pageViews setObject:myCell.imageView atIndexedSubscript:indexPath.row];

        return myCell;
    }
    else if ([mimeType isEqualToString:kFaceImage]) {
        PromptCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PromptCell" forIndexPath: indexPath];
        [myCell.imageView setCoverImageForUser:WGProfile.currentUser completed:nil];
        myCell.titleTextLabel.text = [NSString stringWithFormat:@"Sweet! You're going out to: %@", [self.event name]];
        myCell.subtitleTextLabel.text = @"Post a selfie to build the buzz!";
        myCell.subtitleTextLabel.alpha = 0.7f;
        myCell.actionButton.backgroundColor = [FontProperties getOrangeColor];
        [myCell.actionButton setTitle:@"POST" forState:UIControlStateNormal];
        [myCell.actionButton.titleLabel setFont: [FontProperties scMediumFont: 16.0]];
        [myCell.actionButton addTarget:self action:@selector(promptCamera) forControlEvents:UIControlEventTouchUpInside];
        [myCell.avoidAction addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
        myCell.isPeeking = self.isPeeking;
        self.eventConversationDelegate.buttonCancel.hidden = YES;
        return myCell;
    }
    else if ([mimeType isEqualToString:kNotAbleToPost]) {
        PromptCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PromptCell" forIndexPath: indexPath];
        [myCell.imageView setImageWithURL:[WGProfile currentUser].coverImageURL];
        myCell.titleTextLabel.text = @"To add content you\nmust be going here.";
        myCell.avoidAction.hidden = YES;
        myCell.isPeeking = self.isPeeking;

        return myCell;
    } else {
        VideoCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath: indexPath];
        myCell.mediaScrollDelegate = self;
        myCell.eventMessage = eventMessage;
        myCell.isPeeking = self.isPeeking;
        
        // load video metadata if any
        //NSDictionary *metaData = self.videoMetaData[eventMessage.id];
        
        
        
        [myCell updateUI];
        
//        if(metaData) {
//            myCell.videoStartTime = self.videoMetaData[kVideoMetaDataCurrentTime];
//            myCell.startingThumbnail = self.videoMetaData[kVideoMetaDataCurrentThumbImage];
//            [myCell.thumbnailImageView setImage:myCell.startingThumbnail];
//        }
//        else {
            myCell.videoStartTime = nil;
            NSString *thumbnailURL = [eventMessage objectForKey:@"thumbnail"];
            if (![thumbnailURL isKindOfClass:[NSNull class]]) {
                NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, thumbnailURL]];
                [myCell.thumbnailImageView setImageWithURL:imageURL];
                //[myCell.thumbnailImageView2 setImageWithURL:imageURL];
            }
//        }
        
        
        
        NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, contentURL]];
        myCell.videoURL = videoURL;
        
        NSLog(@"video URL: %@", videoURL.absoluteString);
        
//        if (self.firstCell) {
//            [myCell.moviePlayer play];
//            self.lastMoviePlayer = myCell.moviePlayer;
//            self.firstCell = NO;
//        }
        [self.pageViews setObject:myCell atIndexedSubscript:indexPath.row];
        
        return myCell;
    }
}

- (void)updateEventMessage:(WGEventMessage *)eventMessage forCell:(UICollectionViewCell *)cell {
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    [self.eventMessages replaceObjectAtIndex:[indexPath row] withObject:eventMessage];
}

- (void)closeViewWithHandler:(BoolResultBlock)handler {
    if (self.lastMoviePlayer) {
        [self.lastMoviePlayer stop];
    }
    for (int i = self.minPage; i <= self.maxPage; i++) {
        [self addReadPage:i];
    }
    if (self.eventMessagesRead.count > 0) {
        __weak typeof(handler) weakHandler = handler;
        [self.event setMessagesRead:self.eventMessagesRead andHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                weakHandler(NO, error);
                return;
            }
            weakHandler(YES, error);
        }];
    }
}

- (void)dismissView {
    [self.eventConversationDelegate dismissView];
}

- (void)promptCamera {
    [self.eventConversationDelegate promptCamera];
}


- (void)startedScrollingFromPage:(int)fromPage {
    
    if ((int)fromPage < [self.pageViews count]) {
        
        id currentCell = [self.pageViews objectAtIndex:fromPage];
        if([currentCell isKindOfClass:[VideoCell class]]) {
            [(VideoCell*)currentCell pauseVideo];
        }
    }
}

-(void)scrolledToPage:(int)page {
    
    NSString *isPeekingString = (self.isPeeking) ? @"Yes" : @"No";
    [WGAnalytics tagEvent:@"Event Conversation Scrolled Highlight" withDetails: @{@"isPeeking": isPeekingString}];
    
    if (page < self.minPage) self.minPage = page;
    if (page > self.maxPage && page < self.eventMessages.count) self.maxPage = page;
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
        for (int i = 0 ; i < self.eventMessages.count; i++) {
            [self.pageViews addObject:[NSNull null]];
        }
    }
}

- (void)scrollStoppedAtPage:(int)page {
    NSLog(@"stopped at page %d", page);
    
    [self prepareVideoAtPage:page];
    [self playVideoAtPage:page];
}

- (void)playVideoAtPage:(int)page {
    
    if ((int)page < [self.pageViews count]) {
        id currentCell = [self.pageViews objectAtIndex:page];
        if([currentCell isKindOfClass:[VideoCell class]]) {
            [(VideoCell*)currentCell startVideo];
        }
    }
}

- (void)prepareVideoAtPage:(int)page {
    
    if ((int)page < [self.pageViews count]) {
        
        id currentCell = [self.pageViews objectAtIndex:page];
        if([currentCell isKindOfClass:[VideoCell class]]) {
            
            
            NSLog(@"switching video cells to page %d", page);
            //[self.currentVideoCell unloadVideo];
            
            if(self.currentVideoIndex == page) {

                [self.currentVideoCell resumeVideo];
            }
            else {
                
                self.currentVideoIndex = page;
                self.lastVideoCell = self.currentVideoCell;
                self.currentVideoCell = (VideoCell *)currentCell;
                if(self.lastVideoCell != self.currentVideoCell) {
                    self.lastVideoCell.moviePlayer = nil;
                }
                
                
                // if the previous video cell is preparing a thumbnail,
                // wait until it finishes ( when markVideoPlayerIsSavingThumbnail: is called)
                // to start preparing.
                // Otherwise, start now
                
                if(!self.videoPlayerIsSavingThumbnail) {
                    NSLog(@"preparing cell %d to play video", page);
                    [self.lastVideoCell.moviePlayer stop];
                    [self.currentVideoCell prepareVideo];
                    self.videoIsWaitingToPrepare = NO;
                }
                else {
                    self.videoIsWaitingToPrepare = YES;
                    NSLog(@"waiting to prepare cell %d to play video - thumbnail loading", page);
                }
            }
        }
        
        // previous cell was a video cell but current is not:
        // - stop video on previous cell
        else if(self.currentVideoCell) {
            
            
            
            self.lastVideoCell = self.currentVideoCell;
            self.currentVideoCell = nil;
            self.lastVideoCell.moviePlayer = nil;
            
            self.currentVideoIndex = -1;
            
            // if the previous video cell is preparing a thumbnail,
            // wait until it finishes ( when markVideoPlayerIsSavingThumbnail: is called)
            // to start preparing.
            // Otherwise, start now
            
            if(!self.videoPlayerIsSavingThumbnail) {
                NSLog(@"stopping video for previous cell - now showing photo at %d", page);
                [self.lastVideoCell.moviePlayer stop];
                //self.lastVideoCell.moviePlayer.shouldAutoplay = NO;
                
                self.videoIsWaitingToPrepare = NO;
            }
            else {
                NSLog(@"waiting to stop video for previous cell - now showing photo at %d", page);
                self.videoIsWaitingToPrepare = YES;
            }
        }
    }
}

// response to a video cell starting or finishing saving a thumbnail
//
// if it is finishing, and the current video is waiting to start preparing,
// start preparing the current videw

- (void)markVideoPlayerIsSavingThumbnail:(BOOL)videoPlayerIsSavingThumbnail {
    self.videoPlayerIsSavingThumbnail = videoPlayerIsSavingThumbnail;
    
    NSLog(@"video player is saving thumbnail set to %d", videoPlayerIsSavingThumbnail);
    
    if(!self.videoPlayerIsSavingThumbnail) {
        if(self.videoIsWaitingToPrepare) {
            
            NSLog(@"cell was waiting to prepare - now stopping and preparing");
            self.videoIsWaitingToPrepare = NO;
            
            [self.lastVideoCell.moviePlayer stop];
            //self.lastVideoCell.moviePlayer.shouldAutoplay = NO;
            
            //[self.currentVideoCell prepareVideo];
        }
    }
}

- (void)addReadPage:(int)page {
    if (!self.eventMessagesRead) {
        self.eventMessagesRead = [[WGCollection alloc] initWithType:[WGEventMessage class]];
    }
    if (page < self.eventMessages.count) {
        WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:page];
        if (![eventMessage.isRead boolValue]) {
            eventMessage.isRead = @YES;
            [self.eventMessagesRead addObject:eventMessage];
        }
    }
}

#pragma mark - MediaScrollViewDelegate 

- (void)focusOnContent {
    [self.eventConversationDelegate focusOnContent];
}

- (void)upvotePressed {
    [self.eventConversationDelegate upvotePressed];
}

//- (MPMoviePlayerController *)sharedMoviePlayerController {
//    return self.moviePlayer;
//}

- (MPMoviePlayerController *)getAvailableMoviePlayer {
    return self.sharedMoviePlayer;
    
//    return [self videoCellMoviePlayer];
//    
//    MPMoviePlayerController *ret = [self.moviePlayerPool anyObject];
//    if (!ret) {
//        ret = [self videoCellMoviePlayer];
//    }
//    else {
//        [self.moviePlayerPool removeObject:ret];
//    }
//    return ret;
}

- (WGCameraViewController *)cameraController {
    return self.internalCameraController;
}

- (void)freeMoviePlayer:(MPMoviePlayerController *)moviePlayer {
    [self.moviePlayerPool addObject:moviePlayer];
}

- (NSMutableDictionary *)videoMetaData {
    return self.videoMetaDataInternal;
}

#pragma mark - IQMediaPickerController Delegate methods

- (void)cancelPressed {
    self.filenameString = [self.filenameString substringWithRange:NSMakeRange(0, self.filenameString.length - 4)];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [f numberFromString:self.filenameString];
    myNumber = [NSNumber numberWithInt:((int)[myNumber intValue] + 1)];
    self.filenameString = [NSString stringWithFormat:@"%@.jpg", [myNumber stringValue]];
}

- (void)mediaPickerController:(UIImagePickerController *)controller
       startUploadingWithInfo:(NSDictionary *)info {
    self.filenameString = [self.filenameString substringWithRange:NSMakeRange(0, self.filenameString.length - 4)];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [f numberFromString:self.filenameString];
    myNumber = [NSNumber numberWithInt:((int)[myNumber intValue] + 1)];
    NSString *type = @"";
    NSData *fileData;
    if ([[info allKeys] containsObject:UIImagePickerControllerOriginalImage]) {
        self.filenameString = [NSString stringWithFormat:@"%@.jpg", [myNumber stringValue]];
        if (self.cameraPromptAddToStory) {
            [WGAnalytics tagEvent: @"Go Here, Then Add to Story, Then Picture Captured"];
            self.cameraPromptAddToStory = false;
        } else {
            [WGAnalytics tagEvent: @"Event Conversation Captured Picture"];
        }
        
        
        UIImage *image;
        
        if ([[info allKeys] containsObject:UIImagePickerControllerOriginalImage]) {
            image = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
            fileData = [self getImageDataFromImage:image andController:controller isTemplate:NO];
            type = kImageEventType;
        }
        self.options = @{
                         @"event": self.event.id,
                         kMediaMimeTypeKey: type
                         };

    }
    else {
        self.filenameString = [NSString stringWithFormat:@"%@.mp4", myNumber.stringValue];
        NSURL *fileURL = [info objectForKey:UIImagePickerControllerMediaURL];
        fileData = [NSData dataWithContentsOfURL:fileURL];
        
        type = kVideoEventType;
        UIImage *thumbnailImage = info[kThumbnailImageKey];
        NSData *thumbnailFileData = [self getImageDataFromImage:thumbnailImage andController:controller isTemplate:YES];
        NSString *thumbnailFilename = [NSString stringWithFormat:@"thumbnail%@.jpg", myNumber.stringValue];
        self.options = @{
                         @"event": self.event.id,
                         kMediaMimeTypeKey: type,
                         kThumbnailDataKey: thumbnailFileData,
                         @"thumbnail": thumbnailFilename//,
                         //@"fileURL":info[UIImagePickerControllerMediaURL]
                         };
    }
    
    
   [self uploadContentWithFile:fileData
                andFileName:self.filenameString
                 andOptions:self.options];
  
    
    
    //    else if ( [[info allKeys] containsObject:UIImagePickerControllerO]) {
    //        type = kVideoEventType;
    //        NSURL *videoURL = [[[info objectForKey:IQMediaTypeVideo] objectAtIndex:0] objectForKey:IQMediaURL];
    //        self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(thumbnailGenerated:)
    //                                                     name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
    //                                                   object:self.moviePlayer];
    //        /* [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(didFinishPlaying:)
    //                                                     name:MPMoviePlayerLoadStateDidChangeNotification
    //                                                   object:self.moviePlayer]; */
    //
    //        [self.moviePlayer requestThumbnailImagesAtTimes:@[@0.0f] timeOption:MPMovieTimeOptionNearestKeyFrame];
    //
    //        NSError *error;
    //        self.fileData = [NSData dataWithContentsOfURL: videoURL options: NSDataReadingMappedIfSafe error: &error];
    //
    //    else if ( [[info allKeys] containsObject:IQMediaTypeVideo]) {
    //        [mutableDict addEntriesFromDictionary:@{
    //                                                @"user": WGProfile.currentUser,
    //                                                @"created": [NSDate nowStringUTC],
    //                                                @"media": [[[info objectForKey:IQMediaTypeVideo] objectAtIndex:0] objectForKey:IQMediaURL],
    //                                                }];
    //        NSLog(@"media info: %@", mutableDict);
    //    }
    
}

- (NSData *)getImageDataFromImage:(UIImage *)image
                    andController:(UIImagePickerController *)controller
                       isTemplate:(BOOL)isTemplate{
    
    return UIImageJPEGRepresentation(image, WGProfile.currentUser.imageQuality);
//    CGFloat imageWidth = image.size.height * 1.0; // because the image is rotated
//    CGFloat imageHeight = image.size.width * 1.0; // because the image is rotated
//    
//    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
//    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
//    
//    CGFloat ratio = imageWidth/screenHeight; // approximately 4.0
//    CGFloat cropWidth = screenHeight * ratio;
//    CGFloat cropHeight = screenWidth * ratio;
//    
//    CGFloat jpegQuality = WGProfile.currentUser.imageQuality;
//    CGFloat imageMultiple = WGProfile.currentUser.imageMultiple;
//    
//    CGFloat translation = (imageHeight - cropHeight) / 2.0;
//    
//    UIImage *flippedImage;
//    if (!isTemplate) {
//        UIImage *croppedImage = [image croppedImage:CGRectMake(0, translation, cropWidth, cropHeight)];
//        UIImage *scaledImage = [croppedImage resizedImage:CGSizeMake(screenHeight*imageMultiple, screenWidth*imageMultiple) interpolationQuality:kCGInterpolationHigh];
//        flippedImage = scaledImage;
//        if (controller.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
//            flippedImage = [UIImage imageWithCGImage:[scaledImage CGImage]
//                                               scale:scaledImage.scale
//                                         orientation:UIImageOrientationLeftMirrored];
//        }
//    }
//    else {
////        UIImage *scaledImage = [image resizedImage:CGSizeMake(screenWidth*imageMultiple, screenHeight*imageMultiple) interpolationQuality:kCGInterpolationHigh];
//        flippedImage = image;
////        if (controller.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
////            flippedImage = [UIImage imageWithCGImage:[scaledImage CGImage]
////                                               scale:scaledImage.scale
////                                         orientation:UIImageOrientationLeftMirrored];
////        }
//    }
//    
//    return UIImageJPEGRepresentation(flippedImage, jpegQuality);

}


- (void)mediaPickerController:(UIImagePickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info {
    [self.eventConversationDelegate addLoadingBanner];
    NSDictionary *callbackInfo = nil;
    if ([[info allKeys] containsObject:UIMediaPickerText]) {
        NSString *text = [[info objectForKey:UIMediaPickerText] objectForKey:UIMediaPickerText];
        NSNumber *yPercentage = [[info objectForKey:UIMediaPickerText] objectForKey:UIMediaPickerPercentage];
        NSDictionary *properties = @{@"yPercentage": yPercentage};
         NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:self.options];
        callbackInfo = @{
                         @"message": text,
                         @"properties": properties,
                         };
        [mutableDict addEntriesFromDictionary:callbackInfo];
        self.options = mutableDict;
    }
    if ([self.tasksStillBeingUploaded containsObject:self.filenameString]) {
        [self.tasksStillBeingUploaded removeObject:self.filenameString];
    }
    else {
        [self.tasksStillBeingUploaded addObject:self.filenameString];
    }
    [self callbackFromUploadWithInfo:callbackInfo andFilename:self.filenameString];
  
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

// get sub image
- (UIImage*) getSubImageFrom: (UIImage*) img WithRect: (CGRect) rect {
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // translated rectangle for drawing sub image
    CGRect drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, img.size.width, img.size.height);
    
    // clip to the bounds of the image context
    // not strictly necessary as it will get clipped anyway?
    CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    
    // draw image
    [img drawInRect:drawRect];
    
    // grab image
    UIImage* subImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return subImage;
}


- (void)thumbnailGenerated:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    UIImage *image = [userInfo valueForKey:MPMoviePlayerThumbnailImageKey];
    [self uploadVideo:self.fileData
        withVideoName:@"video0.mp4"
          andThumnail:UIImageJPEGRepresentation(image, 1.0f)
      andThumnailName:@"thumnail0.jpeg"
           andOptions:self.options];
}

//- (void)didFinishPlaying:(NSNotification *)notification {
//    [self.moviePlayer stop];
//}

- (void)uploadContentWithFile:(NSData *)fileData
                  andFileName:(NSString *)filename
                   andOptions:(NSDictionary *)options
{
    // If it's image.
    if ([[options objectForKey:kMediaMimeTypeKey] isEqual:kImageEventType]) {
        WGEventMessage *newEventMessage = [WGEventMessage serialize:options];
        __weak typeof(self) weakSelf = self;
        [newEventMessage addPhoto:fileData withName:filename andHandler:^(WGEventMessage *object, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.error = error;
            strongSelf.object = object;
            NSDictionary *objectDict = [strongSelf.object deserialize];
            if ([[objectDict allKeys] containsObject:@"media"]) {
                NSString *mediaName = [objectDict objectForKey:@"media"];
                NSArray *components = [mediaName componentsSeparatedByString:@"/"];
                NSString *returnedFilename = [components lastObject];
                if ([strongSelf.tasksStillBeingUploaded containsObject:returnedFilename]) {
                    [strongSelf.tasksStillBeingUploaded removeObject:returnedFilename];
                }
                else {
                    [strongSelf.tasksStillBeingUploaded addObject:returnedFilename];
                }
                [strongSelf callbackFromUploadWithInfo:nil andFilename:returnedFilename];
            }
        }];
    } //If it's video
    else if ([[options objectForKey:kMediaMimeTypeKey] isEqual:kVideoEventType]) {
        NSData *thumbnailData = [options objectForKey:kThumbnailDataKey];
        NSString *thumnailFileName = [options objectForKey:@"thumbnail"];
        NSMutableDictionary *mutableOptions = [NSMutableDictionary dictionaryWithDictionary:options];
        [mutableOptions removeObjectForKey:kThumbnailDataKey];
        options = mutableOptions;
        WGEventMessage *newEventMessage = [WGEventMessage serialize:options];
        __weak typeof(self) weakSelf = self;
        
        NSLog(@"video data length: %d", (int)fileData.length);
        
        
//        NSURL *fileURL = options[@"fileURL"];
//        
//         NSURL *uploadURL = [NSURL fileURLWithPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"video_tmp"] stringByAppendingString:@".mp4"]];
//         
//         // Compress movie first
//         [self convertVideoToLowQuailtyWithInputURL:fileURL
//                                          outputURL:uploadURL
//                                         completion:^{
//        
//                                             
//                                             NSData *fileData = [NSData dataWithContentsOfURL:uploadURL];
//                                             NSLog(@"new length: %d", (int)fileData.length);
        
                                             
                                             
                                             [newEventMessage addVideo:fileData withName:filename thumbnail:thumbnailData thumbnailName:thumnailFileName andHandler:^(WGEventMessage *object, NSError *error) {
                                                 __strong typeof(weakSelf) strongSelf = weakSelf;
                                                 strongSelf.error = error;
                                                 strongSelf.object = object;
                                                 NSDictionary *objectDict = [strongSelf.object deserialize];
                                                 if ([[objectDict allKeys] containsObject:@"media"]) {
                                                     NSString *mediaName = [objectDict objectForKey:@"media"];
                                                     NSArray *components = [mediaName componentsSeparatedByString:@"/"];
                                                     NSString *returnedFilename = [components lastObject];
                                                     if ([strongSelf.tasksStillBeingUploaded containsObject:returnedFilename]) {
                                                         [strongSelf.tasksStillBeingUploaded removeObject:returnedFilename];
                                                     }
                                                     else {
                                                         [strongSelf.tasksStillBeingUploaded addObject:returnedFilename];
                                                     }
                                                     [strongSelf callbackFromUploadWithInfo:nil andFilename:returnedFilename];
                                                 }
//                                             }];
                                             
                                             
                                         }];
        
        
//        [newEventMessage addVideo:fileData withName:filename andHandler:^(WGEventMessage *object, NSError *error) {

//        }];
    }
}




// credit: http://stackoverflow.com/questions/11751883/how-can-i-reduce-the-file-size-of-a-video-created-with-uiimagepickercontroller



- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL*)outputURL
                                  completion:(void (^)(void))completion
{
    //setup video writer
    
    AVAsset *videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    
    
    AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGSize videoSize = videoTrack.naturalSize;
    
    NSLog(@"video size: %@", NSStringFromCGSize(videoSize));
    
    NSDictionary *videoWriterCompressionSettings =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1250000], AVVideoAverageBitRateKey, nil];
    
    NSDictionary *videoWriterSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, videoWriterCompressionSettings, AVVideoCompressionPropertiesKey, [NSNumber numberWithFloat:videoSize.width], AVVideoWidthKey, [NSNumber numberWithFloat:videoSize.height], AVVideoHeightKey, nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoWriterSettings];
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    videoWriterInput.transform = videoTrack.preferredTransform;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:nil];
    
    [videoWriter addInput:videoWriterInput];
    
    //setup video reader
    NSDictionary *videoReaderSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoReaderSettings];
    
    AVAssetReader *videoReader = [[AVAssetReader alloc] initWithAsset:videoAsset error:nil];
    
    [videoReader addOutput:videoReaderOutput];
    
    //setup audio writer
    AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeAudio
                                            outputSettings:nil];
    
    audioWriterInput.expectsMediaDataInRealTime = NO;
    
    [videoWriter addInput:audioWriterInput];
    
    //setup audio reader
    AVAssetTrack* audioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    AVAssetReaderOutput *audioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    
    AVAssetReader *audioReader = [AVAssetReader assetReaderWithAsset:videoAsset error:nil];
    
    [audioReader addOutput:audioReaderOutput];
    
    [videoWriter startWriting];
    
    //start writing from video reader
    [videoReader startReading];
    
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue1", NULL);
    
    [videoWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:^{
         
         while ([videoWriterInput isReadyForMoreMediaData]) {
             
             CMSampleBufferRef sampleBuffer;
             
             /*
              AVAssetReaderStatusUnknown = 0,
              AVAssetReaderStatusReading,
              AVAssetReaderStatusCompleted,
              AVAssetReaderStatusFailed,
              AVAssetReaderStatusCancelled,
              */
             
             NSLog(@"video reader status: %d", (int)[videoReader status]);
             if ([videoReader status] == AVAssetReaderStatusReading &&
                 (sampleBuffer = [videoReaderOutput copyNextSampleBuffer])) {
                 
                 [videoWriterInput appendSampleBuffer:sampleBuffer];
                 CFRelease(sampleBuffer);
             }
             
             else {
                 
                 [videoWriterInput markAsFinished];
                 
                 if ([videoReader status] == AVAssetReaderStatusCompleted) {
                     
                     //start writing from audio reader
                     [audioReader startReading];
                     
                     [videoWriter startSessionAtSourceTime:kCMTimeZero];
                     
                     dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue2", NULL);
                     
                     [audioWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:^{
                         
                         while (audioWriterInput.readyForMoreMediaData) {
                             
                             CMSampleBufferRef sampleBuffer;
                             
                             if ([audioReader status] == AVAssetReaderStatusReading &&
                                 (sampleBuffer = [audioReaderOutput copyNextSampleBuffer])) {
                                 
                                 [audioWriterInput appendSampleBuffer:sampleBuffer];
                                 CFRelease(sampleBuffer);
                             }
                             
                             else {
                                 
                                 [audioWriterInput markAsFinished];
                                 
                                 if ([audioReader status] == AVAssetReaderStatusCompleted) {
                                     
                                     [videoWriter finishWritingWithCompletionHandler:^(){
                                         dispatch_async(dispatch_get_main_queue(),
                                                        ^{
                                                            completion();
                                                        });
                                         
                                     }];
                                     
                                 }
                             }
                         }
                         
                     }
                      ];
                 }
             }
         }
     }
     ];
}








- (void)uploadVideo:(NSData *)fileData
      withVideoName:(NSString *)filename
        andThumnail:(NSData *)thumbnailData
    andThumnailName:(NSString *)thumbnailFilename
         andOptions:(NSDictionary *)options
{
    WGEventMessage *newEventMessage = [WGEventMessage serialize:options];
    __weak typeof(self) weakSelf = self;
    [newEventMessage addVideo:fileData withName:filename thumbnail:thumbnailData thumbnailName:thumbnailFilename andHandler:^(WGEventMessage *object, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [strongSelf.eventConversationDelegate showErrorMessage];
            return;
        }
        [object create:^(BOOL success, NSError *error) {
                if (error) {
                    [strongSelf.eventConversationDelegate showErrorMessage];
                    return;
                }
                strongSelf.firstCell = YES;
                [strongSelf.eventConversationDelegate showCompletedMessage];
                strongSelf.shownCurrentImage = YES;
                if (strongSelf.shownCurrentImage) {
                    [strongSelf.eventMessages replaceObjectAtIndex:1 withObject:object];
                }
                else {
                    [strongSelf.eventMessages insertObject:object atIndex:1];
                
                }
                [strongSelf.eventConversationDelegate reloadUIForEventMessages:strongSelf.eventMessages];
            if (!strongSelf.shownCurrentImage) {
                [strongSelf.eventConversationDelegate highlightCellAtPage:1 animated:YES];
            }
        }];
    }];
}

- (void)callbackFromUploadWithInfo:(NSDictionary *)info
                       andFilename:(NSString *)filenameString {
    if (![self.tasksStillBeingUploaded containsObject:filenameString]) {
        if (self.error) {
            [self.eventConversationDelegate showErrorMessage];
            return;
        }
        NSMutableDictionary *objectDict = [[NSMutableDictionary alloc] initWithDictionary:self.object.deserialize];
        [objectDict addEntriesFromDictionary:info];
        self.object = [[WGEventMessage alloc] initWithJSON:objectDict];
        __weak typeof(self) weakSelf = self;
        [self.object create:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.error) {
                [strongSelf.eventConversationDelegate showErrorMessage];
                return;
            }
            [strongSelf.eventConversationDelegate showCompletedMessage];
          
            if (!strongSelf.shownCurrentImage) {
                [strongSelf.eventMessages insertObject:strongSelf.object atIndex:1];
                [strongSelf.eventConversationDelegate reloadUIForEventMessages:self.eventMessages];
                [strongSelf.eventConversationDelegate highlightCellAtPage:1 animated:NO];
                strongSelf.shownCurrentImage = YES;
            }
            else {
                [strongSelf.eventMessages replaceObjectAtIndex:1 withObject:strongSelf.object];
                [strongSelf.eventConversationDelegate reloadUIForEventMessages:self.eventMessages];
                
                strongSelf.shownCurrentImage = NO;
            }
        }];
        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:self.options];

        [mutableDict addEntriesFromDictionary:@{
                                                @"user": WGProfile.currentUser.deserialize,
                                                @"created": [NSDate nowStringUTC],
                                                }];
        if (info && [info.allKeys containsObject:UIImagePickerControllerOriginalImage]) {
            UIImage *image =  (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
            [mutableDict setObject:image forKey:@"media"];
        }
        else {
            [mutableDict addEntriesFromDictionary:self.object.deserialize];
        }


        WGEventMessage *newEventMessage = [WGEventMessage serialize:mutableDict];

        if (!self.shownCurrentImage) {
            [self.eventMessages insertObject:newEventMessage atIndex:1];
            [self.eventConversationDelegate highlightCellAtPage:1 animated:NO];
            [self.eventConversationDelegate reloadUIForEventMessages:self.eventMessages];
            
            self.shownCurrentImage = YES;
        }
        else {
            self.shownCurrentImage = NO;
        }
        
    }

}

@end


@implementation MediaFlowLayout

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
    self.itemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

@end


@implementation VideoCell

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
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    self.backgroundColor = RGB(23, 23, 23);
    
    
    self.isCurrentVideoCell = NO;
    self.isRequestingThumbnail = NO;
    
    self.thumbnailImageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.thumbnailImageView];
    
    self.spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.frame = CGRectMake(self.thumbnailImageView.frame.size.width/4, self.thumbnailImageView.frame.size.height/4, self.thumbnailImageView.frame.size.width/2,  self.thumbnailImageView.frame.size.height/2);
    [self.thumbnailImageView addSubview:self.spinner];
    
    self.thumbnailImageView2 = [[UIImageView alloc] initWithFrame:self.frame];
    self.thumbnailImageView2.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView2.clipsToBounds = YES;
    self.thumbnailImageView2.hidden = YES;
    self.thumbnailImageView2.image = nil;
    [self.contentView addSubview:self.thumbnailImageView2];
    //[self.moviePlayer.backgroundView addSubview:self.thumbnailImageView2];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, self.frame.size.width, 40)];
    self.label.font = [FontProperties mediumFont:17.0f];
    self.label.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor whiteColor];
    self.label.hidden = YES;
    [self.contentView addSubview:self.label];
    [self.contentView bringSubviewToFront:self.label];
    
    self.touchableView = [[UIView alloc] initWithFrame:CGRectMake(0, 110, self.frame.size.width, self.frame.size.height - 200)];
    self.touchableView.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.touchableView];
    [self.contentView bringSubviewToFront:self.touchableView];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnContent)];
    singleTap.cancelsTouchesInView = YES;
    singleTap.numberOfTapsRequired = 1;
    [self.touchableView addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapToLike)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.cancelsTouchesInView = YES;
    [self.touchableView addGestureRecognizer:doubleTap];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    [self.contentView bringSubviewToFront:self.touchableView];
    [self.contentView bringSubviewToFront:self.label];
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    //[self unloadVideo];
}

- (void)prepareVideo {
    
    self.moviePlayer = [self.mediaScrollDelegate getAvailableMoviePlayer];
    
    NSLog(@"preparing video");
    self.moviePlayer.view.frame = self.bounds;
    self.moviePlayer.contentURL = self.videoURL;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerLoadStateChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:self.moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerThumbnailsLoaded:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:self.moviePlayer];
    
    
//    if(self.videoStartTime) {
//        self.moviePlayer.currentPlaybackTime = [self.videoStartTime floatValue];
//    }
    
    [self.moviePlayer prepareToPlay];
    
    [self.contentView addSubview:self.moviePlayer.view];
    [self.contentView bringSubviewToFront:self.thumbnailImageView];
    [self.contentView bringSubviewToFront:self.thumbnailImageView2];
    self.thumbnailImageView.hidden = NO;
    self.thumbnailImageView2.image = nil;
    self.thumbnailImageView2.hidden = YES;
    
    [self.contentView bringSubviewToFront:self.touchableView];
    [self.contentView bringSubviewToFront:self.label];
    
    [self.spinner startAnimating];
    
}

// play if ready, or start playing when ready

// cancel any outstanding thumbnail requests,
// as these will throw up the paused thumbnail on completion
- (void)resumeVideo {
    NSLog(@"resuming video");
    if(self.moviePlayer.isPreparedToPlay) {
        [self.moviePlayer play];
    }
    self.moviePlayer.shouldAutoplay = YES;
    [self.moviePlayer cancelAllThumbnailImageRequests];
}

// play if ready, or start playing when ready
- (void)startVideo {
    
    if(self.moviePlayer.isPreparedToPlay) {
        NSLog(@"start video - playing");
        [self.moviePlayer play];
    }
    else {
        NSLog(@"start video - playing when ready");
        
        self.moviePlayer.shouldAutoplay = YES;
    }
}

- (void)pauseVideo {
    
    if(self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
        
        NSLog(@"pausing video");
        
        [self.moviePlayer pause];
        
        //slight time adjustment to smooth pause effect
        NSArray *times = @[@(self.moviePlayer.currentPlaybackTime+0.05)];
        
        //NSLog(@"requesting thumbnail");
        
        // only allow one thumbnail request for the shared player
        [self.moviePlayer cancelAllThumbnailImageRequests];
        
        self.isRequestingThumbnail = YES;
        [self.mediaScrollDelegate markVideoPlayerIsSavingThumbnail:YES];
        [self.moviePlayer requestThumbnailImagesAtTimes:times timeOption:MPMovieTimeOptionExact];
        
    }
    //self.moviePlayer.shouldAutoplay = NO;
}

// handle the video player being moved to another cell

- (void)unloadVideoCell {
    
    NSLog(@"unloading video");
    
    [self.spinner stopAnimating];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.thumbnailImageView.hidden = NO;
    self.thumbnailImageView2.hidden = YES;
    
    if(self.isRequestingThumbnail) {
        self.isRequestingThumbnail = NO;
        [self.mediaScrollDelegate markVideoPlayerIsSavingThumbnail:NO];
    }
    
}


#pragma mark - MoviePlayerController nofitication handlers

- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification {
    if(self.moviePlayer == notification.object) {
        NSLog(@"playback state: %d", (int)self.moviePlayer.playbackState);
        
        if(self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying &&
           (self.moviePlayer.loadState & MPMovieLoadStatePlaythroughOK)) {
            [self updateUIForPlayback];
        }
    }
}

- (void) moviePlayerLoadStateChanged:(NSNotification*)notification {
    if(self.moviePlayer == notification.object) {
        NSLog(@"video load state: %d", (int)self.moviePlayer.loadState);
        
        if((self.moviePlayer.loadState & MPMovieLoadStatePlaythroughOK) &&
            self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
            [self updateUIForPlayback];
        }
    }
}

- (void)updateUIForPlayback {
    self.thumbnailImageView.hidden = YES;
    self.thumbnailImageView2.hidden = YES;
    [self.spinner stopAnimating];
}


- (void)moviePlayerThumbnailsLoaded:(NSNotification*)notification {
    
    if(notification.object == self.moviePlayer) {
        if(self.isRequestingThumbnail) {
            self.isRequestingThumbnail = NO;
            NSLog(@"thumbnail loaded");
            [self.mediaScrollDelegate markVideoPlayerIsSavingThumbnail:NO];
            
            UIImage *thumbnailImage = notification.userInfo[MPMoviePlayerThumbnailImageKey];
            if(thumbnailImage && [thumbnailImage isKindOfClass:[UIImage class]]) {
                self.thumbnailImageView2.image = thumbnailImage;
                self.thumbnailImageView2.hidden = NO;
                [self.contentView bringSubviewToFront:self.thumbnailImageView2];
                
                [self.contentView bringSubviewToFront:self.touchableView];
                [self.contentView bringSubviewToFront:self.label];
                
            }
        }
    }
}



@end

@implementation PromptCell

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
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    self.backgroundColor = UIColor.clearColor;
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];
    
    self.blackBackgroundLabel = [[UILabel alloc] initWithFrame:self.frame];
    self.blackBackgroundLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.7);
    [self.imageView addSubview:self.blackBackgroundLabel];
    
    self.titleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 150, self.frame.size.width - 30, 80)];
    self.titleTextLabel.font = [FontProperties mediumFont:20.0f];
    self.titleTextLabel.textColor = UIColor.whiteColor;
    self.titleTextLabel.numberOfLines = 0;
    self.titleTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleTextLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleTextLabel];
    
    self.subtitleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 320, self.frame.size.width - 30, 45)];
    self.subtitleTextLabel.font = [FontProperties mediumFont:18.0f];
    self.subtitleTextLabel.textColor = UIColor.whiteColor;
    self.subtitleTextLabel.numberOfLines = 0;
    self.subtitleTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.subtitleTextLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.subtitleTextLabel];

    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 365, self.frame.size.width - 60, 55)];
    [self.actionButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [FontProperties scMediumFont:20.0f];
    self.actionButton.layer.borderColor = UIColor.clearColor.CGColor;
    self.actionButton.layer.cornerRadius = 10.0f;
    self.actionButton.layer.borderWidth = 3.0f;
    [self.contentView addSubview:self.actionButton];

    self.avoidAction = [[UIButton alloc] initWithFrame:CGRectMake(15, self.frame.size.height - 55, self.frame.size.width - 30, 55)];
    [self.avoidAction setTitle:@"not now" forState:UIControlStateNormal];
    [self.avoidAction setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.avoidAction.titleLabel setFont: [FontProperties scMediumFont:18.0f]];
    [self.contentView addSubview:self.avoidAction];
    
    self.cameraAccessView = [[UIView alloc] initWithFrame:CGRectMake(0, 250, [UIScreen mainScreen].bounds.size.width, 192)];
    self.cameraAccessView.hidden = YES;
    [self.contentView addSubview:self.cameraAccessView];
    
    UILabel *firstLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, [UIScreen mainScreen].bounds.size.width, 40)];
    firstLabel.text = @"1.         Open iPhone Settings";
    firstLabel.textColor = UIColor.whiteColor;
    firstLabel.font = [FontProperties mediumFont:20.0f];
    [self.cameraAccessView addSubview:firstLabel];
    
    UIImageView *firstImageView = [[UIImageView alloc] initWithFrame:CGRectMake(43, 5, 25, 25)];
    firstImageView.image = [UIImage imageNamed:@"settings"];
    [self.cameraAccessView addSubview:firstImageView];
    
    UILabel *secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 40, [UIScreen mainScreen].bounds.size.width, 40)];
    secondLabel.text = @"2.         Find Wigo";
    secondLabel.textColor = UIColor.whiteColor;
    secondLabel.font = [FontProperties mediumFont:20.0f];
    [self.cameraAccessView addSubview:secondLabel];
    
    UIImageView *secondImageView = [[UIImageView alloc] initWithFrame:CGRectMake(43, 45, 25, 25)];
    secondImageView.image = [UIImage imageNamed:@"dancingG-0"];
    secondImageView.backgroundColor = UIColor.whiteColor;
    secondImageView.layer.borderColor = UIColor.clearColor.CGColor;
    secondImageView.layer.borderWidth = 1.0f;
    secondImageView.layer.cornerRadius = 4.0f;
    [self.cameraAccessView addSubview:secondImageView];
    
    UILabel *thirdLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 80, [UIScreen mainScreen].bounds.size.width, 40)];
    thirdLabel.text = @"3.         Enable Camera access";
    thirdLabel.textColor = UIColor.whiteColor;
    thirdLabel.font = [FontProperties mediumFont:20.0f];
    [self.cameraAccessView addSubview:thirdLabel];
    
    UIImageView *thirdImageView = [[UIImageView alloc] initWithFrame:CGRectMake(43, 85, 25, 25)];
    thirdImageView.image = [UIImage imageNamed:@"camera"];
    [self.cameraAccessView addSubview:thirdImageView];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIButton *gotItButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 60, 150, 120, 40)];
        [gotItButton setTitle:@"GOT IT" forState:UIControlStateNormal];
        [gotItButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        gotItButton.backgroundColor = [FontProperties getOrangeColor];
        [gotItButton addTarget:self action:@selector(gotItPressed) forControlEvents:UIControlEventTouchUpInside];
        gotItButton.layer.borderColor = UIColor.clearColor.CGColor;
        gotItButton.layer.borderWidth = 1.0f;
        gotItButton.layer.cornerRadius = 10.0f;
        [self.cameraAccessView addSubview:gotItButton];
    }
}

- (void)gotItPressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

@end


@implementation ImageCell

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
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    self.backgroundColor = UIColor.clearColor;
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];

    self.spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.frame = CGRectMake(self.imageView.frame.size.width/4, self.imageView.frame.size.height/4, self.imageView.frame.size.width/2,  self.imageView.frame.size.height/2);
    [self.imageView addSubview:self.spinner];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, self.frame.size.width, 40)];
    self.label.font = [FontProperties mediumFont:17.0f];
    self.label.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor whiteColor];
    self.label.hidden = YES;
    [self.contentView addSubview:self.label];
    [self.contentView bringSubviewToFront:self.label];
    
    
    self.touchableView = [[UIView alloc] initWithFrame:CGRectMake(0, 110, self.frame.size.width, self.frame.size.height - 200)];
    self.touchableView.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.touchableView];
    [self.contentView bringSubviewToFront:self.touchableView];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnContent)];
    singleTap.cancelsTouchesInView = YES;
    singleTap.numberOfTapsRequired = 1;
    [self.touchableView addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapToLike)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.cancelsTouchesInView = YES;
    [self.touchableView addGestureRecognizer:doubleTap];
    [singleTap requireGestureRecognizerToFail:doubleTap];

}


@end

@implementation MediaCell

- (void)cellDidDisappear {
    
}

- (void)updateUI {
    if (self.eventMessage.message) {
        NSString *message = self.eventMessage.message;
        if (message && [message isKindOfClass:[NSString class]]) {
            self.label.hidden = NO;
            self.label.text = self.eventMessage.message;
        }
        else self.label.hidden = YES;
        if (self.eventMessage.properties) {
            if (self.eventMessage.properties &&
                [self.eventMessage.properties isKindOfClass:[NSDictionary class]] &&
                [[self.eventMessage.properties allKeys] containsObject:@"yPercentage"]) {
                NSNumber *yPercentage = [self.eventMessage.properties objectForKey:@"yPercentage"];
                self.label.frame = CGRectMake(0, [yPercentage floatValue]*[[UIScreen mainScreen] bounds].size.height, self.frame.size.width, 40);
            }
        }
    }
    else self.label.hidden = YES;
    
    
}



- (void)sendVote:(BOOL)upvoteBool {
    [self.eventMessage vote:upvoteBool withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionPost];
        }
    }];
}

- (void)focusOnContent {
    [self.mediaScrollDelegate focusOnContent];
}

- (void)doubleTapToLike {
    [self.mediaScrollDelegate upvotePressed];
}

@end

@implementation CameraCell

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
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    self.isTakingPicture = NO;
    
//    self.controller = [[UIImagePickerController alloc] init];
//    self.controller.sourceType = UIImagePickerControllerSourceTypeCamera;
//    self.controller.cameraDevice = UIImagePickerControllerCameraDeviceRear;
//    self.controller.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
//    self.controller.videoQuality = UIImagePickerControllerQualityType640x480;
    self.controller.delegate = self;
//    self.controller.showsCameraControls = NO;
//
//    self.photoController = [[UIImagePickerController alloc] init];
//    self.photoController.sourceType = UIImagePickerControllerSourceTypeCamera;
//    self.photoController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
//    self.photoController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
//    self.photoController.videoQuality = UIImagePickerControllerQualityTypeMedium;
//    self.photoController.delegate = self;
//    self.photoController.showsCameraControls = NO;
    
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat cameraWidth = screenWidth;
    CGFloat cameraHeight = floor((4/3.0f) * cameraWidth);
    CGFloat scale = screenHeight / cameraHeight;
    CGFloat delta = screenHeight - cameraHeight;
    CGFloat yAdjust = delta / 2.0;
    
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, yAdjust); //This slots the preview exactly in the middle of the screen
    //self.controller.cameraViewTransform = CGAffineTransformScale(translate, scale, scale);
    
    self.photoController.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
    self.controller.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, nil];
    //[self.contentView addSubview:self.controller.view];
    
    
    //[self.contentView addSubview:self.cameraController.view];
    

    self.overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    //self.controller.cameraOverlayView = self.overlayView;
    
    //self.cameraController.cameraOverlayView = self.overlayView;
    
    self.pictureButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 100, 100, 100)];
    self.captureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.pictureButton.frame.size.width/2 - 36, self.pictureButton.frame.size.height - 72 - 5, 72, 72)];
    self.captureImageView.image = [UIImage imageNamed:@"captureCamera"];
    [self.pictureButton addSubview:self.captureImageView];
    self.pictureButton.center = CGPointMake(self.overlayView.center.x, self.pictureButton.center.y);
    [self.pictureButton addTarget:self action:@selector(takePicture) forControlEvents:UIControlEventTouchDown];
    [self.overlayView addSubview:self.pictureButton];
  
 //   UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//    tapGestureRecognizer.numberOfTapsRequired = 1;
//    [self.pictureButton addGestureRecognizer:tapGestureRecognizer];
    
//    if (WGProfile.currentUser.videoEnabled) {
        UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longGesture.cancelsTouchesInView = NO;
        longGesture.delaysTouchesBegan = YES;
        [self.pictureButton addGestureRecognizer:longGesture];
//        [longGesture requireGestureRecognizerToFail:tapGestureRecognizer];
//        [tapGestureRecognizer requireGestureRecognizerToFail:longGesture];
//    }
    
    self.circularProgressView = [[LLACircularProgressView alloc] initWithFrame:self.captureImageView.frame];
    // Optionally set the current progress
    self.circularProgressView.progress = 0.0f;
    self.circularProgressView.tintColor = [FontProperties getBlueColor];
    self.circularProgressView.innerObjectTintColor = [FontProperties getOrangeColor];
    self.circularProgressView.backgroundColor = UIColor.clearColor;
    self.circularProgressView.hidden = YES;
    [self.pictureButton addSubview:self.circularProgressView];
    
    self.flashButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.flashImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 37)];
    self.flashImageView.image = [UIImage imageNamed:@"flashOff"];
    [self.flashButton addSubview:self.flashImageView];
    [self.flashButton addTarget:self action:@selector(changeFlash) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.flashButton];
    
    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 100, 0, 100, 100)];
    self.cameraImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.switchButton.frame.size.width - 36 - 10, 10, 36, 29)];
    self.cameraImageView.image = [UIImage imageNamed:@"cameraIcon"];
    [self.switchButton addSubview:self.cameraImageView];
    [self.switchButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.switchButton];
    
    self.dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 100, 100, 100)];
    UIImageView *dismissImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, self.dismissButton.frame.size.height - 36 - 10, 36, 36)];
    dismissImageView.image = [UIImage imageNamed:@"cancelCamera"];
    [self.dismissButton addSubview:dismissImageView];
    [self.dismissButton addTarget:self action:@selector(dismissPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.dismissButton];
    
    self.previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.previewImageView.hidden = YES;
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.overlayView addSubview:self.previewImageView];
    
    self.previewMoviePlayer = [[MPMoviePlayerController alloc] init];
    self.previewMoviePlayer.movieSourceType = MPMovieSourceTypeFile;
    self.previewMoviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    [self.previewMoviePlayer setControlStyle: MPMovieControlStyleNone];
    self.previewMoviePlayer.repeatMode = MPMovieRepeatModeOne;
    self.previewMoviePlayer.shouldAutoplay = YES;
    self.previewMoviePlayer.view.frame = self.overlayView.bounds;
    self.previewMoviePlayer.view.hidden = YES;
    [self.overlayView addSubview:self.previewMoviePlayer.view];
    
    self.flashWhiteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.flashWhiteView.backgroundColor = UIColor.whiteColor;
    self.flashWhiteView.hidden = YES;
    [self.overlayView addSubview:self.flashWhiteView];
    [self.overlayView bringSubviewToFront:self.flashWhiteView];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    self.tapRecognizer.delegate = self;
    [self.previewImageView addGestureRecognizer:self.tapRecognizer];
    
    UITapGestureRecognizer *newTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    newTapGestureRecognizer.delegate = self;
    [self.previewMoviePlayer.view addGestureRecognizer:newTapGestureRecognizer];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    self.panRecognizer.delegate = self;
    self.panRecognizer.enabled = NO;
    [self addGestureRecognizer:self.panRecognizer];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 100, 100, 100)];
    [self.cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *cancelLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.cancelButton.frame.size.height - 50, 100, 50)];
    cancelLabel.text = @"< Cancel";
    cancelLabel.textColor = UIColor.whiteColor;
    cancelLabel.textAlignment = NSTextAlignmentLeft;
    cancelLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    cancelLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
    cancelLabel.layer.shadowOpacity = 0.5;
    cancelLabel.layer.shadowRadius = 0.5;
    [self.cancelButton addSubview:cancelLabel];
    self.cancelButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.cancelButton.hidden = YES;
    self.cancelButton.enabled = NO;
    [self.overlayView addSubview:self.cancelButton];
    
    self.postButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, [UIScreen mainScreen].bounds.size.height - 100, 100, 100)];
    [self.postButton addTarget:self action:@selector(postPressed) forControlEvents:UIControlEventTouchUpInside];
    UILabel *postLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.postButton.frame.size.width - 100, self.postButton.frame.size.height - 50, 100, 50)];
    postLabel.text = @"Post >";
    postLabel.textColor = UIColor.whiteColor;
    postLabel.textAlignment = NSTextAlignmentRight;
    postLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    postLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
    postLabel.layer.shadowOpacity = 0.5;
    postLabel.layer.shadowRadius = 0.5;
    [self.postButton addSubview:postLabel];
    self.postButton.hidden = YES;
    self.postButton.enabled = NO;
    self.postButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [self.overlayView addSubview:self.postButton];
    
    self.textField = [UITextField new];
    self.textField.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.textField.textColor = UIColor.whiteColor;
    self.textField.textAlignment = NSTextAlignmentCenter;
    self.textField.font = [FontProperties mediumFont:17.0f];
    self.textField.delegate = self;
    self.textField.returnKeyType = UIReturnKeyDone;
    [self.overlayView addSubview:self.textField];
    [self.overlayView bringSubviewToFront:self.textField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    
    self.textLabel = [UILabel new];
    self.textLabel.hidden = YES;
    self.textLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.textLabel.textColor = UIColor.whiteColor;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.font = [FontProperties mediumFont:17.0f];
    [self.overlayView addSubview:self.textLabel];
    [self.overlayView bringSubviewToFront:self.textLabel];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(cameraIsReady:)
//                                                 name:AVCaptureSessionDidStartRunningNotification object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(cameraStopped:)
//                                                 name:AVCaptureSessionDidStopRunningNotification
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerThumbnailsLoaded:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:self.previewMoviePlayer];
    
    self.controller.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    self.photoController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    
}

- (void)setupCameraController:(WGCameraViewController *)cameraController {
    self.cameraController = cameraController;
    [self.contentView addSubview:self.cameraController.view];
    self.cameraController.cameraOverlayView = self.overlayView;
    self.cameraController.delegate = self;
}

- (void)cellWillAppear {
}

- (void)cellDidDisappear {
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cameraIsReady:(NSNotification *)notification {
    NSLog(@"camera is ready");
//    if(notification.object && [notification.object isKindOfClass:[AVCaptureSession class]]) {
//        self.captureSession = notification.object;
//        if (![self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//            NSLog(@"cannot set preset %@", AVCaptureSessionPreset1280x720);
//        }
//        [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
//    }
//    
//    if(self.isTakingPicture) {
//        self.isTakingPicture = NO;
//        [self.photoController takePicture];
//    }
}

- (void)cameraStopped:(NSNotification *)notification {
    NSLog(@"camera stopped");
}


- (void)handleTap:(UITapGestureRecognizer *)sender {
    NSLog(@"tap state: %d", (int)sender.state);
    if(sender.state == UIGestureRecognizerStateRecognized) {
        [self takePicture];
    }
}

- (void)takePicture {
    NSLog(@"capture mode: %d", (int)self.controller.cameraCaptureMode);
    NSLog(@"taking picture");
    
    
    //self.controller.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    if (self.photoController.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn &&
        self.photoController.cameraDevice == UIImagePickerControllerCameraDeviceFront ) {
        [UIView animateWithDuration:0.04 animations:^{
            self.flashWhiteView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            self.flashWhiteView.alpha = 0.0f;
        }];
    }
    self.pictureButton.userInteractionEnabled = NO;
    
    
    // take picture
    
//    UIGraphicsBeginImageContextWithOptions(self.controller.view.frame.size, NO, 0.0);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    [self.controller.view.layer renderInContext:context];
//    
//    UIImage *photo = UIGraphicsGetImageFromCurrentImageContext();
//    
//    UIGraphicsEndImageContext();
//    
//    NSDictionary *mediaDict = @{UIImagePickerControllerMediaMetadata:@{},
//                                UIImagePickerControllerMediaType:@"public.image",
//                                UIImagePickerControllerOriginalImage:photo};
//    
//    [self imagePickerController:self.controller
//  didFinishPickingMediaWithInfo:mediaDict];
    
//    self.isTakingPicture = YES;
//    
//    [self.controller.view removeFromSuperview];
//    [self.contentView addSubview:self.photoController.view];
    
    //[self.photoController takePicture];
    
    [self.cameraController takePictureWithCompletion:^(UIImage *image, NSDictionary *attachments, NSError *error) {
        
        NSDictionary *mediaDict = @{UIImagePickerControllerMediaMetadata:attachments,
                                    UIImagePickerControllerMediaType:@"public.image",
                                    UIImagePickerControllerOriginalImage:image};
        [self imagePickerController:self.controller
      didFinishPickingMediaWithInfo:mediaDict];
        
    }];
    
    for(AVCaptureInput *input in self.captureSession.inputs) {
        NSLog(@"input: %@", input.description);
    }
    
    
    AVCaptureStillImageOutput *stillImageOutput = nil;
    for(AVCaptureOutput *output in self.captureSession.outputs) {
        if([output isKindOfClass:[AVCaptureStillImageOutput class]]) {
            stillImageOutput = (AVCaptureStillImageOutput *)output;
        }
        NSLog(@"output: %@", output.description);
    }
    
    NSDictionary *outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG,
                                      (NSString*)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
    
    [stillImageOutput setOutputSettings:outputSettings];
//    
//    NSString* key = ;
//    NSNumber* value = ;
//    NSDictionary* outputSettings = [NSDictionary dictionaryWithObject:value forKey:key];
//    
//    [newStillImageOutput setOutputSettings:outputSettings];
//    
//    AVCaptureConnection *videoConnection = nil;
//    for (AVCaptureConnection *connection in stillImageOutput.connections) {
//        for (AVCaptureInputPort *port in [connection inputPorts]) {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection) { break; }
//    }
//    
//    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
//     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
//         CFDictionaryRef exifAttachments =
//         CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
//         
//         if (exifAttachments) {
//             // Do something with the attachments.
//         }
//         
//         UIImage *image = [self imageFromSampleBuffer:imageSampleBuffer];
//
//         if(image) {
//             
//             NSDictionary *mediaDict = @{UIImagePickerControllerMediaMetadata:(__bridge NSDictionary *)exifAttachments,
//                                         UIImagePickerControllerMediaType:@"public.image",
//                                         UIImagePickerControllerOriginalImage:image};
//             [self imagePickerController:self.controller
//           didFinishPickingMediaWithInfo:mediaDict];
//         }
//         
//         // Continue as appropriate.
//     }];

}

// courtesy http://stackoverflow.com/questions/3305862/uiimage-created-from-cmsamplebufferref-not-displayed-in-uiimageview

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
//    
//    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
//    CGContextRelease(newContext);
//    
//    CGColorSpaceRelease(colorSpace);
//    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//    /* CVBufferRelease(imageBuffer); */  // do not call this!
//    
//    return newImage;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    image = [image imageRotatedByDegrees:90.0];
    return (image);

}

- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    // NSLog(@"gesture state: %d", (int)gesture.state);
    
    if (!self.longGesturePressed && gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long press gesture began");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"setting up progress view");
            [self.circularProgressView setProgress:0.0f];
            self.circularProgressView.hidden = NO;
            self.videoTimerCount = 8.0f;
            self.longGesturePressed = YES;
            self.controller.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            self.controller.videoMaximumDuration = 8.0f;
        });
        [self performBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // need to re-check longGesturePressed this to ensure video recording hasn't been cancelled
                
                if(self.longGesturePressed) {
                    NSLog(@"starting video capture");
                    [self.cameraController startRecordingVideo];
                    //[self.controller startVideoCapture];
                    self.isRecording = YES;
                    
                    self.videoTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 target:self selector:@selector(videoCaptureTimerFired:) userInfo: @{@"gesture": gesture, @"progress": self.circularProgressView} repeats: YES];
                    [self.videoTimer fire];
                }
                
            });
        } afterDelay:0.4];
    }
    if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"long press ended/cancelled (%d)", (int)gesture.state);
        if(self.longGesturePressed) {
            NSLog(@"recording stopped");
            [self stopRecordingVideo];
        }
        else {
            NSLog(@"long gesture NOT pressed - no recording stopped");
        }
    }
}

- (void) videoCaptureTimerFired:(NSTimer *) timer {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(!self.isRecording) {
            
            
            NSLog(@"recording was cancelled");
            return;
        }
        
        
        //NSLog(@"video fire (%f)", timer.timeInterval);
        self.videoTimerCount -= timer.timeInterval;
        //NSLog(@"video timer count: %f", self.videoTimerCount);
        
        //NSLog(@"camera %@", NSStringFromCGAffineTransform(self.controller.cameraViewTransform));
        
        UILongPressGestureRecognizer *gesture = timer.userInfo[@"gesture"];
        [self.circularProgressView setProgress: MIN(1.0, (8.0 - self.videoTimerCount)/8.0) animated:YES];
        
        if (self.videoTimerCount <= 0) {
            
            [timer invalidate];

            //hack to cancel the gesture.
            gesture.enabled = NO;
            gesture.enabled = YES;
            
            [self stopRecordingVideo];
            
        }
    });
}

- (void)stopRecordingVideo {
    
    [self.videoTimer invalidate];
    
    if (self.isRecording) {
        
        // tell camera to stop recording
        [self.cameraController stopRecording];
    }
    else {
        
        // tell camera to cancel
        [self.cameraController cancelRecording];
    }
    
    self.circularProgressView.hidden = YES;
    [self.circularProgressView setProgress:0.0f];
    self.longGesturePressed = NO;
    self.isRecording = NO;
}



- (void)changeFlash {
    
    [self.cameraController toggleFlash];
    if (self.cameraController.flashEnabled) {
        self.flashImageView.image = [UIImage imageNamed:@"flashOn"];
        self.flashImageView.frame = CGRectMake(10, 10, 18, 30);
        self.photoController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
    }
    else {
        self.flashImageView.image = [UIImage imageNamed:@"flashOff"];
        self.flashImageView.frame = CGRectMake(10, 10, 30, 37);
        self.photoController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    }
}

- (void)switchCamera {
    
    [UIView animateWithDuration:.15f animations:^{
        self.cameraImageView.transform = CGAffineTransformMakeScale(1.5,1.5);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.15f animations:^{
            self.cameraImageView.transform = CGAffineTransformMakeScale(1.0,1.0);
            if(self.cameraController.isUsingFrontFacingCamera) {
                self.flashButton.alpha = 0.0;
            }
            else {
                self.flashButton.alpha = 1.0;
            }
        }];
    }];
    
    [self.cameraController switchCameras:self];
}

- (void)dismissPressed {
    [self.mediaScrollDelegate dismissView];
}


// WGCameraViewControllerDelegate methods

- (void)cameraController:(WGCameraViewController *)controller didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self imagePickerController:nil didFinishPickingMediaWithInfo:info];
}

- (void)cameraControllerDidCancel:(WGCameraViewController *)picker {
    NSLog(@"camera controller cancelled");
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker; {
    NSLog(@"image picker cancelled");
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    NSLog(@"finished picking %@", (NSString *)mediaType);
    
    
    // change camera back to default camera mode
    //self.controller.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    
    self.dismissButton.hidden = YES;
    self.dismissButton.enabled = NO;
    self.pictureButton.hidden = YES;
    self.pictureButton.userInteractionEnabled = NO;
    self.flashButton.hidden = YES;
    self.flashButton.enabled = NO;
    self.switchButton.hidden = YES;
    self.switchButton.enabled = NO;
    
    self.postButton.hidden = NO;
    self.postButton.enabled = YES;
    self.cancelButton.hidden = NO;
    self.cancelButton.enabled = YES;
    self.panRecognizer.enabled = NO;
    
    //if(picker == self.controller) {
    if([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.previewMoviePlayer.view.hidden = NO;
            NSURL *fileURL = [info objectForKey:UIImagePickerControllerMediaURL];
            self.previewMoviePlayer.contentURL = fileURL;
            //[self.previewMoviePlayer prepareToPlay];
            [self.previewMoviePlayer play];
            
            // request thumbnail.
            // when the thumbnail returns, the video will be uploaded with the thumbnail
            [self.previewMoviePlayer requestThumbnailImagesAtTimes:@[@(0.0)]
                                                        timeOption:MPMovieTimeOptionExact];
            
        });
        self.info = [NSMutableDictionary dictionaryWithDictionary:info];
    }
    else { //picked photo
        self.previewImageView.hidden = NO;
        self.previewImageView.userInteractionEnabled = YES;
        self.previewImageView.image = (UIImage *) [self.info objectForKey: UIImagePickerControllerOriginalImage];
        NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
        UIImage *image =  (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
        UIImage *newImage = image;
        if (self.controller.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
            newImage = [UIImage imageWithCGImage:[image CGImage]
                                                    scale:image.scale
                                              orientation:UIImageOrientationLeftMirrored];
            [newInfo setObject:newImage forKey:UIImagePickerControllerOriginalImage];
        }
        self.info = [[NSMutableDictionary alloc] initWithDictionary:newInfo];
        self.previewImageView.hidden = NO;
        self.previewImageView.userInteractionEnabled = YES;
        self.previewImageView.image = newImage;
        [self.mediaScrollDelegate mediaPickerController:self.controller
                                 startUploadingWithInfo:self.info];
    }
}

- (void)moviePlayerThumbnailsLoaded:(NSNotification*)notification {
    
    if(notification.object == self.previewMoviePlayer) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           
                           UIImage *thumbnailImage = notification.userInfo[MPMoviePlayerThumbnailImageKey];
                           if(thumbnailImage) {
                               self.info[kThumbnailImageKey] = thumbnailImage;
                           
//                           [self.mediaScrollDelegate mediaPickerController:self.controller
//                                                    startUploadingWithInfo:self.info];
                           }
                           else {
                               // cancel upload
                               [self cancelPressed];
                               
                           }
                       });
    }
}

- (void)cancelPressed {
    //self.controller.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    [self.mediaScrollDelegate cancelPressed];
    [self cleanupView];
    self.info = nil;
}


- (void)cleanupView {
    self.dismissButton.hidden = NO;
    self.dismissButton.enabled = YES;
    self.pictureButton.hidden = NO;
    self.pictureButton.userInteractionEnabled = YES;
    self.flashButton.hidden = NO;
    self.flashButton.enabled = YES;
    self.switchButton.hidden = NO;
    self.switchButton.enabled = YES;

    [self.previewMoviePlayer stop];
    self.previewMoviePlayer.view.hidden = YES;
    self.previewMoviePlayer.contentURL = nil;
    
    self.previewImageView.hidden = YES;
    self.previewImageView.userInteractionEnabled = NO;
    self.previewImageView.image = nil;
    self.postButton.hidden = YES;
    self.postButton.enabled = NO;
    self.cancelButton.hidden = YES;
    self.cancelButton.enabled = NO;
    self.textLabel.text = @"";
    self.textField.text = @"";
    self.textField.hidden = YES;
    self.textLabel.hidden = YES;
    self.panRecognizer.enabled = NO;
}

- (void)postPressed {
    NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:self.info];
    if (self.textField.text.length > 0) {
        [newInfo addEntriesFromDictionary:@{
                                            UIMediaPickerText: @{
                                                    UIMediaPickerText: self.textField.text,
                                                    UIMediaPickerPercentage: [NSNumber numberWithFloat:self.percentPoint.y]
                                                    }
                                            }];
    }
    
    [self.mediaScrollDelegate mediaPickerController:self.controller
                             didFinishMediaWithInfo:newInfo];
    [self cleanupView];
}

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)panRecognizer {
    CGPoint center = [panRecognizer locationInView:self.previewImageView];
    if (!self.textField.isFirstResponder) {
        center.y = MIN(MAX(center.y, 125), [UIScreen mainScreen].bounds.size.height - 158);
        self.textField.hidden = YES;
        self.textLabel.hidden = NO;
        self.textLabel.text = self.textField.text;
        self.textLabel.frame =  CGRectMake(0, center.y, [UIScreen mainScreen].bounds.size.width, 40);
        self.percentPoint = CGPointMake(1 - (center.x/[UIScreen mainScreen].bounds.size.width), center.y/[UIScreen mainScreen].bounds.size.height);
    }
}

// this allows you to dispatch touches
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}
// this enables you to handle multiple recognizers on single view
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)tapGestureRecognizer:(UIGestureRecognizer*)recognizer {
    if (!self.previewImageView.isHidden || !self.previewMoviePlayer.view.isHidden) {
        CGPoint center = [recognizer locationInView:self];
        float heightScreen = [UIScreen mainScreen].bounds.size.height;
        float widthScreen = [UIScreen mainScreen].bounds.size.width;
        self.percentPoint = CGPointMake(1 - (center.x/widthScreen), center.y/heightScreen);
        self.percentPoint = CGPointMake(self.percentPoint.x, MIN(MAX(self.percentPoint.y, 125/[UIScreen mainScreen].bounds.size.height), 1 - (158/[UIScreen mainScreen].bounds.size.height)));
        self.textLabel.frame = CGRectMake(0, center.y, [UIScreen mainScreen].bounds.size.width, 40);
        
        if (![self.textField isFirstResponder]) {
            self.textLabel.hidden = YES;
            [self.textField becomeFirstResponder];
            self.panRecognizer.enabled = YES;
        }
        else {
            [self.textField endEditing:YES];
            self.textField.hidden = YES;
            self.textLabel.hidden = NO;
            self.textLabel.text = self.textField.text;
        }
    }
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.textField.hidden = NO;
    float yPosition = self.percentPoint.y * [UIScreen mainScreen].bounds.size.height;
    self.textField.frame = CGRectMake(0, yPosition, [UIScreen mainScreen].bounds.size.width, 40);
    [UIView animateWithDuration:0.3 animations:^{
        self.textField.frame = CGRectMake(0, kbFrame.origin.y - 40, [UIScreen mainScreen].bounds.size.width, 40);
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.textField endEditing:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.textField.hidden = YES;
        self.textLabel.hidden = NO;
        self.textLabel.text = self.textField.text;
        float yPosition = self.percentPoint.y * [UIScreen mainScreen].bounds.size.height;
        self.textLabel.frame =  CGRectMake(0, yPosition, [UIScreen mainScreen].bounds.size.width, 40);
    }];
    if (self.textField.text.length == 0) {
        self.textField.hidden = YES;
        self.textLabel.hidden = YES;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    CGSize size = [newString sizeWithAttributes:
                   @{NSFontAttributeName:textField.font}];
    if (size.width < [UIScreen mainScreen].bounds.size.width - 10) return YES;
    return NO;
}


@end
