//
//  ImagesScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MediaScrollView.h"
#import "Globals.h"
#import "EventMessagesConstants.h"
#import "WGEventMessage.h"
#import "WGCollection.h"
#import <AVFoundation/AVFoundation.h>

@interface MediaScrollView() {}
@property (nonatomic, strong) NSMutableArray *pageViews;

@property (nonatomic, strong) WGCollection *eventMessagesRead;
@property (nonatomic, strong) NSMutableDictionary *thumbnails;

@property (nonatomic, strong) UIView *chatTextFieldWrapper;
@property (nonatomic, strong) UILabel *addYourVerseLabel;

@property (nonatomic, assign) BOOL shownCurrentImage;
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
    self.backgroundColor = RGB(23, 23, 23);
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.dataSource = self;
    [self registerClass:[VideoCell class] forCellWithReuseIdentifier:@"VideoCell"];
    [self registerClass:[ImageCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [self registerClass:[PromptCell class] forCellWithReuseIdentifier:@"PromptCell"];
    [self registerClass:[CameraCell class] forCellWithReuseIdentifier:@"CameraCell"];
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
    if ([mimeType isEqualToString:kCameraType]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusDenied) {
            PromptCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PromptCell" forIndexPath: indexPath];
            [myCell.imageView setSmallImageForUser:WGProfile.currentUser completed:nil];
             myCell.titleTextLabel.frame = CGRectMake(15, 160, self.frame.size.width - 30, 60);
            myCell.titleTextLabel.text = @"Please Give WiGo an access to camera to add to the story:";
            myCell.avoidAction.hidden = YES;
            myCell.cameraAccessImageView.hidden = NO;
            myCell.isPeeking = self.isPeeking;
            return myCell;
        } else {
            CameraCell *cameraCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CameraCell" forIndexPath: indexPath];
            cameraCell.mediaScrollDelegate = self;
            [self.pageViews setObject:cameraCell.controller atIndexedSubscript:indexPath.row];
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
                        [weakCell.spinner startAnimating];
                        [weakCell.imageView setImageWithURL:realURL
                                           placeholderImage:image
                                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
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
        myCell.titleTextLabel.text = [NSString stringWithFormat:@"Sweet, you're going out to %@.", [self.event name]];
        myCell.subtitleTextLabel.text = @"You can now post inside this event";
        myCell.subtitleTextLabel.alpha = 0.7f;
        myCell.actionButton.backgroundColor = [FontProperties getOrangeColor];
        [myCell.actionButton setTitle:@"ADD TO THIS EVENT" forState:UIControlStateNormal];
        [myCell.actionButton.titleLabel setFont: [FontProperties scMediumFont: 16.0]];
        [myCell.actionButton addTarget:self action:@selector(promptCamera) forControlEvents:UIControlEventTouchUpInside];
        [myCell.avoidAction addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
        myCell.isPeeking = self.isPeeking;

        return myCell;
    }
    else if ([mimeType isEqualToString:kNotAbleToPost]) {
        PromptCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PromptCell" forIndexPath: indexPath];
        [myCell.imageView setImageWithURL:[WGProfile currentUser].coverImageURL];
        myCell.titleTextLabel.text = @"To add a highlight you\nmust be going here.";
        myCell.avoidAction.hidden = YES;
        myCell.isPeeking = self.isPeeking;

        return myCell;
    } else {
        VideoCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath: indexPath];
        myCell.mediaScrollDelegate = self;
        myCell.eventMessage = eventMessage;
        myCell.isPeeking = self.isPeeking;

        [myCell updateUI];
        NSString *thumbnailURL = [eventMessage objectForKey:@"thumbnail"];
        if (![thumbnailURL isKindOfClass:[NSNull class]]) {
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, thumbnailURL]];
            [myCell.thumbnailImageView setImageWithURL:imageURL];
            [myCell.thumbnailImageView2 setImageWithURL:imageURL];
        }
        NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, contentURL]];
        myCell.moviePlayer.contentURL = videoURL;
        if (self.firstCell) {
            [myCell.moviePlayer play];
            self.lastMoviePlayer = myCell.moviePlayer;
            self.firstCell = NO;
        }
        [self.pageViews setObject:myCell.moviePlayer atIndexedSubscript:indexPath.row];
        return myCell;
    }
}

- (void)updateEventMessage:(WGEventMessage *)eventMessage forCell:(UICollectionViewCell *)cell {
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    [self.eventMessages replaceObjectAtIndex:[indexPath row] withObject:eventMessage];
}

