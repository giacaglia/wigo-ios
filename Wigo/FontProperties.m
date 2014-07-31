//
//  FontProperties.m
//  PicBill
//
//  Created by Giuliano Giacaglia on 2/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FontProperties.h"

@implementation FontProperties

#pragma mark - Font

+ (UIFont *)getSmallPhotoFont {
    return LIGHT_FONT(12.0f);
}

+ (UIFont *)getBioFont {
    return LIGHT_FONT(15.0f);
}

+ (UIFont *)getSubtitleFont {
    return MEDIUM_FONT(15.0f);
}

+ (UIFont *)getSmallFont {
    return LIGHT_FONT(18.0f);
}

+ (UIFont *)getNormalFont {
    return SC_LIGHT_FONT(18.0f);
}


+ (UIFont *)getTitleFont {
    return SC_MEDIUM_FONT(18.0f);
}


+ (UIFont *) getBigButtonFont {
    return SC_MEDIUM_FONT(20.0f);
}


+ (UIFont *)getSubHeaderFont {
    return LIGHT_FONT(30.0f);
}

+ (UIFont *)getHeaderFont {
    return LIGHT_FONT(60.0f);
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
    return RGB(122,193,226);
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
