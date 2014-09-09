//
//  Notification.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface Notification : NSDictionary

@property NSString *type;
@property NSNumber *fromUserID;
@property NSDictionary *fromUser;
@property NSString *timeString;

- (id)initWithDictionary:(NSDictionary *)otherDictionary;
- (NSString *)message;

@end
