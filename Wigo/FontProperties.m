//
//  FontProperties.m
//  PicBill
//
//  Created by Giuliano Giacaglia on 2/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FontProperties.h"

static UIFont *bioFont;
static UIFont *headerFont;
static UIFont *subHeaderFont;
static UIFont *normalFont;
static UIFont *smallFont;
static UIFont *titleFont;
static UIFont *subtitleFont;
static UIFont *smallPhotoFont;
static UIFont *bigButtonFont;

static UIColor *blueColor;
static UIColor *orangeColor;
static UIColor *lightOrangeColor;

@implementation FontProperties


#pragma mark - Font

+ (UIFont *)getSmallPhotoFont {
    if (smallPhotoFont == nil) {
        smallPhotoFont = [UIFont fontWithName:@"Whitney-Light" size:12.0f];
    }
    return smallPhotoFont;
}

+ (UIFont *)getBioFont {
    if (bioFont == nil) {
        bioFont = [UIFont fontWithName:@"Whitney-Light" size:15.0f];
    }
    return bioFont;
}

+ (UIFont *)getSubtitleFont {
    if (subtitleFont == nil) {
        subtitleFont = [UIFont fontWithName:@"Whitney-Medium" size:15.0f];
    }
    return subtitleFont;
}


+ (UIFont *)getSmallFont {
    if (smallFont == nil) {
        smallFont = [UIFont fontWithName:@"Whitney-Light" size:18.0f];
    }
    return smallFont;
}

+ (UIFont *)getNormalFont {
    if (normalFont == nil) {
        normalFont = [UIFont fontWithName:@"Whitney-LightSC" size:18.0f];
    }
    return normalFont;
}


+ (UIFont *)getTitleFont {
    if (titleFont == nil) {
        titleFont = [UIFont fontWithName:@"Whitney-MediumSC" size:18.0f];
    }
    return titleFont;
}


+ (UIFont *)getNumericFont {
    return [UIFont fontWithName:@"WhitneyNumeric-Medium" size:18.0f];
}


+ (UIFont *) getBigButtonFont {
    if (bigButtonFont == nil) {
        bigButtonFont = [UIFont fontWithName:@"Whitney-MediumSC" size:20.0f];
    }
    return bigButtonFont;
}


+ (UIFont *)getSubHeaderFont {
    if (subHeaderFont == nil) {
        subHeaderFont =  [UIFont fontWithName:@"Whitney-Light" size:30.0f];
    }
    return subHeaderFont;
}

+ (UIFont *)getHeaderFont {
    if (headerFont == nil) {
        headerFont = [UIFont fontWithName:@"Whitney-Light" size:60.0f];
    }
    return headerFont;
}



+ (NSDictionary *)getDictTitle {
    NSDictionary *dictTitle = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                                NSFontAttributeName:[FontProperties getTitleFont],
                                NSParagraphStyleAttributeName:[FontProperties getStyle]};
    return dictTitle;
}

+ (NSDictionary *)getDictNumeric {
    
    NSDictionary *dictNumeric = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                                  NSFontAttributeName:[FontProperties getNumericFont],
                                  NSParagraphStyleAttributeName:[FontProperties getStyle]};
    return dictNumeric;
}

+ (NSMutableParagraphStyle *)getStyle {
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    return style;
}


#pragma mark - Colors

+ (UIColor *)getBlueColor {
    if (blueColor == nil) {
        blueColor = RGB(122,193,226);
    }
    return blueColor;
}

+ (UIColor *)getLightBlueColor {
    return [UIColor colorWithRed:122/255.0f green:193/255.0f blue:226/255.0f alpha:0.3f];
}

+ (UIColor *)getOrangeColor {
    if (orangeColor == nil) {
        orangeColor = RGB(244,149,45);
    }
    return orangeColor;
}

+ (UIColor *) getLightOrangeColor {
    if (lightOrangeColor == nil) {
        lightOrangeColor = [UIColor colorWithRed:244/255.0f green:149/255.0f blue:45/255.0f alpha:0.3f];
    }
    return lightOrangeColor;
}

+ (UIColor *)getBackgroundLightOrange {
    return RGBAlpha(244, 149, 45, 0.1f);
}

@end
