//
//  ImagesScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MediaScrollView.h"
#import "Globals.h"
#import <MediaPlayer/MediaPlayer.h>


@interface MediaScrollView() {}
@property (nonatomic, strong) NSMutableArray *pageViews;

@property (nonatomic, strong) MPMoviePlayerController *lastMoviePlayer;
@property (nonatomic, strong) NSMutableDictionary *thumbnails;
@property (nonatomic, assign) BOOL lastPageWasVideo;

@property (nonatomic, strong) UIView *chatTextFieldWrapper;
@property (nonatomic, strong) UILabel *addYourVerseLabel;
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    self.backgroundColor = RGB(23, 23, 23);
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.pagingEnabled = YES;
    self.dataSource = self;
    [self registerClass:[MediaCell class] forCellWithReuseIdentifier:@"MediaCell"];
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
    MediaCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCell" forIndexPath: indexPath];
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:indexPath.row];
    NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
    NSString *contentURL = [eventMessage objectForKey:@"media"];
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
    }
    if ([mimeType isEqualToString:@"new"]) {
        self.controller.view.frame = CGRectMake(0, 0, 320, self.superview.frame.size.height);
        [myCell.contentView addSubview:self.controller.view];
        [self.pageViews setObject:[NSNull null] atIndexedSubscript:indexPath.row];
    }
    else if ([mimeType isEqualToString:@"image/jpeg"]) {
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 640)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [imageView setImageWithURL:imageURL];
        [myCell.contentView addSubview:imageView];
        UILabel *labelInsideImage;
        if ([[eventMessage allKeys] containsObject:@"message"]) {
            NSString *message = [eventMessage objectForKey:@"message"];
            if (message && [message isKindOfClass:[NSString class]]) {
                labelInsideImage = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, imageView.frame.size.width, 50)];
                labelInsideImage.font = [FontProperties mediumFont:20.0f];
                labelInsideImage.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
                labelInsideImage.textAlignment = NSTextAlignmentCenter;
                labelInsideImage.text = message;
                labelInsideImage.textColor = [UIColor whiteColor];
                [imageView addSubview:labelInsideImage];
            }
        }
        if ([[eventMessage allKeys] containsObject:@"properties"]) {
            NSDictionary *properties = [eventMessage objectForKey:@"properties"];
            if (properties &&
                [properties isKindOfClass:[NSDictionary class]] &&
                [[properties allKeys] containsObject:@"yPosition"]) {
                NSNumber *yPosition = [properties objectForKey:@"yPosition"];
                labelInsideImage.frame = CGRectMake(0, [yPosition intValue], imageView.frame.size.width, 50);
            }
        }
//        [self.pageViews addObject:imageView];
        [self.pageViews setObject:imageView atIndexedSubscript:indexPath.row];
    }
        else {
            NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://wigo-uploads.s3.amazonaws.com/%@", contentURL]];

            MPMoviePlayerController *theMoviePlayer = [[MPMoviePlayerController alloc] init];

            theMoviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
            [theMoviePlayer setContentURL: videoURL];
            theMoviePlayer.scalingMode = MPMovieScalingModeAspectFill;
            [theMoviePlayer setControlStyle: MPMovieControlStyleNone];
            theMoviePlayer.repeatMode = MPMovieRepeatModeOne;
            theMoviePlayer.shouldAutoplay = NO;

            [theMoviePlayer play];
            [theMoviePlayer pause];
            UIView *videoView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, self.superview.frame.size.height)];

            videoView.backgroundColor = [UIColor clearColor];
            theMoviePlayer.view.frame = videoView.bounds;
            
//            [theMoviePlayer requestThumbnailImagesAtTimes: @[@0, @0.5, @1, @1.5] timeOption: MPMovieTimeOptionNearestKeyFrame];
//            [[NSNotificationCenter defaultCenter] addObserverForName: MPMoviePlayerThumbnailImageRequestDidFinishNotification object: theMoviePlayer queue: [NSOperationQueue new] usingBlock:^(NSNotification *note) {
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    MPMoviePlayerController *curentMoviePlayer = note.object;
//
//                    UIImage *thumb = [note.userInfo objectForKey: MPMoviePlayerThumbnailImageKey];
//
//                    if ([thumb isKindOfClass: [UIImage class]] && [self.thumbnails objectForKey: [NSString stringWithFormat: @"%i", i]] == nil) {
//                        NSLog(@"adding thumb ---> %i", i);
//                        UIImageView *imageView = [[UIImageView alloc] initWithImage: thumb];
//                        imageView.frame = curentMoviePlayer.backgroundView.bounds;
//                        imageView.clipsToBounds = YES;
//                        imageView.contentMode = UIViewContentModeScaleAspectFill;
//                        [curentMoviePlayer.view addSubview: imageView];
//                        [self.thumbnails setObject: imageView forKey: [NSString stringWithFormat: @"%i", i]];
//                    }
//                });
//                
//
//            }];
            
            [videoView addSubview: theMoviePlayer.view];
            [myCell.contentView bringSubviewToFront: theMoviePlayer.view];
            
            [myCell.contentView addSubview: videoView];
