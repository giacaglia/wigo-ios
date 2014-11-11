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
@property (nonatomic, strong) NSMutableArray *players;
@property (nonatomic, strong) MPMoviePlayerController *lastMoviePlayer;

@end
@implementation MediaScrollView


- (void)loadContent {
    self.backgroundColor = RGB(23, 23, 23);
    self.showsHorizontalScrollIndicator = NO;
    self.contentSize = CGSizeMake(self.eventMessages.count * 320, [self superview].frame.size.height);
    if (!self.players) {
        self.players = [[NSMutableArray alloc] init];
    }
    for (int i = 0; i < self.eventMessages.count; i++) {
        NSDictionary *eventMessage = [self.eventMessages objectAtIndex:i];
        NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
        NSString *contentURL = [eventMessage objectForKey:@"media"];
        if ([mimeType isEqualToString:@"new"]) {
            self.controller.view.frame = CGRectMake(i*320, 0, 320, 640);
            [self addSubview:self.controller.view];
            [self.players addObject:[NSNull null]];
        }
        else if ([mimeType isEqualToString:@"newText"]) {
            [self addViewForNewTextAtPage:i];
            [self.players addObject:[NSNull null]];
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
            [self.players addObject:imageView];
          
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
            [theMoviePlayer prepareToPlay];
            
            UIView *videoView = [[UIView alloc] initWithFrame: CGRectMake(i*320, 0, 320, 640)];
//            [theMoviePlayer requestThumbnailImagesAtTimes:@[@0.0f] timeOption:MPMovieTimeOptionNearestKeyFrame];
//            [[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//                UIImage *image = [[note userInfo] objectForKey:MPMoviePlayerThumbnailTimeKey];
//                if (image && [image isKindOfClass:[UIImage class]]) {
//                    videoView.image = [[note userInfo] objectForKey:MPMoviePlayerThumbnailTimeKey];
//                }
//            }];

            videoView.backgroundColor = [UIColor clearColor];
            theMoviePlayer.view.frame = videoView.bounds;
            theMoviePlayer.backgroundView.backgroundColor = [UIColor clearColor];
            [videoView addSubview: theMoviePlayer.view];
            [self bringSubviewToFront: theMoviePlayer.view];

            [self addSubview: videoView];            
            [self.players addObject: theMoviePlayer];
        }
    }
    if (self.index) self.contentOffset = CGPointMake(320 * [self.index intValue], 0);
    else self.contentOffset = CGPointMake(320*(self.eventMessages.count - 1), 0);
}

- (void)closeView {
    if (self.lastMoviePlayer) {
        [self.lastMoviePlayer stop];
    }
}

-(void)scrolledToPage:(int)page {
    if (self.lastMoviePlayer) {
        [self.lastMoviePlayer stop];
    }
    MPMoviePlayerController *theMoviePlayer = [self.players objectAtIndex:page];
    if ([theMoviePlayer isKindOfClass:[MPMoviePlayerController class]]) {
        UIImageView *movieSuperview = (UIImageView *)theMoviePlayer.view.superview;
//        movieSuperview.image = nil;
        [theMoviePlayer play];
        self.lastMoviePlayer = theMoviePlayer;
    }
}

- (void)removeMediaAtPage:(int)page {
    UIView *player = [self.players objectAtIndex:page];
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
    UIView *chatTextFieldWrapper = [[UIView alloc] initWithFrame:CGRectMake(page*320, self.frame.size.height - 50, self.frame.size.width, 60)];
    [self addSubview:chatTextFieldWrapper];
    
    UITextField * messageTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, chatTextFieldWrapper.frame.size.width - 70, 35)];
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
    messageTextField.delegate = self;
    [[UITextView appearance] setTintColor:RGB(102, 102, 102)];
    [chatTextFieldWrapper addSubview:messageTextField];
    [chatTextFieldWrapper bringSubviewToFront:messageTextField];
    
    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(chatTextFieldWrapper.frame.size.width - 50, 10, 45, 35)];
    [sendButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    sendButton.backgroundColor = [FontProperties getOrangeColor];
    sendButton.layer.borderWidth = 1.0f;
    sendButton.layer.borderColor = [UIColor clearColor].CGColor;
    sendButton.layer.cornerRadius = 5;
    [chatTextFieldWrapper addSubview:sendButton];
    
    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 25, 25)];
    sendOvalImageView.image = [UIImage imageNamed:@"sendOval"];
    [sendButton addSubview:sendOvalImageView];
}



@end
