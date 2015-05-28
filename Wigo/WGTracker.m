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
#define kBatchedInfoKey @"batched_info"

static NSString *previousViewName;
static NSString *previousViewID;
static NSString *sessionID;

@implementation WGTracker : NSObject

- (id)init {
    self = [super init];
    if (self) {
        self.dispatchInterval = 9.0f;
        // RESET SETTINGS
        if ([[NSUserDefaults standardUserDefaults] valueForKey:kBatchedInfoKey])
            self.batchedInfo = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] valueForKey:kBatchedInfoKey]];
        else self.batchedInfo = [NSMutableArray new];
        [NSTimer scheduledTimerWithTimeInterval:self.dispatchInterval
                                         target:self
                                       selector:@selector(sendInfo)
                                       userInfo:nil
                                        repeats:YES];
    }
    return self;
}

- (void)setDefaultSessionID:(NSString *)defaultSessionID {
    sessionID = defaultSessionID;
}

- (void)setApplicationInformationForDictionary:(NSMutableDictionary *)mutDict {
    NSMutableDictionary *applicationDict = [NSMutableDictionary new];
    [applicationDict setValue:@"wigo" forKey:kAppNameKey];
    [applicationDict setValue:(NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:kVersionKey];
    [applicationDict setValue:@"iOS" forKey:kPlatformKey];
    [mutDict setValue:applicationDict forKey:kApplicationKey];
}

- (void)setClientMetadataforDictionary:(NSMutableDictionary *)mutDict
{
    NSMutableDictionary *clientMeta = [NSMutableDictionary new];
    [clientMeta setValue:[WGTracker getIPAddress] forKey:kRemoteAddress];
    [clientMeta setValue:[[UIDevice currentDevice] systemVersion] forKey:kOS];
    [clientMeta setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:kVendorIDKey];
    [mutDict setValue:clientMeta forKey:kClientKey];
}

- (void)setGroup:(WGGroup *)group
   forDictionary:(NSMutableDictionary *)mutDict
{
    NSMutableDictionary *groupDict = [NSMutableDictionary new];
    [groupDict setValue:group.id forKey:kObjectID];
    [groupDict setValue:group.name forKey:kObjectName];
    [groupDict setValue:group.locked forKey:kGroupLockedKey];
    [groupDict setValue:group.numMembers forKey:kGroupNumMembersKey];
    [mutDict setValue:groupDict forKey:kGroupKey];
}

- (void)setTargetGroup:(WGGroup *)targetGroup
         forDictionary:(NSMutableDictionary *)mutDict
{
    NSMutableDictionary *targetGroupDict = [NSMutableDictionary new];
    [targetGroupDict setValue:targetGroup.id forKey:kObjectID];
    [targetGroupDict setValue:targetGroup.name forKey:kObjectName];
    [targetGroupDict setValue:targetGroup.locked forKey:kGroupLockedKey];
    [targetGroupDict setValue:targetGroup.numMembers forKey:kGroupNumMembersKey];
    [mutDict setValue:targetGroupDict forKey:kTargetGroupKey];
}

- (void)setUser:(WGUser *)user
  forDictionary:(NSMutableDictionary *)mutDict {
    NSMutableDictionary *userDict = [NSMutableDictionary new];
    [userDict setValue:user.id forKey:kObjectID];
    [userDict setValue:user.email forKey:kUserEmailKey];
    [userDict setValue:user.genderName forKey:kUserGenderKey];
    [userDict setValue:user.numFriends forKey:kUserNumFriendsKey];
    [userDict setValue:(NSNumber *)[user objectForKey:@"period_went_out"] forKey:kUserPeriodWentOutKey];
    [mutDict setValue:userDict forKey:kUserKey];
}

- (void)setTargetUser:(WGUser *)targetUser
        forDictionary:(NSMutableDictionary *)mutDict
{
    NSMutableDictionary *userDict = [NSMutableDictionary new];
    [userDict setValue:targetUser.id forKey:kObjectID];
    [userDict setValue:targetUser.email forKey:kUserEmailKey];
    [userDict setValue:targetUser.fullName forKey:kObjectName];
    [userDict setValue:targetUser.genderName forKey:kUserGenderKey];
    [userDict setValue:targetUser.numFriends forKey:kUserNumFriendsKey];
    [userDict setValue:(NSNumber *)[targetUser objectForKey:@"period_went_out"] forKey:kUserPeriodWentOutKey];
    [mutDict setValue:userDict forKey:kTargetUserKey];
}

- (void)setEvent:(WGEvent *)event
   forDictionary:(NSMutableDictionary *)mutDict {
    NSMutableDictionary *eventDict = [NSMutableDictionary new];
    [eventDict setValue:event.id forKey:kObjectID];
    [eventDict setValue:event.name forKey:kObjectName];
    [eventDict setValue:event.numAttending forKey:KNumAttendingKey];
    if (event.owner) [eventDict setValue:event.owner.id forKey:kOwnerIDKey];
    [mutDict setValue:eventDict forKey:kEventKey];
}

- (void)setEventMessage:(WGEventMessage *)eventMessage
          forDictionary:(NSMutableDictionary *)mutDict {
    NSMutableDictionary *eventMsgDict = [NSMutableDictionary new];
    [eventMsgDict setValue:eventMessage.id forKey:kObjectID];
    [eventMsgDict setValue:eventMessage.mediaMimeType forKey:kMediaMimeTypeKey];
    [eventMsgDict setValue:eventMessage.upVotes forKey:kUpVotesKey];
    if (eventMessage.user) [eventMsgDict setValue:eventMessage.user.id forKey:kUserIDKey];
    [mutDict setValue:eventMsgDict forKey:kEventMesssageKey];
}

-(void)postSubviewWithName:(NSString *)subviewName
                withViewID:(NSString *)subviewID
            atViewWithName:(NSString *)viewName
                 andViewID:(NSString *)viewID
                  andGroup:(WGGroup *)group
            andTargetGroup:(WGGroup *)targetGroup
                   andUser:(WGUser *)user
             andTargetUser:(WGUser *)targetUser
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableDictionary *mutDict = [NSMutableDictionary new];
        [self setApplicationInformationForDictionary:mutDict];
        [self setClientMetadataforDictionary:mutDict];
        [mutDict setValue:kSubViewType forKey:kTypeKey];
        [mutDict setValue:sessionID forKey:kSessionKey];
        if (user) [self setUser:user forDictionary:mutDict];
        if (group) [self setGroup:group forDictionary:mutDict];
        if (targetUser) [self setTargetUser:targetUser forDictionary:mutDict];
        if (targetGroup) [self setTargetGroup:targetGroup forDictionary:mutDict];
        if (viewID) [mutDict setValue:viewID forKey:kViewIDKey];
        if (previousViewName) {
            [mutDict setValue:previousViewName forKey:kPreviousViewName];
        }
        previousViewName = viewName;
        if (previousViewID) {
            [mutDict setValue:previousViewID forKey:kPreviousViewID];
        }
        previousViewID = viewID;
        [mutDict setValue:viewName forKey:kViewNameKey];
        [mutDict setValue:subviewName forKey:kCategoryKey];
        [mutDict setValue:subviewName forKey:kSubviewNameKey];
        [mutDict setValue:subviewID forKey:kSubviewIDKey];
        [mutDict setValue:[WGTracker getTimeNow] forKey:kTimeKey];
        @synchronized(self.batchedInfo) {
            [self.batchedInfo addObject:mutDict];
            [[NSUserDefaults standardUserDefaults] setValue:self.batchedInfo forKey:kBatchedInfoKey];
        }
    });
}