//            [self.pageViews addObject: theMoviePlayer];
            [self.pageViews setObject:theMoviePlayer atIndexedSubscript:indexPath.row];

        }

    return myCell;
}

- (void)closeView {
    if (self.lastMoviePlayer) {
        [self.lastMoviePlayer stop];
    }
}



-(void)scrolledToPage:(int)page {
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
        for (int i = 0 ; i < self.eventMessages.count; i++) {
            [self.pageViews addObject:[NSNull null]];
        }
    }
    MPMoviePlayerController *theMoviePlayer = [self.pageViews objectAtIndex:page];
    if ([theMoviePlayer isKindOfClass:[MPMoviePlayerController class]]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [theMoviePlayer play];
            
            //UIImageView *thumb = [self.thumbnails objectForKey: [NSString stringWithFormat: @"%i", page]];
            //thumb.hidden = YES;
        });

        self.lastMoviePlayer = theMoviePlayer;
        self.lastPageWasVideo = YES;
    } else {
        if (self.lastPageWasVideo && self.lastMoviePlayer) {
            if (self.lastMoviePlayer.playbackState == MPMusicPlaybackStatePlaying) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
//                    UIImageView *thumb = [self.thumbnails objectForKey: [NSString stringWithFormat: @"%i", page]];
//                    thumb.hidden = NO;
                    [self.lastMoviePlayer pause];

                });
            }
        }
    }
}
- (void)removeMediaAtPage:(int)page {
    UIView *player = [self.pageViews objectAtIndex:page];
    if ([player isKindOfClass:[MPMoviePlayerController class]])    {
    }
    else {
        [UIView animateWithDuration:0.4 animations:^{
            player.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [player removeFromSuperview];
        }];
    }
}


- (void)addViewForNewTextAtPage:(int)page {
    self.chatTextFieldWrapper = [[UIView alloc] initWithFrame:CGRectMake(page*320, self.frame.size.height - 50, self.frame.size.width, 60)];
    [self addSubview:self.chatTextFieldWrapper];
    
    UITextField * messageTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, self.chatTextFieldWrapper.frame.size.width - 70, 35)];
    messageTextField.tintColor = [FontProperties getOrangeColor];
    messageTextField.placeholder = @"Add to the story";
    //    _messageTextView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Message" attributes:@{NSFontAttributeName:[FontProperties getSmallFont]}];
    messageTextField.delegate = self;
    messageTextField.returnKeyType = UIReturnKeySend;
    messageTextField.backgroundColor = [UIColor whiteColor];
    messageTextField.layer.borderColor = RGB(147, 147, 147).CGColor;
    messageTextField.layer.borderWidth = 0.5f;
    messageTextField.layer.cornerRadius = 4.0f;
    messageTextField.font = [FontProperties mediumFont:18.0f];
    messageTextField.textColor = RGB(102, 102, 102);
    [[UITextView appearance] setTintColor:RGB(102, 102, 102)];
    [self.chatTextFieldWrapper addSubview:messageTextField];
    [self.chatTextFieldWrapper bringSubviewToFront:messageTextField];
    
    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.chatTextFieldWrapper.frame.size.width - 50, 10, 45, 35)];
    [sendButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    sendButton.backgroundColor = [FontProperties getOrangeColor];
    sendButton.layer.borderWidth = 1.0f;
    sendButton.layer.borderColor = [UIColor clearColor].CGColor;
    sendButton.layer.cornerRadius = 5;
    [self.chatTextFieldWrapper addSubview:sendButton];
    
    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 25, 25)];
    sendOvalImageView.image = [UIImage imageNamed:@"sendOval"];
    [sendButton addSubview:sendOvalImageView];
    
    self.addYourVerseLabel = [[UILabel alloc] initWithFrame:CGRectMake(page * 320, 250, self.frame.size.width, 30)];
    self.addYourVerseLabel.text = @"Add your verse";
    self.addYourVerseLabel.textColor = [UIColor whiteColor];
    self.addYourVerseLabel.font = [FontProperties lightFont:30.0f];
    self.addYourVerseLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.addYourVerseLabel];
    
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    self.addYourVerseLabel.text = [NSString stringWithFormat:@"%@%@", textField.text, string];
    return YES;
}

- (void)sendPressed {
    NSLog(@"here");
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
//    CGRect initialFrame = self.chatTextFieldWrapper.frame;
//    initialFrame = initialFrame - kbFrame;
    self.chatTextFieldWrapper.frame = CGRectMake(self.chatTextFieldWrapper.frame.origin.x, self.chatTextFieldWrapper.frame.origin.y - kbFrame.size.height, self.chatTextFieldWrapper.frame.size.width, self.chatTextFieldWrapper.frame.size.height);

}

- (void)removeEventMessageAtPage:(int)page {
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:page];
    NSNumber *eventMessageID = [eventMessage objectForKey:@"id"];
    [Network sendAsynchronousHTTPMethod:DELETE withAPIName:[NSString stringWithFormat:@"eventmessages/?id=%@", eventMessageID] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        
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

@implementation MediaCell

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
    self.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height);
    self.backgroundColor = UIColor.clearColor;
}

@end
