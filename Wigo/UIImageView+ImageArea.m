//
//  UIImageView+ImageArea.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/18/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UIImageView+ImageArea.h"
#import "NSObject-CancelableScheduledBlock.h"
#import "WGProfile.h"

NSMutableArray *failedUserInfoArray;

@implementation UIImageView (ImageArea)

- (void)setImage:(NSDictionary *)image completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:[NSURL URLWithString:[image objectForKey:@"url"]] placeholderImage:[[UIImage alloc] init] imageArea:[image objectForKey:@"area"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedBlock) completedBlock(image, error, cacheType);
    }];
}

- (void)setSmallImageForUser:(WGUser *)user completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:[user smallCoverImageURL] placeholderImage:[[UIImage alloc] init] imageArea:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedBlock) completedBlock(image, error, cacheType);
    }];
}

- (void)setCoverImageForUser:(WGUser *)user completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:[user coverImageURL] placeholderImage:[[UIImage alloc] init] imageArea:[user coverImageArea] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedBlock) completedBlock(image, error, cacheType);
    }];
}

- (void)setImageWithURL:(NSURL *)url
              imageArea:(NSDictionary *)area
               withInfo:(NSDictionary *)info
       outputDictionary:(NSDictionary *)outputDict
completedWithDictionary:(SDWebImageCompletedBlockWithDictionary)completedDictionary {
    [self setImageWithURL:url withArea:area placeholderImage:nil options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedDictionary) completedDictionary(image, error, cacheType, outputDict);
    }];
}

- (void)setImageWithURL:(NSURL *)url
              imageArea:(NSDictionary *)area
               withInfo:(NSDictionary *)info
              completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url withArea:area placeholderImage:nil options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedBlock) completedBlock(image, error, cacheType);
    }];
}

- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary *)area {
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil imageArea:area completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {}];
}

- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil imageArea:area completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageArea:(NSDictionary*)area {
    [self setImageWithURL:url placeholderImage:placeholder options:0 progress:nil imageArea:area completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:placeholder options:0 progress:nil imageArea:area completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options imageArea:(NSDictionary*)area {
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil imageArea:area completed:nil ];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock  {
    [self setImageWithURL:url withArea:area placeholderImage:placeholder options:options progress:progressBlock completed:completedBlock];
    
}

@end
