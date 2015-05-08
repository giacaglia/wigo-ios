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


// Tagging views
+ (void)tagView:(NSString *)viewName
 withTargetUser:(WGUser *)targetUser;
+(void)tagView:(NSString *)viewName
withTargetGroup:(WGGroup *)targetGroup;
+(void) tagView:(NSString *)viewName;


// Tagging actions
+ (void)tagAction:(NSString *)actionName
           atView:(NSString *)viewName
   withTargetUser:(WGUser *)targetUser;
+ (void)tagAction:(NSString *)actionName
           atView:(NSString *)viewName;
+(void)tagAction:(NSString *)actionName
   withTargetUser:(WGUser *)targetUser;
+(void) tagAction:(NSString *)actionName;

+(void) tagEvent:(NSString *)name;
+(void) tagEvent:(NSString *)name withDetails:(NSDictionary *)details;
+(void) tagScreen:(NSString *)name;
+(void) setUser:(WGUser *)user;

@end