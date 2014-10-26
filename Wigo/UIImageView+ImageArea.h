//
//  UIImageView+ImageArea.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/18/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "User.h"

@interface UIImageView (ImageArea)

- (void)setSmallImageForUser:(User *)user completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setCoverImageForUser:(User *)user completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary *)area;
- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageArea:(NSDictionary *)area;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options imageArea:(NSDictionary*)area;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock;


@end
