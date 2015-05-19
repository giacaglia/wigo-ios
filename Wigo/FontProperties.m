//
//  FontProperties.m
//  WiGo
//
//  Created by Giuliano Giacaglia on 2/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FontProperties.h"

@implementation FontProperties

#pragma mark - Font

+ (UIFont *)openSansRegular:(float)fontSize {
    return [UIFont fontWithName:@"OpenSans" size:fontSize];
}

+ (UIFont *)openSansSemibold:(float)fontSize {
    return [UIFont fontWithName:@"OpenSans-Semibold" size:fontSize];
}

+ (UIFont *)openSansBold:(float)fontSize {
    return [UIFont fontWithName:@"OpenSans-Bold" size:fontSize];
}

+ (UIFont *)montserratRegular:(float)fontSize {
    return [UIFont fontWithName:@"Montserrat" size:fontSize];
}

+ (UIFont *)montserratBold:(float)fontSize {
    return [UIFont fontWithName:@"Montserrat-Bold" size:fontSize];
}

+ (UIFont *)numericLightFont:(float)fontSize {
    return [UIFont fontWithName:@"WhitneyNumeric-Light" size:fontSize];
}

+ (UIFont *)lightFont:(float)fontSize {
    return [UIFont fontWithName:@"Whitney-Light" size:fontSize];
}

+ (UIFont *)scLightFont:(float)fontSize {
    return [UIFont fontWithName:@"Whitney-LightSC" size:fontSize];
}

+ (UIFont *)mediumFont:(float)fontSize {
    return [UIFont fontWithName:@"Whitney-Medium" size:fontSize];
}

+ (UIFont *)scMediumFont:(float)fontSize {
    return [UIFont fontWithName:@"Whitney-MediumSC" size:fontSize];
}

+ (UIFont *)boldFont:(float)fontSize {
    return [UIFont fontWithName:@"Whitney-Bold" size:fontSize];
}

+ (UIFont *)getSmallPhotoFont {
    return [FontProperties lightFont:12.0f];
}

+ (UIFont *)getBioFont {
    return [FontProperties lightFont:15.0f];
}

+ (UIFont *)getSubtitleFont {
    return [FontProperties mediumFont:15.0f];
}

+ (UIFont *)getSmallFont {
    return [FontProperties lightFont:18.0f];
}

+ (UIFont *)getNormalFont {
    return [FontProperties scLightFont:18.0f];
}

+ (UIFont *)semiboldFont:(float)fontSize {
    return [UIFont fontWithName:@"Whitney-Semibold" size:fontSize];
}

+ (UIFont *)getTitleFont {
    return [FontProperties scMediumFont:18.0f];
}


+ (UIFont *) getBigButtonFont {
    return [FontProperties scMediumFont:20.0f];
}


+ (UIFont *)getSubHeaderFont {
    return [FontProperties lightFont:30.0f];
}

+ (UIFont *)getHeaderFont {
    return [FontProperties lightFont:60.0f];
}



+ (NSDictionary *)getDictTitle {
    return @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                                NSFontAttributeName:[FontProperties getTitleFont],
                                NSParagraphStyleAttributeName:[FontProperties getStyle]};
}


+ (NSMutableParagraphStyle *)getStyle {
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    return style;
}


#pragma mark - Colors

+ (UIColor *)getBlueColor {
    return RGB(114, 181, 219);
}

+ (UIColor *)getLightBlueColor {
    return RGBAlpha(122, 193, 226, 0.3f);
}

+ (UIColor *)getOrangeColor {
    return RGB(244,149,45);
}

+ (UIColor *) getLightOrangeColor {
    return RGBAlpha(244, 149, 45, 0.3f);
}

+ (UIColor *)getBackgroundLightOrange {
    return RGBAlpha(244, 149, 45, 0.1f);
}

@end
