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
    NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
    NSString *contentURL = [eventMessage objectForKey:@"media"];
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
    }
    [myCell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIView *player = [self.pageViews objectAtIndex:indexPath.row];
    if ([player isKindOfClass:[UIImageView class]]) {
        [myCell.contentView addSubview:player];
    }
    else if ([player isKindOfClass:[MPMoviePlayerController class]]) {
        MPMoviePlayerController *moviePlayer = (MPMoviePlayerController *)player;
        [myCell.contentView addSubview:moviePlayer.view];
    }
    else if ([player isKindOfClass:[IQMediaPickerController class]]) {
        IQMediaPickerController *controller = (IQMediaPickerController *)player;
        [myCell.contentView addSubview:controller.view];
    }
    else {
        if ([mimeType isEqualToString:@"new"]) {
            self.controller.view.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height);
            [myCell.contentView addSubview:self.controller.view];
            [self.pageViews setObject:self.controller atIndexedSubscript:indexPath.row];
        }
        else if ([mimeType isEqualToString:@"image/jpeg"]) {
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height)];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [imageView setImageWithURL:imageURL];
            [myCell.contentView addSubview:imageView];
            UILabel *labelInsideImage;
            if ([[eventMessage allKeys] containsObject:@"message"]) {
                NSString *message = [eventMessage objectForKey:@"message"];
                if (message && [message isKindOfClass:[NSString class]]) {
                    labelInsideImage = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, imageView.frame.size.width, 40)];
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
                    labelInsideImage.frame = CGRectMake(0, [yPosition intValue], imageView.frame.size.width, 40);
                }
            }
            [self.pageViews setObject:imageView atIndexedSubscript:indexPath.row];
        }
        else {
            NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://wigo-uploads.s3.amazonaws.com/%@", contentURL]];
            
            MPMoviePlayerController *theMoviePlayer = [[MPMoviePlayerController alloc] init];
            
            theMoviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
            NSLog(@"video URL %@", videoURL);
            [theMoviePlayer setContentURL: videoURL];
            theMoviePlayer.scalingMode = MPMovieScalingModeAspectFill;
            [theMoviePlayer setControlStyle: MPMovieControlStyleNone];
            theMoviePlayer.repeatMode = MPMovieRepeatModeOne;
            theMoviePlayer.shouldAutoplay = NO;
            
            //            [theMoviePlayer play];
            //            [theMoviePlayer pause];
            [theMoviePlayer prepareToPlay];
            UIView *videoView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height)];
            
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
            //                    if ([thumb isKindOfClass: [UIImage class]] && [self.thumbnails objectForKey: [NSString stringWithFormat: @"%i", indexPath.row]] == nil) {
            //                        NSLog(@"adding thumb ---> %i", indexPath.row);
            //                        UIImageView *imageView = [[UIImageView alloc] initWithImage: thumb];
            //                        imageView.frame = curentMoviePlayer.backgroundView.bounds;
            //                        imageView.clipsToBounds = YES;
            //                        imageView.contentMode = UIViewContentModeScaleAspectFill;
            //                        [curentMoviePlayer.backgroundView addSubview: imageView];
            //                        [self.thumbnails setObject: imageView forKey: [NSString stringWithFormat: @"%i", indexPath.row]];
            //                    }
            //                });
            //                
            //
            //            }];
            //            
            [videoView addSubview: theMoviePlayer.view];
            [myCell.contentView bringSubviewToFront: theMoviePlayer.view];
            
            [myCell.contentView addSubview: videoView];
            [self.pageViews setObject:theMoviePlayer atIndexedSubscript:indexPath.row];
        }

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
    MPMoviePlayerController *theMoviePlayer = [self.pageViews objectAtIndex:page];
    if ([theMoviePlayer isKindOfClass:[MPMoviePlayerController class]] &&
        theMoviePlayer.playbackState != MPMoviePlaybackStatePlaying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.lastMoviePlayer)  [self.lastMoviePlayer pause];
            [theMoviePlayer play];
            self.lastMoviePlayer = theMoviePlayer;
        });
    }
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
