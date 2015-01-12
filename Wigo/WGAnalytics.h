//
//  WGAnalytics.h
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "WGProfile.h"

@interface WGAnalytics : NSObject

+(void) tagEvent:(NSString *)name;
+(void) tagEvent:(NSString *)name withDetails:(NSDictionary *)details;
+(void) tagScreen:(NSString *)name;
+(void) setUser:(WGUser *)user;

@end
