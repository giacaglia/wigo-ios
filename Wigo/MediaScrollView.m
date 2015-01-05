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
#import "IQMediaCaptureController.h"
#import "AWSUploader.h"

@interface MediaScrollView() {}
@property (nonatomic, strong) NSMutableArray *pageViews;

@property (nonatomic, strong) MPMoviePlayerController *lastMoviePlayer;
@property (nonatomic, strong) NSMutableDictionary *thumbnails;

@property (nonatomic, strong) UIView *chatTextFieldWrapper;
@property (nonatomic, strong) UILabel *addYourVerseLabel;
@property (nonatomic, strong) NSMutableSet *eventMessagesIDSet;
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
    if (self.index) {
        self.minPage = [self.index intValue];
        self.maxPage = [self.index intValue];
    }
    else {
        self.minPage = 0;
        self.maxPage = 0;
    }
    
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
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:indexPath.row];
    NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
    NSString *contentURL = [eventMessage objectForKey:@"media"];
    if ([mimeType isEqualToString:kCameraType]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusDenied) {
            PromptCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PromptCell" forIndexPath: indexPath];
            [myCell.imageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL] ]];
             myCell.titleTextLabel.frame = CGRectMake(15, 160, self.frame.size.width - 30, 60);
            myCell.titleTextLabel.text = @"Please Give WiGo an access to camera to add to the story:";
            myCell.avoidAction.hidden = YES;
            myCell.cameraAccessImageView.hidden = NO;
            myCell.isPeeking = self.isPeeking;

            return myCell;
        }
        else {
            CameraCell *cameraCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CameraCell" forIndexPath: indexPath];
            [cameraCell setControllerDelegate:self];
            NSArray *arrayViewContollers = (NSArray *)cameraCell.controller.viewControllers;
            if (arrayViewContollers.count > 0) {
                IQMediaCaptureController *captureController = (IQMediaCaptureController *)arrayViewContollers[0];
                captureController.startXPoint = (self.eventMessages.count - 1) * [[UIScreen mainScreen] bounds].size.width;
            }
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
        NSURL *imageURL;
        if ([contentURL isKindOfClass:[UIImage class]]) {
            myCell.imageView.image = (UIImage *)contentURL;
        }
        else {
            imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
            [myCell.spinner startAnimating];
            __weak ImageCell *weakCell = myCell;
            [myCell.imageView setImageWithURL:imageURL
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [weakCell.spinner stopAnimating];
                                        });
                                    }];

        }
        [self.pageViews setObject:myCell.imageView atIndexedSubscript:indexPath.row];
        
        return myCell;
    }
    else if ([mimeType isEqualToString:kFaceImage]) {
        PromptCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PromptCell" forIndexPath: indexPath];
        [myCell.imageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL] ]];
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
        [myCell.imageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL] ]];
        myCell.titleTextLabel.text = @"To add a highlight you must be going here.";
        myCell.avoidAction.hidden = YES;
        myCell.isPeeking = self.isPeeking;
        return myCell;
    }
    else {
        VideoCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath: indexPath];
        myCell.mediaScrollDelegate = self;
        myCell.eventMessage = eventMessage;
        myCell.isPeeking = self.isPeeking;

        [myCell updateUI];
        NSString *thumbnailURL = [eventMessage objectForKey:@"thumbnail"];
        if (![thumbnailURL isKindOfClass:[NSNull class]]) {
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], thumbnailURL]];
            [myCell.thumbnailImageView setImageWithURL:imageURL];
        }
        NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
        myCell.moviePlayer.contentURL = videoURL;
        [self.pageViews setObject:myCell.moviePlayer atIndexedSubscript:indexPath.row];
        return myCell;
    }
}

- (void)updateEventMessage:(NSDictionary *)eventMessage forCell:(UICollectionViewCell *)cell {
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
    if (self.eventMessagesIDSet.count > 0) {
        [Network sendAsynchronousHTTPMethod:POST
                                withAPIName:[NSString stringWithFormat:@"events/%@/messages/read/", [self.event eventID]]
                                withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                    if (!error) {
                                        NSLog(@"json response %@", jsonResponse);
                                    }
                                    else {
                                        NSLog(@"error %@", error);
                                    }
                                } withOptions:(id)[self.eventMessagesIDSet allObjects]];
    }
    [self.storyDelegate readEventMessageIDArray:[self.eventMessagesIDSet allObjects]];
}

