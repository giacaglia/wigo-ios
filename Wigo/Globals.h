//
//  Globals.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/15/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "Profile.h"
#import "User.h"
#import "Party.h"
#import "Network.h"
#import "Event.h"
#import "Message.h"
#import "Time.h"

#import "FontProperties.h"


//#ifdef DEBUG
//#define NSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#else
//#define NSLog(...)
//#endif
#define MAX_LENGTH_BIO 110

@protocol Globals <NSObject>

@end
