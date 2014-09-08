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

+ (UIFont *)numericLightFont:(float)fontSize {
//    if (IS_IOS_8) return [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
    return [UIFont fontWithName:@"WhitneyNumeric-Light" size:fontSize];
}

+ (UIFont *)lightFont:(float)fontSize {
//    if (IS_IOS_8) return [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
    return [UIFont fontWithName:@"Whitney-Light" size:fontSize];
}

+ (UIFont *)scLightFont:(float)fontSize {
//    if (IS_IOS_8) return [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
    return [UIFont fontWithName:@"Whitney-LightSC" size:fontSize];
}

+ (UIFont *)mediumFont:(float)fontSize {
//    if (IS_IOS_8) return [UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize];
    return [UIFont fontWithName:@"Whitney-Medium" size:fontSize];
}

+ (UIFont *)scMediumFont:(float)fontSize {
//    if (IS_IOS_8) return [UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize];
    return [UIFont fontWithName:@"Whitney-MediumSC" size:fontSize];
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
