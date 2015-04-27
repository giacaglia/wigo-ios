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

- (void)fetchMeta {
    [WGApi get:@"users/me/meta/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) return;
        if ([jsonResponse objectForKey:@"last_notification"]) {
            NSString *notificationString = [jsonResponse objectForKey:@"last_notification"];
            NSDate *lastNotification = [WGGetter getDateFromString:notificationString];
            [TabBarAuxiliar checkIndex:kIndexOfProfile ForDate:lastNotification];
        }
        if ([jsonResponse objectForKey:@"last_message"]) {
            NSString *messageString = [jsonResponse objectForKey:@"last_message"];
            NSDate *lastMessage = [WGGetter getDateFromString:messageString];
            [TabBarAuxiliar checkIndex:kIndexOfChats ForDate:lastMessage];
        }
        if ([jsonResponse objectForKey:@"last_user"]) {
            NSString *userString = [jsonResponse objectForKey:@"last_user"];
            NSDate *lastUser = [WGGetter getDateFromString:userString];
            [TabBarAuxiliar checkIndex:kIndexOfFriends ForDate:lastUser];
        }
        [WGProfile setNumFriends:[jsonResponse objectForKey:@"num_friends"]];
    }];
}

+(NSDate *)getDateFromString:(NSString *)timeString {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSDate *dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:timeString];
    return dateFromString;
}


@end
