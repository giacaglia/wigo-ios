//
//  Globals.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+ImageArea.h"

#import "Profile.h"
#import "User.h"
#import "Party.h"
#import "Network.h"
#import "Event.h"
#import "Message.h"
#import "Time.h"

#import "FontProperties.h"


#import "EventAnalytics.h"

#import "WiGoSpinnerView.h"
#import "FLAnimatedImage.h"
#import "FLAnimatedImageView.h"
#import "NSString+URLEncoding.h"
#import "NSObject-CancelableScheduledBlock.h"

#if !defined(StringOrEmpty)
#define StringOrEmpty(A)  ({ __typeof__(A) __a = (A); __a ? __a : @""; })
#endif

static NSString * const collectionViewCellIdentifier = @"CollectionViewCellIdentifier";
static NSString * const headerCellIdentifier = @"HeaderContentCell";

//#ifdef DEBUG
//#define NSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#else
//#define NSLog(...)
//#endif
#define isiPhone5  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE
#define MAX_LENGTH_BIO 110
#define PEOPLEVIEW_HEIGHT_OF_CELLS 80
#define kGoHereState @"goHereState"

@protocol Globals <NSObject>

@end