-(void)postViewWithName:(NSString *)viewName
              andViewID:(NSString *)viewID
               andGroup:(WGGroup *)group
         andTargetGroup:(WGGroup *)targetGroup
                andUser:(WGUser *)user
          andTargetUser:(WGUser *)targetUser
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableDictionary *mutDict = [NSMutableDictionary new];
        [self setApplicationInformationForDictionary:mutDict];
        [self setClientMetadataforDictionary:mutDict];
        [mutDict setValue:kViewType forKey:kTypeKey];
        [mutDict setValue:sessionID forKey:kSessionKey];
        if (user) [self setUser:user forDictionary:mutDict];
        if (group) [self setGroup:group forDictionary:mutDict];
        if (targetUser) [self setTargetUser:targetUser forDictionary:mutDict];
        if (targetGroup) [self setTargetGroup:targetGroup forDictionary:mutDict];
        if (viewID) [mutDict setValue:viewID forKey:kViewIDKey];
        if (previousViewName) [mutDict setValue:previousViewName forKey:kPreviousViewName];
        previousViewName = viewName;
        if (previousViewID) [mutDict setValue:previousViewID forKey:kPreviousViewID];
        previousViewID = viewID;
        [mutDict setValue:viewName forKey:kViewNameKey];
        [mutDict setValue:viewName forKey:kCategoryKey];
        [mutDict setValue:[WGTracker getTimeNow] forKey:kTimeKey];
        @synchronized(self.batchedInfo) {
            [self.batchedInfo addObject:mutDict];
            [[NSUserDefaults standardUserDefaults] setValue:self.batchedInfo forKey:kBatchedInfoKey];
        }
    });
}


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
    atEventMessage:(WGEventMessage *)eventMessage{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableDictionary *mutDict = [NSMutableDictionary new];
        [self setApplicationInformationForDictionary:mutDict];
        [self setClientMetadataforDictionary:mutDict];
        [mutDict setValue:kActionType forKey:kTypeKey];
        [mutDict setValue:sessionID forKey:kSessionKey];
        if (user) [self setUser:user forDictionary:mutDict];
        if (group) [self setGroup:group forDictionary:mutDict];
        if (targetUser) [self setTargetUser:targetUser forDictionary:mutDict];
        if (targetGroup) [self setTargetGroup:targetGroup forDictionary:mutDict];
        if (viewID) [mutDict setValue:viewID forKey:kViewIDKey];
        if (event) [self setEvent:event forDictionary:mutDict];
        if (eventMessage) [self setEventMessage:eventMessage forDictionary:mutDict];
        if (previousViewName) [mutDict setValue:previousViewName forKey:kPreviousViewName];
        previousViewName = viewName;
        if (previousViewID) [mutDict setValue:previousViewID forKey:kPreviousViewID];
        previousViewID = viewID;
        [mutDict setValue:viewName forKey:kViewNameKey];
        [mutDict setValue:subviewName forKey:kSubviewNameKey];
        [mutDict setValue:subviewID forKey:kSubviewIDKey];
        [mutDict setValue:actionName forKey:kCategoryKey];
        [mutDict setValue:[WGTracker getTimeNow] forKey:kTimeKey];
        @synchronized(self.batchedInfo) {
            [self.batchedInfo addObject:mutDict];
            [[NSUserDefaults standardUserDefaults] setValue:self.batchedInfo forKey:kBatchedInfoKey];
        }
    });
}