- (void)dismissView {
    [self.eventConversationDelegate dismissView];
}

- (void)promptCamera {
    [self.eventConversationDelegate promptCamera];
}


-(void)scrolledToPage:(int)page {
    if (page < self.minPage) self.minPage = page;
    if (page > self.maxPage) self.maxPage = page;
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
        for (int i = 0 ; i < self.eventMessages.count; i++) {
            [self.pageViews addObject:[NSNull null]];
        }
    }

    [self performBlock:^(void){[self playVideoAtPage:page];}
            afterDelay:0.5
 cancelPreviousRequest:YES];
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
    if (!self.eventMessagesIDSet) {
        self.eventMessagesIDSet = [NSMutableSet new];
    }
    if ((int)page < self.eventMessages.count) {
        NSMutableDictionary *eventMessage = [NSMutableDictionary dictionaryWithDictionary:[self.eventMessages objectAtIndex:page]];
        if ([[eventMessage allKeys] containsObject:@"id"] && [[eventMessage allKeys] containsObject:@"is_read"] && ![[eventMessage objectForKey:@"is_read"] boolValue]) {
            [self.eventMessagesIDSet addObject:[eventMessage objectForKey:@"id"]];
            [eventMessage setValue:@YES forKey:@"is_read"];
            [self.eventMessages replaceObjectAtIndex:page withObject:eventMessage];
        }
    }
  
}

- (void)removeMediaAtPage:(int)page {
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:page];
    if ([[eventMessage allKeys] containsObject:@"id"]) {
        NSNumber *eventMessageID = [eventMessage objectForKey:@"id"];
        [Network sendAsynchronousHTTPMethod:DELETE withAPIName:[NSString stringWithFormat:@"eventmessages/%@", eventMessageID] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            NSLog(@"jsonREsponse:%@, error %@", jsonResponse,error);
        }];
    }
 }

#pragma mark - MediaScrollViewDelegate 

- (void)focusOnContent {
    [self.eventConversationDelegate focusOnContent];
}

#pragma mark - IQMediaPickerController Delegate methods

