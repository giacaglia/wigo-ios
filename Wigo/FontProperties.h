//
//  FontProperties.h
//  PicBill
//
//  Created by Giuliano Giacaglia on 2/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
#define RGBAlpha(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


//#if __IPHONE_8_0
//    #define IS_IOS_8 YES
//#else
//    #define IS_IOS_8 NO
//#endif

//#if YES
    #define LIGHT_FONT(fontSize) [UIFont fontWithName:@"Whitney-Light" size:fontSize];
    #define SC_LIGHT_FONT(fontSize) [UIFont fontWithName:@"Whitney-LightSC" size:fontSize];
    #define MEDIUM_FONT(fontSize) [UIFont fontWithName:@"Whitney-Medium" size:fontSize];
    #define SC_MEDIUM_FONT(fontSize) [UIFont fontWithName:@"Whitney-MediumSC" size:fontSize];
//#else
//    #define LIGHT_FONT(fontSize) [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
//    #define SC_LIGHT_FONT(fontSize) [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
//    #define MEDIUM_FONT(fontSize) [UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize];
//    #define SC_MEDIUM_FONT(fontSize) [UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize];
//#endif


@interface FontProperties : NSObject

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
