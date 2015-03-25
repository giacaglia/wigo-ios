//
//  NSObject+WGI.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Globals.h"
#import "WGTracker.h"

@interface WGI : NSObject

+(WGTracker *) defaultTracker;
+(void)openedTheApp;
+(void)closedTheApp;

@end
