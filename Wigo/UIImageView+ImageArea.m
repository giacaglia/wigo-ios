//
//  UIImageView+ImageArea.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/18/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UIImageView+ImageArea.h"
#import "Network.h"
#import "NSObject-CancelableScheduledBlock.h"

NSMutableArray *failedUserInfoArray;

@implementation UIImageView (ImageArea)


- (void)setSmallImageForUser:(User *)user completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:[NSURL URLWithString:[user smallImageURL]] placeholderImage:[[UIImage alloc] init] imageArea:[user coverImageArea] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (error) {
            if (!failedUserInfoArray) failedUserInfoArray = [NSMutableArray new];
            
            if (![[failedUserInfoArray valueForKey:@"user_id"] containsObject:[user objectForKey:@"id"]]) {
                [failedUserInfoArray addObject:@{@"user_id": [user objectForKey:@"id"], @"image_type": @"facebook"}];
            }
            [Network sendAsynchronousHTTPMethod:POST
                                    withAPIName:@"images/failed/"
                                    withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                        failedUserInfoArray = [NSMutableArray new];
                                    }
                                    withOptions:failedUserInfoArray
             ];
        }
        if (completedBlock) completedBlock(image, error, cacheType);
    }];
}

- (void)setCoverImageForUser:(User *)user completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:[NSURL URLWithString:[user coverImageURL]] placeholderImage:[[UIImage alloc] init] imageArea:[user coverImageArea] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (error) {
            if (!failedUserInfoArray) failedUserInfoArray = [NSMutableArray new];
            
            if (![[failedUserInfoArray valueForKey:@"user_id"] containsObject:[user objectForKey:@"id"]]) {
                [failedUserInfoArray addObject:@{@"user_id": [user objectForKey:@"id"], @"image_type": @"facebook"}];
            }
            [Network sendAsynchronousHTTPMethod:POST
                                    withAPIName:@"images/failed/"
                                    withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                        failedUserInfoArray = [NSMutableArray new];
                                    }
                                    withOptions:failedUserInfoArray
             ];
        }
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