- (void)closeView {
    if (self.lastMoviePlayer) {
        [self.lastMoviePlayer stop];
    }
    for (int i = self.minPage; i <= self.maxPage; i++) {
        [self addReadPage:i];
    }
    if (self.eventMessagesRead.count > 0) {
        __weak typeof(self) weakSelf = self;
        [self.event setMessagesRead:self.eventMessagesRead andHandler:^(BOOL success, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                return;
            }
            [strongSelf.storyDelegate readEventMessageIDArray:[strongSelf.eventMessagesRead idArray]];
        }];
    }
}

- (void)dismissView {
    [self.eventConversationDelegate dismissView];
}

- (void)promptCamera {
    [self.eventConversationDelegate promptCamera];
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

    // [self performBlock:^(void){[self playVideoAtPage:page];} afterDelay:0.5 cancelPreviousRequest:YES];
    [self playVideoAtPage:page];
}


- (void)playVideoAtPage:(int)page {
    if (self.lastMoviePlayer) [self.lastMoviePlayer stop];
    if ((int)page < [self.pageViews count]) {
        MPMoviePlayerController *theMoviePlayer = [self.pageViews objectAtIndex:page];
        if ([theMoviePlayer isKindOfClass:[MPMoviePlayerController class]] &&
            theMoviePlayer.playbackState != MPMoviePlaybackStatePlaying) {
            [theMoviePlayer play];
            self.lastMoviePlayer = theMoviePlayer;
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

#pragma mark - IQMediaPickerController Delegate methods

- (void)mediaPickerController:(UIImagePickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info {
    if (self.cameraPromptAddToStory) {
        [WGAnalytics tagEvent: @"Go Here, Then Add to Story, Then Picture Captured"];
        self.cameraPromptAddToStory = false;
    } else {
        [WGAnalytics tagEvent: @"Event Conversation Captured Picture"];
    }

    [self.eventConversationDelegate addLoadingBanner];
    NSString *type = @"";
   
    UIImage *image;
    NSData *fileData;
    if ([[info allKeys] containsObject:UIImagePickerControllerOriginalImage]) {
        image = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
        
        CGFloat imageWidth = image.size.height * 1.0; // because the image is rotated
        CGFloat imageHeight = image.size.width * 1.0; // because the image is rotated

        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        
        CGFloat ratio = imageWidth/screenHeight; // approximately 4.0
        CGFloat cropWidth = screenHeight * ratio;
        CGFloat cropHeight = screenWidth * ratio;
        
        CGFloat jpegQuality = 0.8;
        CGFloat imageMultiple = 1.0f;
        
        CGFloat translation = (imageHeight - cropHeight) / 2.0;
    
        UIImage *croppedImage = [image croppedImage:CGRectMake(0, translation, cropWidth, cropHeight)];
        UIImage *scaledImage = [croppedImage resizedImage:CGSizeMake(screenHeight*imageMultiple, screenWidth*imageMultiple) interpolationQuality:kCGInterpolationHigh];
        UIImage *flippedImage = scaledImage;
        if (controller.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
            flippedImage = [UIImage imageWithCGImage:[scaledImage CGImage]
                                                    scale:scaledImage.scale
                                              orientation:UIImageOrientationLeftMirrored];
        }

        fileData = UIImageJPEGRepresentation(flippedImage, jpegQuality);
        type = kImageEventType;
    }
    
    if ([[info allKeys] containsObject:UIMediaPickerText]) {
        NSString *text = [[info objectForKey:UIMediaPickerText] objectForKey:UIMediaPickerText];
        NSNumber *yPercentage = [[info objectForKey:UIMediaPickerText] objectForKey:UIMediaPickerPercentage];
        NSDictionary *properties = @{@"yPercentage": yPercentage};
        self.options =  @{
                          @"event": self.event.id,
                          @"message": text,
                          @"properties": properties,
                          @"media_mime_type": type
                          };
    }
    else {
        self.options =  @{
                          @"event": self.event.id,
                          @"media_mime_type": type
                          };
    }
    
    [self uploadContentWithFile:fileData
                    andFileName:@"image0.jpg"
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

    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:self.options];

    if ([[info allKeys] containsObject:UIImagePickerControllerOriginalImage]) {
        [mutableDict addEntriesFromDictionary:@{
                                                @"user": [WGProfile currentUser],
                                                @"created": [NSDate nowStringUTC],
                                                @"media": image
                                                }];
        NSLog(@"media info: %@", mutableDict);
    }
//    else if ( [[info allKeys] containsObject:IQMediaTypeVideo]) {
//        [mutableDict addEntriesFromDictionary:@{
//                                                @"user": WGProfile.currentUser,
//                                                @"created": [NSDate nowStringUTC],
//                                                @"media": [[[info objectForKey:IQMediaTypeVideo] objectAtIndex:0] objectForKey:IQMediaURL],
//                                                }];
//        NSLog(@"media info: %@", mutableDict);
//    }
    
    WGEventMessage *newEventMessage = [WGEventMessage serialize:mutableDict];
    
    if (!self.shownCurrentImage) {
        [self.eventMessages replaceObjectAtIndex:(self.eventMessages.count - 1) withObject:newEventMessage];
        [self.eventConversationDelegate reloadUIForEventMessages:self.eventMessages];
        self.shownCurrentImage = YES;
    }
  
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

- (void)didFinishPlaying:(NSNotification *)notification {
    [self.moviePlayer stop];
}

- (void)uploadContentWithFile:(NSData *)fileData
                  andFileName:(NSString *)filename
                   andOptions:(NSDictionary *)options
{
    WGEventMessage *newEventMessage = [WGEventMessage serialize:options];
    [newEventMessage addPhoto:fileData withName:filename andHandler:^(WGEventMessage *object, NSError *error) {
        if (error) {
            [self.eventConversationDelegate showErrorMessage];
            return;
        }
        [object create:^(BOOL success, NSError *error) {
            if (error) {
                [self.eventConversationDelegate showErrorMessage];
                return;
            }
            [self.eventConversationDelegate showCompletedMessage];
            self.shownCurrentImage = YES;
            [self.eventMessages replaceObjectAtIndex:(self.eventMessages.count - 2) withObject:object];
            if (self.shownCurrentImage) {
                [self.eventMessages removeObjectAtIndex:self.eventMessages.count - 1];
            }
            [self.eventConversationDelegate reloadUIForEventMessages:self.eventMessages];
        }];
    }];
}

- (void)uploadVideo:(NSData *)fileData
      withVideoName:(NSString *)filename
        andThumnail:(NSData *)thumbnailData
    andThumnailName:(NSString *)thumbnailFilename
         andOptions:(NSDictionary *)options
{
    WGEventMessage *newEventMessage = [WGEventMessage serialize:options];
    [newEventMessage addVideo:fileData withName:filename thumbnail:thumbnailData thumbnailName:thumbnailFilename andHandler:^(WGEventMessage *object, NSError *error) {
        if (error) {
            [self.eventConversationDelegate showErrorMessage];
            return;
        }
        [object create:^(BOOL success, NSError *error) {
                if (error) {
                    [self.eventConversationDelegate showErrorMessage];
                    return;
                }
                self.firstCell = YES;
                [self.eventConversationDelegate showCompletedMessage];
                self.shownCurrentImage = YES;
                [self.eventMessages replaceObjectAtIndex:(self.eventMessages.count - 2) withObject:object];
                // [self playVideoAtPage:(int)(self.eventMessages.count - 2)];
                if (self.shownCurrentImage) {
                    [self.eventMessages removeObjectAtIndex:self.eventMessages.count - 1];
                }
                [self.eventConversationDelegate reloadUIForEventMessages:self.eventMessages];
        }];
    }];
}


//- (void)mediaPickerControllerDidCancel:( *)controller {
//    [self.eventConversationDelegate dismissView];
//}

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
    
    self.moviePlayer = [[MPMoviePlayerController alloc] init];
    self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;

    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    [self.moviePlayer setControlStyle: MPMovieControlStyleNone];
    self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    self.moviePlayer.shouldAutoplay = NO;
    self.moviePlayer.view.frame = self.frame;
    [self.moviePlayer prepareToPlay];
    [self.contentView addSubview:self.moviePlayer.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerLoadStateChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:self.moviePlayer];
    
    self.thumbnailImageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    
    [self.contentView addSubview:self.thumbnailImageView];
    
    self.thumbnailImageView2 = [[UIImageView alloc] initWithFrame:self.frame];
    self.thumbnailImageView2.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView2.clipsToBounds = YES;
    [self.moviePlayer.backgroundView addSubview:self.thumbnailImageView2];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, self.frame.size.width, 40)];
    self.label.font = [FontProperties mediumFont:17.0f];
    self.label.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor whiteColor];
    self.label.hidden = YES;
    [self.contentView addSubview:self.label];
    [self.contentView bringSubviewToFront:self.label];
    
    self.focusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 110, self.frame.size.width, self.frame.size.height - 220)];
    self.focusButton.backgroundColor = UIColor.clearColor;
    [self.focusButton addTarget:self action:@selector(focusOnContent) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.focusButton];
    [self.contentView bringSubviewToFront:self.focusButton];
}

