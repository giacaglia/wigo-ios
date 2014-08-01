//
//  EventAnalytics.h
//  Classy
//
//  Created by Dennis Doughty on 7/25/14.
//  Copyright (c) 2014 WiGo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventAnalytics : NSObject

+ (void) tagEvent:(NSString *)name;
+ (void) tagEvent:(NSString *)name withDetails:(NSDictionary *)details;
+ (void) tagScreen:(NSString *)name;

@end
