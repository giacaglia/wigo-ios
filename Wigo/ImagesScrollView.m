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
                labelInsideImage = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, imageView.frame.size.width, 50)];
                labelInsideImage.font = [FontProperties mediumFont:20.0f];
                labelInsideImage.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
                labelInsideImage.textAlignment = NSTextAlignmentCenter;
                labelInsideImage.text = [eventMessage objectForKey:@"message"];
                labelInsideImage.textColor = [UIColor whiteColor];
                [imageView addSubview:labelInsideImage];
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
