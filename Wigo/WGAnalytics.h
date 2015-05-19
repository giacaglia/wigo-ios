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
#import "WGEventMessage.h"

@interface WGAnalytics : NSObject

// tagging subview
+ (void)tagSubview:(NSString *)subviewName
            atView:(NSString *)viewName
    withTargetUser:(WGUser *)targetUser;

+ (void)tagViewWithNoUser:(NSString *)viewName;

// Tagging view
+ (void)tagView:(NSString *)viewName
 withTargetUser:(WGUser *)targetUser;

// tagging actions
+ (void)tagAction:(NSString *)actionName
        atSubview:(NSString *)subviewName
           atView:(NSString *)viewName
   withTargetUser:(WGUser *)targetUser;

// Tagging action
+ (void)tagAction:(NSString *)actionName
           atView:(NSString *)viewName
    andTargetUser:(WGUser *)targetUser
          atEvent:(WGEvent *)event
  andEventMessage:(WGEventMessage *)eventMessage;

+ (void)tagViewAction:(NSString *)actionName
               atView:(NSString *)viewName
        andTargetUser:(WGUser *)targetUser
              atEvent:(WGEvent *)event
      andEventMessage:(WGEventMessage *)eventMessage;

+ (void)tagViewAction:(NSString *)actionName
            atSubview:(NSString *)subviewName
               atView:(NSString *)viewName
       withTargetUser:(WGUser *)targetUser;

+(void) tagEvent:(NSString *)name;
+(void) tagEvent:(NSString *)name withDetails:(NSDictionary *)details;
+(void) tagScreen:(NSString *)name;
+(void) setUser:(WGUser *)user;


@end