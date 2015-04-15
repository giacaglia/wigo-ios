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


@end
