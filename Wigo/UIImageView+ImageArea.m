//
//  UIImageView+ImageArea.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/18/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UIImageView+ImageArea.h"


@implementation UIImageView (ImageArea)

- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary *)area {
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil imageArea:area completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {}];

}

- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil imageArea:area completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageArea:(NSDictionary*)area {
    [self setImageWithURL:url placeholderImage:placeholder options:0 progress:nil imageArea:area completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options imageArea:(NSDictionary*)area {
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil imageArea:area completed:nil ];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock  {
    __weak UIImageView *weakProfileImgView = self;
    __weak NSDictionary* weakArea = area;
    weakProfileImgView.hidden = YES;
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (![weakArea isKindOfClass:[NSNull class]] && !weakArea) {
                    CGRect rect = CGRectMake([[weakArea objectForKey:@"x"] intValue], [[weakArea objectForKey:@"y"] intValue], [[weakArea objectForKey:@"width"] intValue], [[weakArea objectForKey:@"height"] intValue]);
                    if (!CGRectEqualToRect(CGRectZero, rect)) {
                        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
                        [weakProfileImgView setImage:[UIImage imageWithCGImage:imageRef]];
                        CGImageRelease(imageRef);
                    }
                }
                weakProfileImgView.hidden = NO;
                if (completedBlock) {
                    completedBlock(image, error, cacheType);
                }

             });
    }];
}





@end