- (void)mediaPickerController:(IQMediaPickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info {
    [self.eventConversationDelegate addLoadingBanner];
    NSString *type = @"";
    
    UIImage *zoomedImage;
    if ([[info allKeys] containsObject:IQMediaTypeImage]) {
        UIImage *image = [[[info objectForKey:IQMediaTypeImage] objectAtIndex:0] objectForKey:IQMediaImage];
        
        IQMediaCaptureController *captureController = [controller.viewControllers objectAtIndex: 0];
        
        float scaleFactor = [captureController effectiveScale];
        
        UIImage *resizedImage = [self imageWithImage: image scaledToSize: CGSizeMake(image.size.width*scaleFactor, image.size.height*scaleFactor)];
        
        CGRect cropRect = CGRectMake(resizedImage.size.width/2 - image.size.width/2, resizedImage.size.height/2 - image.size.height/2, image.size.width, image.size.height);
        
        zoomedImage = [self getSubImageFrom: resizedImage WithRect: cropRect];

        NSData *fileData = UIImageJPEGRepresentation(zoomedImage, 1.0);
        type = kImageEventType;
        if ([[info allKeys] containsObject:IQMediaTypeText]) {
            NSString *text = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaText];
            NSNumber *yPosition = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaYPosition];
            NSDictionary *properties = @{@"yPosition": yPosition};
            self.options =  @{
                         @"event": [self.event eventID],
                         @"message": text,
                         @"properties": properties,
                         @"media_mime_type": type
                         };
        }
        else {
            self.options =  @{
                         @"event": [self.event eventID],
                         @"media_mime_type": type
                         };
        }
        [self uploadContentWithFile:fileData
                        andFileName:@"image0.jpg"
                         andOptions:self.options];
        
    }
    
    else if ( [[info allKeys] containsObject:@"IQMediaTypeVideo"]) {
        type = kVideoEventType;
        NSURL *videoURL = [[[info objectForKey:@"IQMediaTypeVideo"] objectAtIndex:0] objectForKey:@"IQMediaURL"];
        self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(thumbnailGenerated:)
                                                     name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                   object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishPlaying:)
                                                     name:MPMoviePlayerLoadStateDidChangeNotification
                                                   object:self.moviePlayer];
        [self.moviePlayer requestThumbnailImagesAtTimes:@[@0.0f] timeOption:MPMovieTimeOptionNearestKeyFrame];
        
        NSError *error;
        self.fileData = [NSData dataWithContentsOfURL: videoURL options: NSDataReadingMappedIfSafe error: &error];
        
        if ([[info allKeys] containsObject:IQMediaTypeText]) {
            NSString *text = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaText];
            NSNumber *yPosition = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaYPosition];
            NSDictionary *properties = @{@"yPosition": yPosition};
            self.options =  @{
                              @"event": [self.event eventID],
                              @"message": text,
                              @"properties": properties,
                              @"media_mime_type": type
                              };
        }
        else {
            self.options =  @{
                              @"event": [self.event eventID],
                              @"media_mime_type": type
                              };
        }
        
    }
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:self.options];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    if ([[info allKeys] containsObject:IQMediaTypeImage]) {
        [mutableDict addEntriesFromDictionary:@{
                                                @"user": [[Profile user] dictionary],
                                                @"created": [dateFormatter stringFromDate:[NSDate date]],
                                                @"media": zoomedImage
                                                }];
    }
    else if ( [[info allKeys] containsObject:IQMediaTypeVideo]) {
            [mutableDict addEntriesFromDictionary:@{
                                                    @"user": [[Profile user] dictionary],
                                                    @"created": [dateFormatter stringFromDate:[NSDate date]],
                                                    @"media": [[[info objectForKey:IQMediaTypeVideo] objectAtIndex:0] objectForKey:IQMediaImage],
                                                               }];
    }
    
    if (!self.shownCurrentImage) {
        NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:self.eventMessages];
        [mutableEventMessages replaceObjectAtIndex:(self.eventMessages.count - 1)  withObject:mutableDict];
        [self.eventConversationDelegate reloadUIForEventMessages:mutableEventMessages];
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
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:[NSString stringWithFormat: @"uploads/photos/?filename=%@", filename]
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSArray *fields = [jsonResponse objectForKey:@"fields"];
                                    NSString *actionString = [jsonResponse objectForKey:@"action"];
                                    [AWSUploader uploadFields:fields
                                                withActionURL:actionString
                                                     withFile:fileData
                                                  andFileName:filename
                                     withCompletion:^{
                                         NSDictionary *eventMessageOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
                                         [eventMessageOptions setValue:[AWSUploader valueOfFieldWithName:@"key" ofDictionary:fields] forKey:@"media"];
                                         [Network sendAsynchronousHTTPMethod:POST
                                                                 withAPIName:@"eventmessages/"
                                                                 withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [self.eventConversationDelegate showErrorMessage];
                }
                else {
                    [self.eventConversationDelegate showCompletedMessage];
                    self.shownCurrentImage = YES;
                    NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:self.eventMessages];
                    [mutableEventMessages replaceObjectAtIndex:(self.eventMessages.count - 1) withObject:jsonResponse];
                    if (self.shownCurrentImage) {
                        [mutableEventMessages removeLastObject];
                    }
                    [self.eventConversationDelegate reloadUIForEventMessages:mutableEventMessages];

                }
            });
                                                                 } withOptions:[NSDictionary dictionaryWithDictionary:eventMessageOptions]];
                                     }];
                                    
                                });
                                
                            }];
}

