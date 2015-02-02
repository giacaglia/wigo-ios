//
//  UIView+ViewToImage.m
//  Wigo
//
//  Created by Adam Eagle on 2/2/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "UIView+ViewToImage.h"

@implementation UIView (ViewToImage)

-(UIImage *)convertViewToImage {
    UIGraphicsBeginImageContext(self.bounds.size);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
