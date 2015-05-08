//
//  UIColor+ImageExtension.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/8/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "UIColor+ImageExtension.h"

@implementation UIColor (ImageExtension)

-(UIImage *) imageFromColor {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [self CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
