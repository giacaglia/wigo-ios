//
//  NSObject+WGTracker.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Globals.h"

#ifdef DEBUG
static NSString *analyticsString = @"https://blade-analytics.herokuapp.com/wigo/dev/track?key=0i9u4r98jfg";
#else
static NSString *analyticsString = @"https://blade-analytics.herokuapp.com/wigo/dev/track?key=0i9u4r98jfg";
#endif

// Object keys
#define kObjectID @"id"
#define kObjectName @"name"

// User keys
#define kUserKey @"user"
#define kTargetUserKey @"target_user"
#define kUserEmailKey @"email"
#define kUserGenderKey @"gender"
#define kUserNumFollowingKey @"num_following"
#define kUserNumFollowersKey @"num_followers"
#define kUserPeriodWentOutKey @"period_went_out"

// Group keys
#define kGroupKey @"group"
#define kTargetGroupKey @"target_group"
#define kGroupLockedKey @"locked"
#define kGroupNumMembersKey @"num_members"

// Client metadata keys
#define kClientKey @"client"
#define kRemoteAddress @"remote_addr"
#define kUserAgent @"user_agent"
#define kOS @"os"

// Application Information keys
#define kApplicationKey @"application"
#define kAppNameKey @"name"
#define kVersionKey @"version"
#define kPlatformKey @"platform"

// Form keys
#define kTimeKey @"time"
#define kTypeKey @"type"
#define kCategoryKey @"category"
#define kSessionKey @"session_id"

//Event keys
#define kEventKey @"event"
#define KNumAttendingKey @"num_attending"

//Event Message keys
#define kEventMesssageKey @"event_message"
#define kMediaMimeTypeKey @"media_mime_type"
#define kUpVotesKey @"up_votes"

#define kTypeKey @"type"
#define kCategoryKey @"category"
#define kViewID @"view_id"
#define kViewName @"view_name"
#define kSubviewID @"sub_view_id"
#define kSubviewName @"sub_view_name"
#define kPreviousViewID @"previous_view_id"
#define kPreviousViewName @"previous_name"

@interface WGTracker : NSObject

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSMutableDictionary *mutDict;
@property (nonatomic, strong) NSNumber *dispatchInterval; // Time in seconds
@property (nonatomic, strong) NSMutableArray *batchedInfo;
-(void)setValue:(id)value forKey:(NSString *)key;
-(void)remove:(NSString *)key;
-(void)setGroup:(WGGroup *)group;
-(void)setUser:(WGUser *)user;
-(void)postViewWithName:(NSString *)viewName;
-(void)postActionWithName:(NSString *)actionName;
- (void)postActionWithName:(NSString *)actionName
               andCategory:(NSString *)category;
+(NSString *)getTimeNow;

@end
