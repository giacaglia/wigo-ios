//
//  NSObject+WGGetter.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/27/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGGetter.h"
#import "WGMessage.h"
#import "WGUser.h"

@implementation WGGetter: NSObject

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


@end
