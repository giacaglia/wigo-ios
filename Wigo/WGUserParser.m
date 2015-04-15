//
//  WGUserParser.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/15/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGUserParser.h"
#import "WGCollection.h"
#import "NetworkFetcher.h"
#import "WGUser.h"

@implementation WGUserParser

+(WGCollection *)usersFromText:(NSString *)text {
    text = text.lowercaseString;
    WGCollection *newUsersCollection = [[WGCollection alloc] initWithType:[WGUser class]];
    if (text.length == 0) return newUsersCollection;
    WGCollection *allUsers = NetworkFetcher.defaultGetter.allUsers;
    for (WGUser *user in allUsers) {
        NSString*firstPartOfUser = [user.fullName substringWithRange:NSMakeRange(0, text.length)].lowercaseString;
        if ([text isEqual:firstPartOfUser]) {
            [newUsersCollection addObject:user];
        }
    }
    return newUsersCollection;
}

@end