- (void) moviePlayerLoadStateChanged:(NSNotification*)notification {
    if (self.moviePlayer.loadState == MPMovieLoadStatePlayable || self.moviePlayer.loadState == MPMovieLoadStatePlaythroughOK) {
        [self performBlock:^{
            self.thumbnailImageView.alpha = 0.0;
        } afterDelay:0.1];
    } else if (self.moviePlayer.loadState == MPMovieLoadStateUnknown) {
        // [self.moviePlayer.view removeFromSuperview];
        self.thumbnailImageView.alpha = 1.0;
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
    
    self.cameraAccessImageView = [[UIImageView alloc] initWithFrame:CGRectMake(25, 250, 224, 192)];
    self.cameraAccessImageView.image = [UIImage imageNamed:@"cameraRoll"];
    self.cameraAccessImageView.hidden = YES;
    [self.contentView addSubview:self.cameraAccessImageView];
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
    
    self.focusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 110, self.frame.size.width, self.frame.size.height - 220)];
    self.focusButton.backgroundColor = UIColor.clearColor;
    [self.focusButton addTarget:self action:@selector(focusOnContent) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.focusButton];
    [self.contentView bringSubviewToFront:self.focusButton];

}


@end

@implementation MediaCell

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
    
    NSNumber *vote = self.eventMessage.vote;
        if (!self.numberOfVotesLabel) {
            self.numberOfVotesLabel = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 42, self.frame.size.height - 75, 32, 30)];
            self.numberOfVotesLabel.textColor = UIColor.whiteColor;
            self.numberOfVotesLabel.textAlignment = NSTextAlignmentCenter;
            self.numberOfVotesLabel.font = [FontProperties mediumFont:18.0f];
            self.numberOfVotesLabel.layer.shadowOpacity = 1.0f;
            self.numberOfVotesLabel.layer.shadowColor = UIColor.blackColor.CGColor;
            self.numberOfVotesLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
            self.numberOfVotesLabel.layer.shadowRadius = 0.5;
            [self.contentView addSubview:self.numberOfVotesLabel];
        }
        int votes = [self.eventMessage.upVotes intValue] - [self.eventMessage.downVotes intValue];
        self.numberOfVotesLabel.text = [[NSNumber numberWithInt:votes] stringValue];

        if (!self.upVoteButton) {
            self.upVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 56, self.frame.size.height - 118, 56, 52)];
            self.upvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 10, 32, 32)];
            [self.upVoteButton addSubview:self.upvoteImageView];
            [self.upVoteButton addTarget:self action:@selector(upvotePressed:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:self.upVoteButton];
        
        }
        if (!self.downVoteButton) {
            self.downVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 56, self.frame.size.height - 52, 56, 52)];
            self.downvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 10, 32, 32)];
            [self.downVoteButton addSubview:self.downvoteImageView];
            [self.contentView addSubview:self.downVoteButton];
            
            if (self.isPeeking) {
                self.downVoteButton.alpha = 0.2;
            } else {
                [self.downVoteButton addTarget:self action:@selector(downvotePressed:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        if ([vote intValue] == 1) self.upvoteImageView.image = [UIImage imageNamed:@"upvoteFilled"];
        else self.upvoteImageView.image = [UIImage imageNamed:@"upvote"];
        if ([vote intValue] == -1) self.downvoteImageView.image = [UIImage imageNamed:@"downvoteFilled"];
        else self.downvoteImageView.image = [UIImage imageNamed:@"downvote"];
        
        [self showVotes];
    
}

- (void)upvotePressed:(id)sender {
    NSNumber *vote = [self.eventMessage objectForKey:@"vote"];
    if (vote != nil) {
        return;
    }
    if ([self.eventMessage objectForKey:@"id"] == nil) {
        return;
    }
    
    [WGAnalytics tagEvent:@"Up Vote Tapped"];
    
    CGAffineTransform currentTransform = self.upVoteButton.transform;
    
    [UIView animateWithDuration:0.2f
                     animations:^{
                         self.upvoteImageView.image = [UIImage imageNamed:@"upvoteFilled"];
                         self.upVoteButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2f
                                          animations:^{
                                              self.upVoteButton.transform = currentTransform;
                                              
                                          } completion:^(BOOL finished) {
                                              [self updateNumberOfVotes:YES];
                                          }];
                     }];
}

- (void)downvotePressed:(id)sender {
    
    NSNumber *vote = [self.eventMessage objectForKey:@"vote"];
    if (vote != nil) {
        return;
    }
    if ([self.eventMessage objectForKey:@"id"] == nil) {
        return;
    }
    
    
    [WGAnalytics tagEvent:@"Down Vote Tapped"];
    
    
    CGAffineTransform currentTransform = self.downVoteButton.transform;
    
    [UIView animateWithDuration:0.2f
                     animations:^{
                         self.downvoteImageView.image = [UIImage imageNamed:@"downvoteFilled"];
                         self.downVoteButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2f
                                          animations:^{
                                              self.downVoteButton.transform = currentTransform;
                                              
                                          } completion:^(BOOL finished) {
                                              [self updateNumberOfVotes: NO];
                                          }];
                     }];

}

