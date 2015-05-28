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
static NSString *analyticsString = @"https://blade-analytics.herokuapp.com/wigo2/dev/track?key=7efgskg0043kfo";
#else
static NSString *analyticsString = @"https://blade-analytics.herokuapp.com/wigo2/production/track?key=7efgskg0043kfo";
#endif


// Object keys
#define kObjectID @"id"
#define kObjectName @"name"

// User keys
#define kUserKey @"user"
#define kTargetUserKey @"target_user"
#define kUserEmailKey @"email"
#define kUserGenderKey @"gender"
#define kUserNumFriendsKey @"num_friends"
#define kUserPeriodWentOutKey @"period_went_out"

// Group keys
#define kGroupKey @"group"
#define kTargetGroupKey @"target_group"
#define kGroupLockedKey @"locked"
#define kGroupNumMembersKey @"num_members"

// Client metadata keys
#define kClientKey @"client"
#define kVendorIDKey @"vendor_id"
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
#define kOwnerIDKey @"owner_id"

//Event Message keys
#define kEventMesssageKey @"event_message"
#define kMediaMimeTypeKey @"media_mime_type"
#define kUpVotesKey @"up_votes"
#define kUserIDKey @"user_id"

#define kTypeKey @"type"
#define kViewType @"view"
#define kSubViewType @"sub_view"
#define kActionType @"action"
#define kViewActionType @"view_action"
#define kCategoryKey @"category"
#define kViewIDKey @"view_id"
#define kViewNameKey @"view_name"
#define kSubviewIDKey @"sub_view_id"
#define kSubviewNameKey @"sub_view_name"
#define kPreviousViewID @"previous_view_id"
#define kPreviousViewName @"previous_view_name"

@interface WGTracker : NSObject

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) float dispatchInterval; // Time in seconds
@property (nonatomic, strong) NSMutableArray *batchedInfo;
@property (nonatomic, strong) NSString *defaultSessionID;



-(void)postSubviewWithName:(NSString *)subviewName
                withViewID:(NSString *)subviewID
            atViewWithName:(NSString *)viewName
                 andViewID:(NSString *)viewID
                  andGroup:(WGGroup *)group
            andTargetGroup:(WGGroup *)targetGroup
                   andUser:(WGUser *)user
             andTargetUser:(WGUser *)targetUser;

-(void)postViewWithName:(NSString *)viewName
              andViewID:(NSString *)viewID
               andGroup:(WGGroup *)group
         andTargetGroup:(WGGroup *)targetGroup
                andUser:(WGUser *)user
          andTargetUser:(WGUser *)targetUser;


- (void)postAction:(NSString *)actionName
         atSubview:(NSString *)subviewName
      andSubviewID:(NSString *)subviewID
            atView:(NSString *)viewName
         andViewID:(NSString *)viewID
          andGroup:(WGGroup *)group
    andTargetGroup:(WGGroup *)targetGroup
           andUser:(WGUser *)user
     andTargetUser:(WGUser *)targetUser
           atEvent:(WGEvent *)event
    atEventMessage:(WGEventMessage *)eventMessage;

- (void)postAction:(NSString *)actionName
            atView:(NSString *)viewName
         andViewID:(NSString *)viewID
          andGroup:(WGGroup *)group
    andTargetGroup:(WGGroup *)targetGroup
           andUser:(WGUser *)user
     andTargetUser:(WGUser *)targetUser;

- (void)postViewAction:(NSString *)actionName
             atSubview:(NSString *)subviewName
          andSubviewID:(NSString *)subviewID
                atView:(NSString *)viewName
             andViewID:(NSString *)viewID
              andGroup:(WGGroup *)group
        andTargetGroup:(WGGroup *)targetGroup
               andUser:(WGUser *)user
         andTargetUser:(WGUser *)targetUser
               atEvent:(WGEvent *)event
        atEventMessage:(WGEventMessage *)eventMessage;

- (void)postViewAction:(NSString *)actionName
                atView:(NSString *)viewName
             andViewID:(NSString *)viewID
              andGroup:(WGGroup *)group
        andTargetGroup:(WGGroup *)targetGroup
               andUser:(WGUser *)user
         andTargetUser:(WGUser *)targetUser;


+(NSString *)getTimeNow;
@end
