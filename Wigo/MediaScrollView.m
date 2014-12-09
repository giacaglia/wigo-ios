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
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:indexPath.row];
    NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
    NSString *contentURL = [eventMessage objectForKey:@"media"];
    if ([mimeType isEqualToString:kCameraType]) {
        CameraCell *cameraCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CameraCell" forIndexPath: indexPath];
        [cameraCell setControllerDelegate:self];
        NSArray *arrayViewContollers = (NSArray *)cameraCell.controller.viewControllers;
        if (arrayViewContollers.count > 0) {
            IQMediaCaptureController *captureController = (IQMediaCaptureController *)arrayViewContollers[0];
            captureController.startXPoint = (self.eventMessages.count - 1) * 320;
        }
        [self.pageViews setObject:cameraCell.controller atIndexedSubscript:indexPath.row];
        return cameraCell;
    }
    else if ([mimeType isEqualToString:kImageEventType]) {
        ImageCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath: indexPath];
        myCell.mediaScrollDelegate = self;
        myCell.eventMessage = eventMessage;
        [myCell updateUI];
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.frame = CGRectMake(myCell.imageView.frame.size.width/4, myCell.imageView.frame.size.height/4, myCell.imageView.frame.size.width/2,  myCell.imageView.frame.size.height/2);
        [spinner startAnimating];
        [myCell.imageView setImageWithURL:imageURL
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                    [spinner stopAnimating];
        }];
        [self.pageViews setObject:myCell.imageView atIndexedSubscript:indexPath.row];
        return myCell;
    }
    else {
        VideoCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath: indexPath];
        myCell.mediaScrollDelegate = self;
        myCell.eventMessage = eventMessage;
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
                                } withOptions:[self.eventMessagesIDSet allObjects]];
    }
    [self.storyDelegate readEventMessageIDArray:[self.eventMessagesIDSet allObjects]];
}



-(void)scrolledToPage:(int)page {
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
        for (int i = 0 ; i < self.eventMessages.count; i++) {
            [self.pageViews addObject:[NSNull null]];
        }
    }
    [self addReadPage:page];

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
    NSMutableDictionary *eventMessage = [NSMutableDictionary dictionaryWithDictionary:[self.eventMessages objectAtIndex:page]];
    if ([[eventMessage allKeys] containsObject:@"id"] && [[eventMessage allKeys] containsObject:@"is_read"] && ![[eventMessage objectForKey:@"is_read"] boolValue]) {
        [self.eventMessagesIDSet addObject:[eventMessage objectForKey:@"id"]];
        [eventMessage setValue:@YES forKey:@"is_read"];
        [self.eventMessages replaceObjectAtIndex:page withObject:eventMessage];
    }
}

- (void)removeMediaAtPage:(int)page {
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:page];
    NSNumber *eventMessageID = [eventMessage objectForKey:@"id"];
    [Network sendAsynchronousHTTPMethod:DELETE withAPIName:[NSString stringWithFormat:@"eventmessages/%@", eventMessageID] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
    }];
}

#pragma mark - MediaScrollViewDelegate 

- (void)focusOnContent {
    [self.eventConversationDelegate focusOnContent];
}

#pragma mark - IQMediaPickerController Delegate methods

- (void)mediaPickerController:(IQMediaPickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info {
    [self.eventConversationDelegate addLoadingBanner];
    NSDictionary *options;
    NSString *type = @"";
    if ([[info allKeys] containsObject:IQMediaTypeImage]) {
        UIImage *image = [[[info objectForKey:IQMediaTypeImage] objectAtIndex:0] objectForKey:IQMediaImage];
        NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
        type = kImageEventType;
        if ([[info allKeys] containsObject:IQMediaTypeText]) {
            NSString *text = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaText];
            NSNumber *yPosition = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaYPosition];
            NSDictionary *properties = @{@"yPosition": yPosition};
            options =  @{
                         @"event": [self.event eventID],
                         @"message": text,
                         @"properties": properties,
                         @"media_mime_type": type
                         };
        }
        else {
            options =  @{
                         @"event": [self.event eventID],
                         @"media_mime_type": type
                         };
        }
        [self uploadContentWithFile:fileData
                        andFileName:@"image0.jpg"
                         andOptions:options];
        
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
                                                                             NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:self.eventMessages];
                                                                             [mutableEventMessages replaceObjectAtIndex:(self.eventMessages.count - 1) withObject:jsonResponse];
                                                                             [self.eventConversationDelegate reloadUIForEventMessages:mutableEventMessages];
                                                                             [self.eventConversationDelegate showCompletedMessage];
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
    self.itemSize = CGSizeMake(320, 568);
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
    self.frame = CGRectMake(0, 0, 320, 568);
    self.backgroundColor = UIColor.clearColor;
    
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
    self.frame = CGRectMake(0, 0, 320, 568);
    self.backgroundColor = UIColor.clearColor;
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];
    
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
    
    NSNumber *vote = [self.eventMessage objectForKey:@"vote"];
        if (!self.numberOfVotesLabel) {
            self.numberOfVotesLabel = [[UILabel alloc] initWithFrame:CGRectMake(320 - 46, self.frame.size.height - 75, 32, 30)];
            self.numberOfVotesLabel.textColor = [UIColor whiteColor];
            self.numberOfVotesLabel.textAlignment = NSTextAlignmentCenter;
            self.numberOfVotesLabel.font = [FontProperties mediumFont:18.0f];
            [self.contentView addSubview:self.numberOfVotesLabel];
        }
        int votes = [[self.eventMessage objectForKey:@"up_votes"] intValue] - [[self.eventMessage objectForKey:@"down_votes"] intValue];
        self.numberOfVotesLabel.text = [[NSNumber numberWithInt:votes] stringValue];
        
        if (!self.upVoteButton) {
            self.upVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 56, self.frame.size.height - 118, 56, 52)];
            self.upvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 32, 32)];
            [self.upVoteButton addSubview:self.upvoteImageView];
            [self.upVoteButton addTarget:self action:@selector(upvotePressed:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:self.upVoteButton];
        }
        if (!self.downVoteButton) {
            self.downVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 56, self.frame.size.height - 52, 56, 52)];
            self.downvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 32, 32)];
                       [self.downVoteButton addSubview:self.downvoteImageView];
            [self.downVoteButton addTarget:self action:@selector(downvotePressed:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:self.downVoteButton];
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
    [self updateNumberOfVotes:YES];
}

- (void)downvotePressed:(id)sender {
    [self updateNumberOfVotes:NO];
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
            downVotes = @([downVotes intValue] + 1);
            [mutableEventMessage setObject:downVotes forKey:@"down_votes"];
            self.eventMessage = [NSDictionary dictionaryWithDictionary:mutableEventMessage];
            [self updateUI];
            [self sendVote:upvoteBool];
        }
        else {
            NSMutableDictionary *mutableEventMessage = [NSMutableDictionary dictionaryWithDictionary:self.eventMessage];
            [mutableEventMessage setObject:@1 forKey:@"vote"];
            NSNumber *upVotes = [mutableEventMessage objectForKey:@"up_votes"];
            upVotes = @([upVotes intValue] + 1);
            [mutableEventMessage setObject:upVotes forKey:@"up_votes"];
            self.eventMessage = [NSDictionary dictionaryWithDictionary:mutableEventMessage];
            [self updateUI];
            [self sendVote:upvoteBool];
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
    self.frame = CGRectMake(0, 0, 320, 568);
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