- (void)hideVotes {
    self.upVoteButton.hidden = YES;
    self.upVoteButton.enabled = NO;
    self.numberOfVotesLabel.hidden = YES;
}

- (void)showVotes {
    self.upVoteButton.hidden = NO;
    self.upVoteButton.enabled = YES;
    self.numberOfVotesLabel.hidden = NO;
}

- (void)updateNumberOfVotes:(BOOL)upvoteBool {
    NSNumber *votedUpNumber = [self.eventMessage objectForKey:@"vote"];
    if (!votedUpNumber) {
        if (!upvoteBool) {
            self.eventMessage.vote = @-1;
            self.eventMessage.downVotes = @([self.eventMessage.downVotes intValue] + 1);
        } else {
            self.eventMessage.vote = @1;
            self.eventMessage.upVotes = @([self.eventMessage.upVotes intValue] + 1);
        }
        [self updateUI];
        [self sendVote:upvoteBool];
    }
    [self.mediaScrollDelegate updateEventMessage:self.eventMessage forCell:self];
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

    self.controller = [[UIImagePickerController alloc] init];
    self.controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.controller.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    self.controller.delegate = self;
    self.controller.showsCameraControls = NO;
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat cameraWidth = screenWidth;
    CGFloat cameraHeight = floor((4/3.0f) * cameraWidth);
    CGFloat scale = screenHeight / cameraHeight;
    CGFloat delta = screenHeight - cameraHeight;
    CGFloat yAdjust = delta / 2.0;
    
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, yAdjust); //This slots the preview exactly in the middle of the screen
    self.controller.cameraViewTransform = CGAffineTransformScale(translate, scale, scale);
    
    self.controller.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
    [self.contentView addSubview:self.controller.view];

    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.controller.cameraOverlayView = overlayView;
    
    self.pictureButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 110, 100, 100)];
    [self.pictureButton setImage:[UIImage imageNamed:@"captureCamera"] forState:UIControlStateNormal];
    self.pictureButton.center = CGPointMake(overlayView.center.x, self.pictureButton.center.y);
    [self.pictureButton addTarget:self.controller action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:self.pictureButton];
    
    self.flashButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.flashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
    [self.flashButton addTarget:self action:@selector(changeFlash) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:self.flashButton];
    
    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 100, 0, 100, 100)];
    [self.switchButton setImage:[UIImage imageNamed:@"cameraIcon"] forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:self.switchButton];
    
    self.dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 100, 100, 100)];
    [self.dismissButton setImage:[UIImage imageNamed:@"cancelCamera"] forState:UIControlStateNormal];
    [self.dismissButton addTarget:self action:@selector(dismissPressed) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:self.dismissButton];
    
    self.previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.previewImageView.hidden = YES;
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    [overlayView addSubview:self.previewImageView];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    self.tapRecognizer.delegate = self;
    [self.previewImageView addGestureRecognizer:self.tapRecognizer];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    self.panRecognizer.delegate = self;
    self.panRecognizer.enabled = NO;
    [self addGestureRecognizer:self.panRecognizer];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 100, 100, 100)];
    [self.cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setTitle:@"< Cancel" forState:UIControlStateNormal];
    self.cancelButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.cancelButton.hidden = YES;
    self.cancelButton.enabled = NO;
    [overlayView addSubview:self.cancelButton];
    
    self.postButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, [UIScreen mainScreen].bounds.size.height - 100, 100, 100)];
    [self.postButton addTarget:self action:@selector(postPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.postButton setTitle:@"Post >" forState:UIControlStateNormal];
    self.postButton.hidden = YES;
    self.postButton.enabled = NO;
    self.postButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [overlayView addSubview:self.postButton];
    
    self.textField = [UITextField new];
    self.textField.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.textField.textColor = UIColor.whiteColor;
    self.textField.textAlignment = NSTextAlignmentCenter;
    self.textField.font = [FontProperties mediumFont:17.0f];
    self.textField.delegate = self;
    self.textField.returnKeyType = UIReturnKeyDone;
    [self.previewImageView addSubview:self.textField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    
    self.textLabel = [UILabel new];
    self.textLabel.hidden = YES;
    self.textLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.textLabel.textColor = UIColor.whiteColor;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.font = [FontProperties mediumFont:17.0f];
    [self.previewImageView addSubview:self.textLabel];
}

- (void)changeFlash {
    if (self.controller.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        [self.flashButton setImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
        self.controller.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
    }
    else {
        [self.flashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
        self.controller.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    }
}

- (void)switchCamera {
    [UIView animateWithDuration:.15f animations:^{
        self.switchButton.transform = CGAffineTransformMakeScale(1.5,1.5);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.15f animations:^{
            self.switchButton.transform = CGAffineTransformMakeScale(1.0,1.0);
        }];
    }];

    if (self.controller.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
        self.controller.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    else {
        self.controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
}

- (void)dismissPressed {
    [self.mediaScrollDelegate dismissView];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
    UIImage *image =  (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
    if (self.controller.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
        UIImage *newImage = [UIImage imageWithCGImage:[image CGImage]
                                                scale:image.scale
                                          orientation:UIImageOrientationLeftMirrored];
        [newInfo setObject:newImage forKey:UIImagePickerControllerOriginalImage];
    }
    self.info = [[NSDictionary alloc] initWithDictionary:newInfo];
    
    self.dismissButton.hidden = YES;
    self.dismissButton.enabled = NO;
    self.pictureButton.hidden = YES;
    self.pictureButton.enabled = NO;
    self.flashButton.hidden = YES;
    self.flashButton.enabled = NO;
    self.switchButton.hidden = YES;
    self.switchButton.enabled = NO;
    
    self.previewImageView.hidden = NO;
    self.previewImageView.userInteractionEnabled = YES;
    self.previewImageView.image = (UIImage *) [self.info objectForKey: UIImagePickerControllerOriginalImage];
    self.postButton.hidden = NO;
    self.postButton.enabled = YES;
    self.cancelButton.hidden = NO;
    self.cancelButton.enabled = YES;
    self.panRecognizer.enabled = NO;
}

- (void)cancelPressed {
    [self cleanupView];
    self.info = nil;
}


- (void)cleanupView {
    self.dismissButton.hidden = NO;
    self.dismissButton.enabled = YES;
    self.pictureButton.hidden = NO;
    self.pictureButton.enabled = YES;
    self.flashButton.hidden = NO;
    self.flashButton.enabled = YES;
    self.switchButton.hidden = NO;
    self.switchButton.enabled = YES;
    
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
    
    [self cleanupView];
    [self.mediaScrollDelegate mediaPickerController:self.controller
                             didFinishMediaWithInfo:newInfo];

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


- (void)tapGestureRecognizer:(UIGestureRecognizer*)recognizer {
    if (!self.previewImageView.isHidden) {
        CGPoint center = [recognizer locationInView:self];
        float heightScreen = [UIScreen mainScreen].bounds.size.height;
        float widthScreen = [UIScreen mainScreen].bounds.size.width;
        self.percentPoint = CGPointMake(1 - (center.x/widthScreen), center.y/heightScreen);
        self.percentPoint = CGPointMake(self.percentPoint.x, MIN(MAX(self.percentPoint.y, 125/[UIScreen mainScreen].bounds.size.height), 1 - (158/[UIScreen mainScreen].bounds.size.height)));
        NSLog(@"center.x %f, center.y: %f,  percent point %f", center.x, center.y,  self.percentPoint.y);
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
