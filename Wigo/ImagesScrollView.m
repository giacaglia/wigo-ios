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
    self.backgroundColor = RGB(23, 23, 23);
    self.showsHorizontalScrollIndicator = NO;
    self.contentSize = CGSizeMake(self.eventMessages.count * 320, [self superview].frame.size.height);
    for (int i = 0; i < self.eventMessages.count; i++) {
        NSDictionary *eventMessage = [self.eventMessages objectAtIndex:i];
        NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
        NSString *contentURL = [eventMessage objectForKey:@"media"];
        if ([mimeType isEqualToString:@"image/jpeg"]) {
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i*320, 0, 320, 640)];
            [imageView setImageWithURL:imageURL];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [self addSubview:imageView];
            
            if ([[eventMessage allKeys] containsObject:@"message"]) {
                UILabel *textInsideImage = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, imageView.frame.size.width, 50)];
                textInsideImage.font = [FontProperties mediumFont:20.0f];
                textInsideImage.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
                textInsideImage.textAlignment = NSTextAlignmentCenter;
                textInsideImage.text = [eventMessage objectForKey:@"message"];
                textInsideImage.textColor = [UIColor whiteColor];
                [imageView addSubview:textInsideImage];
            }
          
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
