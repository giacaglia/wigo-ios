//
//  NSObject+WGGetter.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/27/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGGetter.h"
#import "WGMessage.h"
#import "WGProfile.h"
#import "WGUser.h"
#import "WGNotification.h"
#import "TabBarAuxiliar.h"


@implementation WGGetter: NSObject

- (void)fetchUserNames {
    __weak typeof(self) weakSelf = self;
    [WGProfile get:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) return;
            strongSelf.allUsers = collection;
        });
    }];
}

- (void)fetchMessages {
    __weak typeof(self) weakSelf = self;
    [WGMessage getConversations:^(WGCollection *collection, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (error) return;
        strongSelf.messages = collection;
    }];
}

- (void)fetchSuggestions {
    __weak typeof(self) weakSelf = self;
    [WGUser getSuggestions:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (error) return;
            strongSelf.suggestions = collection;
        });
    }];
}

- (void)fetchNotifications {
    self.notifications = [[WGCollection alloc] initWithType:[WGNotification class]];
    __weak typeof(self) weakSelf = self;
    [WGNotification get:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        for (WGNotification *notification in collection) {
            if (!notification.isFromLastDay) {
                [strongSelf.notifications addObject:notification];
            }
        }
    }];
}

- (void)fetchMetaWithHandler:(BoolResultBlock)handler {
    if (!WGProfile.currentUser.key) return;
    [WGApi get:@"users/me/meta/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) return;
        if ([jsonResponse objectForKey:@"last_notification"]) {
            NSString *notificationString = [jsonResponse objectForKey:@"last_notification"];
            NSDate *lastNotification = [WGGetter getDateFromString:notificationString];
            [TabBarAuxiliar checkIndex:kIndexOfProfile forDate:lastNotification];
        }
        if ([jsonResponse objectForKey:@"last_message_received"]) {
            NSString *messageString = [jsonResponse objectForKey:@"last_message_received"];
            NSDate *lastMessage = [WGGetter getDateFromString:messageString];
            [TabBarAuxiliar checkIndex:kIndexOfChats forDate:lastMessage];
        }
        if ([jsonResponse objectForKey:@"last_friend_request"]) {
            NSString *userString = [jsonResponse objectForKey:@"last_friend_request"];
            NSDate *lastUser = [WGGetter getDateFromString:userString];
            [TabBarAuxiliar checkIndex:kIndexOfFriends forDate:lastUser];
        }
        [WGProfile setNumFriends:[jsonResponse objectForKey:@"num_friends"]];
        handler(YES, nil);
    }];
}

+(NSDate *)getDateFromString:(NSString *)timeString {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    return [[dateFormatter dateFromString:timeString] dateByAddingTimeInterval:timeZoneSeconds];
}

- (void)fetchFriendsIds {
    if (!WGProfile.currentUser.key) return;
    [WGApi get:@"users/me/friends/ids/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!WGProfile.currentUser || error) return;
        [WGProfile.currentUser setFriendsIds:(NSArray *)jsonResponse];
    }];
}

- (void)fetchFriendsIdsWithHandler:(BoolResultBlock)handler {
    if (!WGProfile.currentUser.key) return;
    [WGApi get:@"users/me/friends/ids/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!WGProfile.currentUser || error) {
            handler(NO, error);
            return;
        }
        [WGProfile.currentUser setFriendsIds:(NSArray *)jsonResponse];
        handler(YES, nil);
    }];
}

@end
