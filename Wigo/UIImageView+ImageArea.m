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

- (void)setSmallImageForUsers:(WGCollection *)arrayOfUsers {
    if (arrayOfUsers.count == 0) return;
    WGUser *firstUser = (arrayOfUsers.count > 0) ? (WGUser *)[arrayOfUsers objectAtIndex:0] : [WGUser new];
    WGUser *secondUser = (arrayOfUsers.count > 1) ? (WGUser *)[arrayOfUsers objectAtIndex:1] : [WGUser new];
    WGUser *thirdUser =  (arrayOfUsers.count > 2)? (WGUser *)[arrayOfUsers objectAtIndex:2] : [WGUser new];
    if (arrayOfUsers.count == 1) {
        [self setSmallImageForUser:firstUser completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];
    }
    else if (arrayOfUsers.count == 2) {
        UIImageView * firstPartImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width/2 - 3, self.frame.size.height)];
        firstPartImageView.contentMode = UIViewContentModeScaleAspectFill;
        firstPartImageView.clipsToBounds = YES;
        [self addSubview:firstPartImageView];
        UIImageView * secondPartImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 3, 0, self.frame.size.width/2 - 6, self.frame.size.height)];
        secondPartImageView.contentMode = UIViewContentModeScaleAspectFill;
        secondPartImageView.clipsToBounds = YES;
        [self addSubview:secondPartImageView];
        [firstPartImageView setSmallImageForUser:firstUser completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];
        [secondPartImageView setSmallImageForUser:secondUser completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];
    }
    else if (arrayOfUsers.count >= 3) {
        self.image = nil;
        [self cancelCurrentImageLoad];
        UIImageView * firstPartImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width/2 - 0.5, self.frame.size.height)];
        firstPartImageView.contentMode = UIViewContentModeScaleAspectFill;
        firstPartImageView.clipsToBounds = YES;
        [self addSubview:firstPartImageView];
        [firstPartImageView setSmallImageForUser:firstUser completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];
      
        UIImageView * secondPartImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 0.5, 0, self.frame.size.width/2 - 1, self.frame.size.height/2 - 0.5)];
        secondPartImageView.contentMode = UIViewContentModeScaleAspectFill;
        secondPartImageView.clipsToBounds = YES;
        [secondPartImageView setSmallImageForUser:secondUser completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];
        [self addSubview:secondPartImageView];
        
        UIImageView * thirdPartImageVIew = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 0.5, self.frame.size.height/2 + 0.5, self.frame.size.width/2 - 1, self.frame.size.height/2 - 0.5)];
        thirdPartImageVIew.contentMode = UIViewContentModeScaleAspectFill;
        thirdPartImageVIew.clipsToBounds = YES;
        [thirdPartImageVIew setSmallImageForUser:thirdUser completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];
        [self addSubview:thirdPartImageVIew];
    }
}

- (void)setCoverImageForUser:(WGUser *)user completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:[user coverImageURL] placeholderImage:[[UIImage alloc] init] imageArea:[user coverImageArea] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedBlock) completedBlock(image, error, cacheType);
    }];
}

- (void)setImageWithURL:(NSURL *)url
              imageArea:(NSDictionary *)area
       outputDictionary:(NSDictionary *)outputDict
completedWithDictionary:(SDWebImageCompletedBlockWithDictionary)completedDictionary {
    [self setImageWithURL:url withArea:area placeholderImage:nil options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedDictionary) completedDictionary(image, error, cacheType, outputDict);
    }];
}

- (void)setImageWithURL:(NSURL *)url
              imageArea:(NSDictionary *)area
       placeholderImage:(UIImage *)placeholderImage
       outputDictionary:(NSDictionary *)outputDict
completedWithDictionary:(SDWebImageCompletedBlockWithDictionary)completedDictionary {
    [self setImageWithURL:url withArea:area placeholderImage:placeholderImage options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (completedDictionary) completedDictionary(image, error, cacheType, outputDict);
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
