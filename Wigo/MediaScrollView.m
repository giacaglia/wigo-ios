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

@interface MediaScrollView() {}
@property (nonatomic, strong) NSMutableArray *pageViews;

@property (nonatomic, strong) MPMoviePlayerController *lastMoviePlayer;
@property (nonatomic, strong) NSMutableDictionary *thumbnails;

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
    NSLog(@"event message %@", eventMessage);
    NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
    NSString *contentURL = [eventMessage objectForKey:@"media"];
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
    }

    if ([mimeType isEqualToString:@"new"]) {
        myCell.label.hidden = YES;
        myCell.controller.view.hidden = NO;
        [myCell setControllerDelegate:self.controllerDelegate];
        myCell.moviePlayer.view.hidden = YES;
        myCell.imageView.hidden = YES;
        [self.pageViews setObject:myCell.controller atIndexedSubscript:indexPath.row];
    }
    else if ([mimeType isEqualToString:kImageEventType]) {
        [myCell setTextForEventMessage:eventMessage];
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
        [myCell.imageView setImageWithURL:imageURL];
        myCell.imageView.hidden = NO;
        [myCell setTextForEventMessage:eventMessage];
        myCell.moviePlayer.view.hidden = YES;
        myCell.controller.view.hidden = YES;
        [self.pageViews setObject:myCell.imageView atIndexedSubscript:indexPath.row];
    }
    else {
        [myCell setTextForEventMessage:eventMessage];
        NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://wigo-uploads.s3.amazonaws.com/%@", contentURL]];
        myCell.moviePlayer.contentURL = videoURL;
        myCell.moviePlayer.view.hidden = NO;
        myCell.imageView.hidden = YES;
        myCell.controller.view.hidden = YES;
        [self.pageViews setObject:myCell.moviePlayer atIndexedSubscript:indexPath.row];
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

    [self performBlock:^(void){[self playVideoAtPage:page];}
            afterDelay:0.01
 cancelPreviousRequest:YES];
}


- (void)playVideoAtPage:(int)page {
    if (self.lastMoviePlayer)  [self.lastMoviePlayer pause];
    MPMoviePlayerController *theMoviePlayer = [self.pageViews objectAtIndex:page];
    if ([theMoviePlayer isKindOfClass:[MPMoviePlayerController class]] &&
        theMoviePlayer.playbackState != MPMoviePlaybackStatePlaying) {
        [theMoviePlayer play];
        self.lastMoviePlayer = theMoviePlayer;
    }

}

- (void)removeMediaAtPage:(int)page {
    [self removeEventMessageAtPage:page];
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

- (void)removeEventMessageAtPage:(int)page {
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:page];
    NSNumber *eventMessageID = [eventMessage objectForKey:@"id"];
    [Network sendAsynchronousHTTPMethod:DELETE withAPIName:[NSString stringWithFormat:@"eventmessages/%@", eventMessageID] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
    self.frame = CGRectMake(0, 0, 320, 568);
    self.backgroundColor = UIColor.clearColor;
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.hidden = YES;
    [self.contentView addSubview:self.imageView];
   
    self.moviePlayer = [[MPMoviePlayerController alloc] init];
    self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    [self.moviePlayer setControlStyle: MPMovieControlStyleNone];
    self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    self.moviePlayer.shouldAutoplay = NO;
    [self.moviePlayer prepareToPlay];
    self.moviePlayer.view.frame = self.frame;
    self.moviePlayer.view.hidden = YES;
    [self.contentView addSubview:self.moviePlayer.view];

    self.controller = [[IQMediaPickerController alloc] init];
    [self.controller setMediaType:IQMediaPickerControllerMediaTypePhoto];
    self.controller.view.frame = self.frame;
    self.controller.view.hidden = YES;
    [self.contentView addSubview:self.controller.view];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, self.imageView.frame.size.width, 40)];
    self.label.font = [FontProperties mediumFont:20.0f];
    self.label.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor whiteColor];
    self.label.hidden = YES;
    [self.contentView addSubview:self.label];
    [self.contentView bringSubviewToFront:self.label];
}

- (void)setControllerDelegate:(id)controllerDelegate {
    if (!self.controllerDelegateSet) {
        self.controller.delegate = controllerDelegate;
    }
    self.controllerDelegateSet = YES;
}


- (void)setTextForEventMessage:(NSDictionary *)eventMessage {
    if ([[eventMessage allKeys] containsObject:@"message"]) {
        NSString *message = [eventMessage objectForKey:@"message"];
        if (message && [message isKindOfClass:[NSString class]]) {
            self.label.hidden = NO;
            self.label.text = message;
        }
        else self.label.hidden = YES;
        if ([[eventMessage allKeys] containsObject:@"properties"]) {
            NSDictionary *properties = [eventMessage objectForKey:@"properties"];
            if (properties &&
                [properties isKindOfClass:[NSDictionary class]] &&
                [[properties allKeys] containsObject:@"yPosition"]) {
                NSNumber *yPosition = [properties objectForKey:@"yPosition"];
                self.label.frame = CGRectMake(0, [yPosition intValue], self.imageView.frame.size.width, 40);
            }
        }
    }
}

@end