- (void)postAction:(NSString *)actionName
            atView:(NSString *)viewName
         andViewID:(NSString *)viewID
          andGroup:(WGGroup *)group
    andTargetGroup:(WGGroup *)targetGroup
           andUser:(WGUser *)user
     andTargetUser:(WGUser *)targetUser {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableDictionary *mutDict = [NSMutableDictionary new];
        [self setApplicationInformationForDictionary:mutDict];
        [self setClientMetadataforDictionary:mutDict];
        [mutDict setValue:kActionType forKey:kTypeKey];
        [mutDict setValue:sessionID forKey:kSessionKey];
        if (user) [self setUser:user forDictionary:mutDict];
        if (group) [self setGroup:group forDictionary:mutDict];
        if (targetUser) [self setTargetUser:targetUser forDictionary:mutDict];
        if (targetGroup) [self setTargetGroup:targetGroup forDictionary:mutDict];
        if (viewID) [mutDict setValue:viewID forKey:kViewIDKey];
        if (previousViewName) [mutDict setValue:previousViewName forKey:kPreviousViewName];
        previousViewName = viewName;
        if (previousViewID) [mutDict setValue:previousViewID forKey:kPreviousViewID];
        previousViewID = viewID;
        [mutDict setValue:viewName forKey:kViewNameKey];
        [mutDict setValue:actionName forKey:kCategoryKey];
        [mutDict setValue:[WGTracker getTimeNow] forKey:kTimeKey];
        @synchronized(self.batchedInfo) {
            [self.batchedInfo addObject:mutDict];
            [[NSUserDefaults standardUserDefaults] setValue:self.batchedInfo forKey:kBatchedInfoKey];
        }
    });
}

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
        atEventMessage:(WGEventMessage *)eventMessage{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableDictionary *mutDict = [NSMutableDictionary new];
        [self setApplicationInformationForDictionary:mutDict];
        [self setClientMetadataforDictionary:mutDict];
        [mutDict setValue:kViewActionType forKey:kTypeKey];
        [mutDict setValue:sessionID forKey:kSessionKey];
        if (user) [self setUser:user forDictionary:mutDict];
        if (group) [self setGroup:group forDictionary:mutDict];
        if (targetUser) [self setTargetUser:targetUser forDictionary:mutDict];
        if (targetGroup) [self setTargetGroup:targetGroup forDictionary:mutDict];
        if (viewID) [mutDict setValue:viewID forKey:kViewIDKey];
        if (event) [self setEvent:event forDictionary:mutDict];
        if (eventMessage) [self setEventMessage:eventMessage forDictionary:mutDict];
        if (previousViewName) [mutDict setValue:previousViewName forKey:kPreviousViewName];
        previousViewName = viewName;
        if (previousViewID) [mutDict setValue:previousViewID forKey:kPreviousViewID];
        previousViewID = viewID;
        [mutDict setValue:viewName forKey:kViewNameKey];
        [mutDict setValue:subviewName forKey:kSubviewNameKey];
        [mutDict setValue:subviewID forKey:kSubviewIDKey];
        [mutDict setValue:actionName forKey:kCategoryKey];
        [mutDict setValue:[WGTracker getTimeNow] forKey:kTimeKey];
        @synchronized(self.batchedInfo) {
            [self.batchedInfo addObject:mutDict];
            [[NSUserDefaults standardUserDefaults] setValue:self.batchedInfo forKey:kBatchedInfoKey];
        }
    });
}

