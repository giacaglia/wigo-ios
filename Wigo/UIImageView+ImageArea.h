//
//  UIImageView+ImageArea.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/18/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "WGUser.h"

@interface UIImageView (ImageArea)

- (void)setSmallImageForUsers:(WGCollection *)arrayOfUsers;
- (void)setSmallImageForUser:(WGUser *)user completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setCoverImageForUser:(WGUser *)user completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary *)area;
- (void)setImageWithURL:(NSURL *)url imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageArea:(NSDictionary *)area;

- (void)setImageWithURL:(NSURL *)url
              imageArea:(NSDictionary *)area
       outputDictionary:(NSDictionary *)outputDict
completedWithDictionary:(SDWebImageCompletedBlockWithDictionary)completedDictionary;
- (void)setImageWithURL:(NSURL *)url
              imageArea:(NSDictionary *)area
       placeholderImage:(UIImage *)placeholderImage
       outputDictionary:(NSDictionary *)outputDict
completedWithDictionary:(SDWebImageCompletedBlockWithDictionary)completedDictionary;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options imageArea:(NSDictionary*)area;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock imageArea:(NSDictionary*)area completed:(SDWebImageCompletedBlock)completedBlock;


@end
