//
//  FontProperties.h
//  WiGo
//
//  Created by Giuliano Giacaglia on 2/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
#define RGBAlpha(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

@interface FontProperties : NSObject

+ (UIFont *)numericLightFont:(float)fontSize;
+ (UIFont *)lightFont:(float)fontSize;
+ (UIFont *)scLightFont:(float)fontSize;
+ (UIFont *)mediumFont:(float)fontSize;
+ (UIFont *)scMediumFont:(float)fontSize;
+ (UIFont *)boldFont:(float)fontSize;

+ (UIFont *)getBioFont;
+ (UIFont *)getSubHeaderFont;
+ (UIFont *)getNormalFont;
+ (UIFont *)getSmallFont;
+ (UIFont *)getTitleFont;
+ (UIFont *)getSubtitleFont;
+ (UIFont *)getSmallPhotoFont;
+ (UIFont *)getBigButtonFont;

+ (NSDictionary *)getDictTitle;

+ (UIColor *)getOrangeColor;
+ (UIColor *)getLightOrangeColor;
+ (UIColor *)getLightBlueColor;
+ (UIColor *)getBlueColor;
+ (UIColor *)getBackgroundLightOrange;

@end
