//
//  UIImageCrop.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/26/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageCrop : UIImage

+ (UIImage*)imageFromImageView:(UIImageView*)imageView;
+ (UIImage *)blurredImageFromImageView:(UIImageView *)imageView withRadius:(float)radius;
+ (void)blurImageView:(UIImageView *)profileImgView withRadius:(float)radius;
+ (UIImage *)croppingImage:(UIImage *)imageToCrop toRect:(CGRect)rect;
+ (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize andImage:(UIImage *)sourceImage;
@end
