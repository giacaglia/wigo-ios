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
@property (nonatomic, strong) NSMutableArray *moviePlayers;

@end
@implementation MediaScrollView


- (void)loadContent {
    self.backgroundColor = RGB(23, 23, 23);
    self.showsHorizontalScrollIndicator = NO;
    self.contentSize = CGSizeMake(self.eventMessages.count * 320, [self superview].frame.size.height);
    for (int i = 0; i < self.eventMessages.count; i++) {
        NSDictionary *eventMessage = [self.eventMessages objectAtIndex:i];
        NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
        NSString *contentURL = [eventMessage objectForKey:@"media"];
        if ([mimeType isEqualToString:@"new"]) {
            self.controller.view.frame = CGRectMake(i*320, 0, 320, 640);
            [self addSubview:self.controller.view];
        }
        else if ([mimeType isEqualToString:@"image/jpeg"]) {
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i*320, 0, 320, 640)];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [imageView setImageWithURL:imageURL];
            [self addSubview:imageView];
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
          
        }
        else {
            NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://wigo-uploads.s3.amazonaws.com/%@", contentURL]];
            
            MPMoviePlayerController *theMoviePlayer = [[MPMoviePlayerController alloc] initWithContentURL: videoURL];
            theMoviePlayer.movieSourceType=MPMovieSourceTypeStreaming;
            theMoviePlayer.scalingMode = MPMovieScalingModeFill;
            [theMoviePlayer setControlStyle: MPMovieControlStyleNone];
            theMoviePlayer.view.frame = self.frame;

            if (!self.moviePlayers) {
                self.moviePlayers = [[NSMutableArray alloc] init];
            }
            
            [self.moviePlayers addObject: theMoviePlayer];
            
            [theMoviePlayer prepareToPlay];
            
            UIView *videoView = [[UIView alloc] initWithFrame: self.frame];
            videoView.backgroundColor = [UIColor clearColor];
            
            UIButton *playButton = [[UIButton alloc] initWithFrame: theMoviePlayer.view.frame];
            [playButton addTarget: self action: @selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
            playButton.tag = [self.moviePlayers indexOfObject: theMoviePlayer];
            playButton.backgroundColor = [UIColor clearColor];
            
            [videoView addSubview: theMoviePlayer.view];
            [videoView addSubview: playButton];
            
            [self addSubview: videoView];
        }
    }
    if (self.index) self.contentOffset = CGPointMake(320 * [self.index intValue], 0);
    else self.contentOffset = CGPointMake(320*(self.eventMessages.count - 1), 0);
}

- (void) playVideo: (UIButton *) sender {
    if (sender.tag > self.moviePlayers.count - 1) {
        NSLog(@"Movie Player trying to play movie that doesn't exist in the array.");
        return;
    }
    
    MPMoviePlayerController *theMoviePlayer = [self.moviePlayers objectAtIndex: sender.tag];
    [theMoviePlayer play];
}

@end
