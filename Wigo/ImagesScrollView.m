//
//  ImagesScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ImagesScrollView.h"
#import "Globals.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation ImagesScrollView


- (void)loadContent {
    self.showsHorizontalScrollIndicator = NO;
    self.contentSize = CGSizeMake(self.eventMessages.count * 320, [self superview].frame.size.height);
    for (int i = 0; i < self.eventMessages.count; i++) {
        NSDictionary *eventMessage = [self.eventMessages objectAtIndex:i];
        NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
        NSString *contentURL = [eventMessage objectForKey:@"media"];
        if ([mimeType isEqualToString:@"image/jpeg"]) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((i-1)*320, 0, 320, 640)];
            [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://wigo-uploads.s3.amazonaws.com/%@", contentURL]]];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [self addSubview:imageView];
        }
        else {
            MPMoviePlayerController *theMoviPlayer;
            NSURL *urlString = [NSURL URLWithString:[NSString stringWithFormat:@"https://wigo-uploads.s3.amazonaws.com/%@", contentURL]];
            theMoviPlayer = [[MPMoviePlayerController alloc] initWithContentURL:urlString];
            theMoviPlayer.scalingMode = MPMovieScalingModeFill;
            theMoviPlayer.view.frame = CGRectMake(0, 60, 320, 350);
            [self addSubview:theMoviPlayer.view];
            [theMoviPlayer play];
        }
    }
}

@end
