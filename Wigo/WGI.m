//
//  NSObject+WGI.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGI.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

#ifdef DEBUG
static NSString *analyticsString = @"https://blade-analytics.herokuapp.com/wigo/dev/track";
#else
static NSString *analyticsString = @"https://blade-analytics.herokuapp.com/wigo/dev/track";
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

static NSMutableDictionary * sharedMutableDict;

@implementation WGI : NSObject

+ (void)setSessionID {
    [WGI setValue:[[NSUUID UUID] UUIDString] forKey:kSessionKey];
}

+ (void)setApplicationInformation {
    NSMutableDictionary *applicationDict = [NSMutableDictionary new];
    [applicationDict setValue:@"wigo" forKey:kAppNameKey];
    [applicationDict setValue:(NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:kVersionKey];
    [applicationDict setValue:@"iOS" forKey:kPlatformKey];
    [WGI setValue:applicationDict forKey:kApplicationKey];
}

+ (void)setClientMetadata {
    NSMutableDictionary *clientMeta = [NSMutableDictionary new];
    [clientMeta setValue:[WGI getIPAddress] forKey:kRemoteAddress];
    [clientMeta setValue:[[UIDevice currentDevice] systemVersion] forKey:kOS];
    [WGI setValue:clientMeta forKey:kClientKey];
}

+ (void)setGroup:(WGGroup *)group {
    NSMutableDictionary *groupDict = [NSMutableDictionary new];
    [groupDict setValue:group.id forKey:kObjectID];
    [groupDict setValue:group.name forKey:kObjectName];
    [groupDict setValue:group.locked forKey:kGroupLockedKey];
    [groupDict setValue:group.numMembers forKey:kGroupNumMembersKey];
    [WGI setValue:groupDict forKey:kGroupKey];
}

+ (void)setTargetGroup:(WGGroup *)targetGroup {
    NSMutableDictionary *targetGroupDict = [NSMutableDictionary new];
    [targetGroupDict setValue:targetGroup.id forKey:kObjectID];
    [targetGroupDict setValue:targetGroup.name forKey:kObjectName];
    [targetGroupDict setValue:targetGroup.locked forKey:kGroupLockedKey];
    [targetGroupDict setValue:targetGroup.numMembers forKey:kGroupNumMembersKey];
    [WGI setValue:targetGroupDict forKey:kTargetGroupKey];
}

+ (void)setUser:(WGUser *)user {
    NSMutableDictionary *userDict = [NSMutableDictionary new];
    [userDict setValue:user.id forKey:kObjectID];
    [userDict setValue:user.email forKey:kUserEmailKey];
    [userDict setValue:user.fullName forKey:kObjectName];
    [userDict setValue:user.genderName forKey:kUserGenderKey];
    [userDict setValue:user.numFollowing forKey:kUserNumFollowingKey];
    [userDict setValue:user.numFollowers forKey:kUserNumFollowersKey];
    [userDict setValue:(NSNumber *)[user objectForKey:@"period_went_out"] forKey:kUserPeriodWentOutKey];
    [WGI setValue:userDict forKey:kUserKey];
}

+ (void)setTargetUser:(WGUser *)targetUser {
    NSMutableDictionary *userDict = [NSMutableDictionary new];
    [userDict setValue:targetUser.id forKey:kObjectID];
    [userDict setValue:targetUser.email forKey:kUserEmailKey];
    [userDict setValue:targetUser.fullName forKey:kObjectName];
    [userDict setValue:targetUser.genderName forKey:kUserGenderKey];
    [userDict setValue:targetUser.numFollowing forKey:kUserNumFollowingKey];
    [userDict setValue:targetUser.numFollowers forKey:kUserNumFollowersKey];
    [userDict setValue:(NSNumber *)[targetUser objectForKey:@"period_went_out"] forKey:kUserPeriodWentOutKey];
    [WGI setValue:userDict forKey:kTargetUserKey];
}

+(void)setValue:(id)value forKey:(NSString *)key {
    if (key == nil || [key isKindOfClass:[NSNull class]]) return;
    [sharedMutableDict setValue:value forKey:key];
}

+ (void)setEvent:(WGEvent *)event {
    NSMutableDictionary *eventDict = [NSMutableDictionary new];
    [eventDict setValue:event.id forKey:kObjectID];
    [eventDict setValue:event.name forKey:kObjectName];
    [eventDict setValue:event.numAttending forKey:KNumAttendingKey];
    [sharedMutableDict setValue:eventDict forKey:kEventKey];
}

+ (void)setEventMessage:(WGEventMessage *)eventMessage {
    NSMutableDictionary *eventMsgDict = [NSMutableDictionary new];
    [eventMsgDict setValue:eventMessage.id forKey:kObjectID];
    [eventMsgDict setValue:eventMessage.mediaMimeType forKey:kMediaMimeTypeKey];
    [eventMsgDict setValue:eventMessage.upVotes forKey:kUpVotesKey];
    [sharedMutableDict setValue:eventMsgDict forKey:kEventMesssageKey];
}

+ (void)postActionWithName:(NSString *)actionName
               andCategory:(NSString *)category {
    [sharedMutableDict setValue:category forKey:kCategoryKey];
    [WGI postActionWithName:actionName];
}

+ (void)postActionWithName:(NSString *)actionName {
    [sharedMutableDict setValue:actionName forKey:kTypeKey];
    [WGI postDictionary:sharedMutableDict];
}


+(void)postDictionary:(NSDictionary *)dict {
    [sharedMutableDict setValue:[WGI getTimeNow] forKey:kTimeKey];

    
    [WGApi postURL:analyticsString
    withParameters:sharedMutableDict
        andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        
    }];

}

#pragma mark - Helper Functions 

+ (NSString *)getTimeNow {
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    return [outputFormatter stringFromDate:now];
}

+ (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

@end