- (void)uploadVideo:(NSData *)fileData
      withVideoName:(NSString *)filename
        andThumnail:(NSData *)thumbnailData
    andThumnailName:(NSString *)thumnailFilename
         andOptions:(NSDictionary *)options
{
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:[NSString stringWithFormat: @"uploads/videos/?filename=%@", filename]
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSDictionary *videoDictionary = [jsonResponse objectForKey:@"video"];
                                    NSArray *videoFields = [videoDictionary objectForKey:@"fields"];
                                    NSString *videoActionString = [videoDictionary objectForKey:@"action"];
                                    
                                    [AWSUploader uploadFields:videoFields
                                                withActionURL:videoActionString
                                                     withFile:fileData
                                                  andFileName:filename
                                               withCompletion:^{
                                                   NSDictionary *thumbnailDictionary = [jsonResponse objectForKey:@"thumbnail"];
                                                   NSArray *fields = [thumbnailDictionary objectForKey:@"fields"];
                                                   NSString *actionString = [thumbnailDictionary objectForKey:@"action"];
                                                   [AWSUploader uploadFields:fields
                                                               withActionURL:actionString
                                                                    withFile:thumbnailData
                                                                 andFileName:thumnailFilename];
                                                   
                                                   NSDictionary *eventMessageOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
                                                   [eventMessageOptions setValue:[AWSUploader valueOfFieldWithName:@"key" ofDictionary:videoFields] forKey:@"media"];
                                                   [eventMessageOptions setValue:[AWSUploader valueOfFieldWithName:@"key" ofDictionary:fields] forKey:@"thumbnail"];
                                                   [Network sendAsynchronousHTTPMethod:POST
                                                                           withAPIName:@"eventmessages/"
                                                                           withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                                                               if (!error) {
                                                                                   NSLog(@"fjahefi Response: %@", jsonResponse);

                                                                               }
                                                                               else {
                                                                                   NSLog(@"jerhj error: %@", error);
                                                                               }
                                                                           } withOptions:[NSDictionary dictionaryWithDictionary:eventMessageOptions]];
                                               }];
                                });
                            }];
}


- (void)mediaPickerControllerDidCancel:(IQMediaPickerController *)controller {
    [self.eventConversationDelegate dismissView];
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
    
    self.moviePlayer = [[MPMoviePlayerController alloc] init];
    self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    [self.moviePlayer setControlStyle: MPMovieControlStyleNone];
    self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    self.moviePlayer.shouldAutoplay = NO;
    [self.moviePlayer prepareToPlay];
    self.moviePlayer.view.frame = self.frame;
    [self.contentView addSubview:self.moviePlayer.view];
    
    self.thumbnailImageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.frame];
    backgroundImageView.image = [UIImage imageNamed:@"storyBackground"];
    [self.thumbnailImageView addSubview:backgroundImageView];
    [self.moviePlayer.backgroundView addSubview:self.thumbnailImageView];
    
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
    if ([[self.eventMessage allKeys] containsObject:@"message"]) {
        NSString *message = [self.eventMessage objectForKey:@"message"];
        if (message && [message isKindOfClass:[NSString class]]) {
            self.label.hidden = NO;
            self.label.text = message;
        }
        else self.label.hidden = YES;
        if ([[self.eventMessage allKeys] containsObject:@"properties"]) {
            NSDictionary *properties = [self.eventMessage objectForKey:@"properties"];
            if (properties &&
                [properties isKindOfClass:[NSDictionary class]] &&
                [[properties allKeys] containsObject:@"yPosition"]) {
                NSNumber *yPosition = [properties objectForKey:@"yPosition"];
                self.label.frame = CGRectMake(0, [yPosition intValue], self.frame.size.width, 40);
            }
        }
    }
    else self.label.hidden = YES;
    
    NSNumber *vote = [self.eventMessage objectForKey:@"vote"];
        if (!self.numberOfVotesLabel) {
            self.numberOfVotesLabel = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 46, self.frame.size.height - 75, 32, 30)];
            self.numberOfVotesLabel.textColor = UIColor.whiteColor;
            self.numberOfVotesLabel.textAlignment = NSTextAlignmentCenter;
            self.numberOfVotesLabel.font = [FontProperties mediumFont:18.0f];
            self.numberOfVotesLabel.layer.shadowOpacity = 1.0f;
            self.numberOfVotesLabel.layer.shadowColor = UIColor.blackColor.CGColor;
            self.numberOfVotesLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
            self.numberOfVotesLabel.layer.shadowRadius = 0.5;
            [self.contentView addSubview:self.numberOfVotesLabel];
        }
        int votes = [[self.eventMessage objectForKey:@"up_votes"] intValue] - [[self.eventMessage objectForKey:@"down_votes"] intValue];
        self.numberOfVotesLabel.text = [[NSNumber numberWithInt:votes] stringValue];

        if (!self.upVoteButton) {
            self.upVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 56, self.frame.size.height - 118, 56, 52)];
            self.upvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 32, 32)];
            [self.upVoteButton addSubview:self.upvoteImageView];
            [self.contentView addSubview:self.upVoteButton];

            if (self.isPeeking) {
                self.upVoteButton.alpha = 0.2;
            } else {
                [self.upVoteButton addTarget:self action:@selector(upvotePressed:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        if (!self.downVoteButton) {
            self.downVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 56, self.frame.size.height - 52, 56, 52)];
            self.downvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 32, 32)];
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
    