- (void)postViewAction:(NSString *)actionName
                atView:(NSString *)viewName
             andViewID:(NSString *)viewID
              andGroup:(WGGroup *)group
        andTargetGroup:(WGGroup *)targetGroup
               andUser:(WGUser *)user
         andTargetUser:(WGUser *)targetUser {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableDictionary *mutDict = [NSMutableDictionary new];
        [self setApplicationInformationForDictionary:mutDict];
        [self setClientMetadataforDictionary:mutDict];
        [mutDict setValue:kViewActionType forKey:kTypeKey];
        [mutDict setValue:sessionID forKey:kSessionKey];
        if (user) [self setUser:user forDictionary:mutDict];
        if (group) [self setGroup:group forDictionary:mutDict];
        if (targetUser) [self setTargetUser:targetUser forDictionary:mutDict];
        if (targetGroup) [self setTargetGroup:targetGroup forDictionary:mutDict];
        if (viewID) [mutDict setValue:viewID forKey:kViewIDKey];
        if (previousViewName) [mutDict setValue:previousViewName forKey:kPreviousViewName];
        previousViewName = viewName;
        if (previousViewID) [mutDict setValue:previousViewID forKey:kPreviousViewID];
        previousViewID = viewID;
        [mutDict setValue:viewName forKey:kViewNameKey];
        [mutDict setValue:actionName forKey:kCategoryKey];
        [mutDict setValue:[WGTracker getTimeNow] forKey:kTimeKey];
        @synchronized(self.batchedInfo) {
            [self.batchedInfo addObject:mutDict];
            [[NSUserDefaults standardUserDefaults] setValue:self.batchedInfo forKey:kBatchedInfoKey];
        }
    });
}

- (void)sendInfo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableArray *stuffToSend;
        if (self.batchedInfo.count == 0) return;
        @synchronized(self.batchedInfo) {
            stuffToSend = self.batchedInfo;
            // RESET SETTINGS
            self.batchedInfo = [NSMutableArray new];
            [[NSUserDefaults standardUserDefaults] setValue:self.batchedInfo forKey:kBatchedInfoKey];
        }
        // so if we fail RIGHT here we will lose all the events.  I'm not sure what the right thing to do about
        // it is.
        [WGApi postURL:analyticsString
        withParameters:stuffToSend
            andHandler:^(NSDictionary *jsonResponse, NSError *error) {
                
            }];
    });
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