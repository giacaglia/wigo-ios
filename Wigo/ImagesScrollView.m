//
//  ImagesScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ImagesScrollView.h"
#import "Globals.h"

@implementation ImagesScrollView


- (void)loadImages {
    self.contentSize = CGSizeMake(self.eventMessages.count * 320, [self superview].frame.size.height);
    for (int i = 0; i < self.eventMessages.count; i++) {
        NSDictionary *eventMessage = [self.eventMessages objectAtIndex:i];
        NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
        NSString *contentURL = [eventMessage objectForKey:@"media"];
        if ([mimeType isEqualToString:@"image/jpeg"]) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((i-1)*320, 0, 320, 640)];
            [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://wigo-uploads.s3.amazonaws.com/%@", contentURL]]];
            [self addSubview:imageView];
        }
        else {
            
        }
    }
}

@end
