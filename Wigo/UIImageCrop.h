//
//  UIImageCrop.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/26/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageCrop : UIImage

+ (void)blurImageView:(UIImageView *)profileImgView withRadius:(float)radius;
+ (void)blurImageView:(UIImageView *)profileImgView;
+ (UIImage *)croppingImage:(UIImage *)imageToCrop toRect:(CGRect)rect;
+ (UIImage*)image:(UIImage*)image scaledToSize:(CGSize)newSize;
+ (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize andImage:(UIImage *)sourceImage;
@end
