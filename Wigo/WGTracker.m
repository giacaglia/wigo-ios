//
//  NSObject+WGTracker.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGTracker.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#define kViewType @"view"
#define kActionType @"action"

static NSString *previousViewName;

@implementation WGTracker : NSObject

- (id)init {
    self = [super init];
    if (self) {
        [self setApplicationInformation];
        [self setClientMetadata];
        self.dispatchInterval = 30.0f;
        self.batchedInfo = [NSMutableArray new];
        [NSTimer scheduledTimerWithTimeInterval:self.dispatchInterval
                                         target:self
                                       selector:@selector(sendInfo)
                                       userInfo:nil
                                        repeats:YES];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (self.mutDict == nil  ||
        [self.mutDict isKindOfClass:[NSNull class]]) {
        self.mutDict = [NSMutableDictionary new];
    }
    if (key == nil || [key isKindOfClass:[NSNull class]]) return;
    [self.mutDict setValue:value forKey:key];
}

- (void)remove:(NSString *)key {
    [self.mutDict removeObjectForKey:key];
}

- (void)setApplicationInformation {
    NSMutableDictionary *applicationDict = [NSMutableDictionary new];
    [applicationDict setValue:@"wigo" forKey:kAppNameKey];
    [applicationDict setValue:(NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:kVersionKey];
    [applicationDict setValue:@"iOS" forKey:kPlatformKey];
    [self setValue:applicationDict forKey:kApplicationKey];
}

- (void)setClientMetadata {
    NSMutableDictionary *clientMeta = [NSMutableDictionary new];
    [clientMeta setValue:[WGTracker getIPAddress] forKey:kRemoteAddress];
    [clientMeta setValue:[[UIDevice currentDevice] systemVersion] forKey:kOS];
    [self setValue:clientMeta forKey:kClientKey];
}


- (void)setGroup:(WGGroup *)group {
    NSMutableDictionary *groupDict = [NSMutableDictionary new];
    [groupDict setValue:group.id forKey:kObjectID];
    [groupDict setValue:group.name forKey:kObjectName];
    [groupDict setValue:group.locked forKey:kGroupLockedKey];
    [groupDict setValue:group.numMembers forKey:kGroupNumMembersKey];
    [self setValue:groupDict forKey:kGroupKey];
}

- (void)setTargetGroup:(WGGroup *)targetGroup {
    NSMutableDictionary *targetGroupDict = [NSMutableDictionary new];
    [targetGroupDict setValue:targetGroup.id forKey:kObjectID];
    [targetGroupDict setValue:targetGroup.name forKey:kObjectName];
    [targetGroupDict setValue:targetGroup.locked forKey:kGroupLockedKey];
    [targetGroupDict setValue:targetGroup.numMembers forKey:kGroupNumMembersKey];
    [self setValue:targetGroupDict forKey:kTargetGroupKey];
}

- (void)setUser:(WGUser *)user {
    NSMutableDictionary *userDict = [NSMutableDictionary new];
    [userDict setValue:user.id forKey:kObjectID];
    [userDict setValue:user.email forKey:kUserEmailKey];
    [userDict setValue:user.genderName forKey:kUserGenderKey];
    [userDict setValue:user.numFollowing forKey:kUserNumFollowingKey];
    [userDict setValue:user.numFollowers forKey:kUserNumFollowersKey];
    [userDict setValue:(NSNumber *)[user objectForKey:@"period_went_out"] forKey:kUserPeriodWentOutKey];
    [self setValue:userDict forKey:kUserKey];
}

- (void)setTargetUser:(WGUser *)targetUser {
    NSMutableDictionary *userDict = [NSMutableDictionary new];
    [userDict setValue:targetUser.id forKey:kObjectID];
    [userDict setValue:targetUser.email forKey:kUserEmailKey];
    [userDict setValue:targetUser.fullName forKey:kObjectName];
    [userDict setValue:targetUser.genderName forKey:kUserGenderKey];
    [userDict setValue:targetUser.numFollowing forKey:kUserNumFollowingKey];
    [userDict setValue:targetUser.numFollowers forKey:kUserNumFollowersKey];
    [userDict setValue:(NSNumber *)[targetUser objectForKey:@"period_went_out"] forKey:kUserPeriodWentOutKey];
    [self setValue:userDict forKey:kTargetUserKey];
}


- (void)setEvent:(WGEvent *)event {
    NSMutableDictionary *eventDict = [NSMutableDictionary new];
    [eventDict setValue:event.id forKey:kObjectID];
    [eventDict setValue:event.name forKey:kObjectName];
    [eventDict setValue:event.numAttending forKey:KNumAttendingKey];
    [self setValue:eventDict forKey:kEventKey];
}

- (void)setEventMessage:(WGEventMessage *)eventMessage {
    NSMutableDictionary *eventMsgDict = [NSMutableDictionary new];
    [eventMsgDict setValue:eventMessage.id forKey:kObjectID];
    [eventMsgDict setValue:eventMessage.mediaMimeType forKey:kMediaMimeTypeKey];
    [eventMsgDict setValue:eventMessage.upVotes forKey:kUpVotesKey];
    [self setValue:eventMsgDict forKey:kEventMesssageKey];
}

- (void)postAction:(NSString *)actionName
            atView:(NSString *)viewName {
    if (previousViewName == nil ||
        [previousViewName isKindOfClass:[NSNull class]]) {
        previousViewName = viewName;
    }
    else {
        [self setValue:previousViewName forKey:kPreviousViewName];
    }
    [self setValue:viewName forKey:kViewName];
    [self postAction:actionName];
    [self remove:kViewName];
    [self remove:kPreviousViewName];
}


- (void)postAction:(NSString *)actionName {
    [self setValue:kActionType forKey:kTypeKey];
    [self setValue:actionName forKey:kCategoryKey];
    [self postDictionary];
    [self remove:kTypeKey];
    [self remove:kCategoryKey];
    [self remove:kTargetGroupKey];
    [self remove:kTargetUserKey];
}

- (void)postViewWithName:(NSString *)viewName {
    [self setValue:kViewType forKey:kTypeKey];
    if (previousViewName == nil ||
        [previousViewName isKindOfClass:[NSNull class]]) {
        previousViewName = viewName;
    }
    else {
        [self setValue:previousViewName forKey:kPreviousViewName];
    }
    [self setValue:viewName forKey:kViewName];
    [self postDictionary];
    [self remove:kTypeKey];
    [self remove:kPreviousViewName];
    [self remove:kViewName];
    [self remove:kTargetGroupKey];
    [self remove:kTargetUserKey];
}


- (void)postDictionary {
    [self setValue:[WGTracker getTimeNow] forKey:kTimeKey];
    [self.batchedInfo addObject:self.mutDict];
    [self queueRequest];
    
}

- (void)queueRequest {
    [self.batchedInfo addObject:self.mutDict];
}

- (void)sendInfo {
//    if (self.batchedInfo.count == 0) return;
//    [WGApi postURL:analyticsString
//    withParameters:self.batchedInfo
//        andHandler:^(NSDictionary *jsonResponse, NSError *error) {
//            
//        }];
//    // RESET SETTINGS
//    self.batchedInfo = [NSMutableArray new];
}


#pragma mark - Helpers

+ (NSString *)getTimeNow {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
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