//    else {
//        [self hideVotes];
//    }
    
}

- (void)upvotePressed:(id)sender {
    NSNumber *vote = [self.eventMessage objectForKey:@"vote"];
    if (vote != nil) {
        return;
    }
    
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
    self.downVoteButton.hidden = YES;
    self.downVoteButton.enabled = NO;
    self.numberOfVotesLabel.hidden = YES;
}

- (void)showVotes {
    self.upVoteButton.hidden = NO;
    self.upVoteButton.enabled = YES;
    self.downVoteButton.hidden = NO;
    self.downVoteButton.enabled = YES;
    self.numberOfVotesLabel.hidden = NO;
}

- (void)updateNumberOfVotes:(BOOL)upvoteBool {
    NSNumber *votedUpNumber = [self.eventMessage objectForKey:@"vote"];
    if (!votedUpNumber) {
        if (!upvoteBool) {
            NSMutableDictionary *mutableEventMessage = [NSMutableDictionary dictionaryWithDictionary:self.eventMessage];
            [mutableEventMessage setObject:@-1 forKey:@"vote"];
            NSNumber *downVotes = [mutableEventMessage objectForKey:@"down_votes"];
            if ([downVotes isKindOfClass:[NSNumber class]]) {
                downVotes = @([downVotes intValue] + 1);
                [mutableEventMessage setObject:downVotes forKey:@"down_votes"];
                self.eventMessage = [NSDictionary dictionaryWithDictionary:mutableEventMessage];
                [self updateUI];
                [self sendVote:upvoteBool];
            }
          
        }
        else {
            NSMutableDictionary *mutableEventMessage = [NSMutableDictionary dictionaryWithDictionary:self.eventMessage];
            [mutableEventMessage setObject:@1 forKey:@"vote"];
            NSNumber *upVotes = [mutableEventMessage objectForKey:@"up_votes"];
            if ([upVotes isKindOfClass:[NSNumber class]]) {
                upVotes = @([upVotes intValue] + 1);
                [mutableEventMessage setObject:upVotes forKey:@"up_votes"];
                self.eventMessage = [NSDictionary dictionaryWithDictionary:mutableEventMessage];
                [self updateUI];
                [self sendVote:upvoteBool];
            }
        }
    }
    [self.mediaScrollDelegate updateEventMessage:self.eventMessage forCell:self];
}


- (void)sendVote:(BOOL)upvoteBool {
    NSNumber *eventMessageID = [self.eventMessage objectForKey:@"id"];
    NSDictionary *options = @{@"message" : eventMessageID, @"up_vote": @(upvoteBool)};
    [Network sendAsynchronousHTTPMethod:POST withAPIName:@"eventmessagevotes/"
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                            }
                            withOptions:options];

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
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    self.backgroundColor = UIColor.clearColor;

    self.controller = [[IQMediaPickerController alloc] init];
    [self.controller setMediaType:IQMediaPickerControllerMediaTypePhoto];
    self.controller.view.frame = self.frame;
    [self.contentView addSubview:self.controller.view];
    
}

- (void)setControllerDelegate:(id)controllerDelegate {
    if (!self.controllerDelegateSet) {
        self.controller.delegate = controllerDelegate;
    }
    self.controllerDelegateSet = YES;
}


@end
