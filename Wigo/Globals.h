//
//  Globals.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Crashlytics/Crashlytics.h>
#import "UIImageView+ImageArea.h"

#import "FontProperties.h"
#import "WGAnalytics.h"

#import "WGSpinnerView.h"
#import "FLAnimatedImage.h"
#import "FLAnimatedImageView.h"
#import "NSString+URLEncoding.h"
#import "NSObject-CancelableScheduledBlock.h"
#import "UIImage+Resize.h"
#import "UIColor+ImageExtension.h"

#import "WGProfile.h"
#import "WGEvent.h"
#import "WGEventAttendee.h"
#import "WGEventMessage.h"
#import "WGMessage.h"
#import "WGNotification.h"
#import "WGCollection.h"
#import "WGCollectionArray.h"
#import "NSDate+WGDate.h"
#import "WGFollow.h"
#import "NetworkFetcher.h"
#import "TabBarAuxiliar.h"
#import "LayerHelper.h"

#if !defined(StringOrEmpty)
#define StringOrEmpty(A)  ({ __typeof__(A) __a = (A); __a ? __a : @""; })
#endif

static NSString * const collectionViewCellIdentifier = @"CollectionViewCellIdentifier";
static NSString * const headerCellIdentifier = @"HeaderContentCell";

/* #ifdef DEBUG
#define NSLog(x, ...) NSLog(@"%s %d: " x, __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define NSLog(x, ...) CLSLog(@"%s %d: " x, __FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif */

#define isiPhone4s ([[UIScreen mainScreen] bounds].size.height == 480)?TRUE:FALSE
#define isiPhone5  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE
#define isIphone6 ([[UIScreen mainScreen] bounds].size.height == 667)?TRUE:FALSE
#define isIphone6Plus ([[UIScreen mainScreen] bounds].size.height == 736)?TRUE:FALSE
#define MAX_LENGTH_BIO 110
#define PEOPLEVIEW_HEIGHT_OF_CELLS 80
#define kGoHereState @"goHereState"

static NSString * const kWGTabHome = @"WGTabHome";
static NSString * const kWGTabChat = @"WGTabChat";
static NSString * const kWGTabDiscover = @"WGTabDiscover";
static NSString * const kWGTabProfile = @"WGTabProfile";

@protocol Globals <NSObject>

@end

@protocol WGViewController <NSObject>

- (void)updateViewWithOptions:(NSDictionary *)options;

@end

