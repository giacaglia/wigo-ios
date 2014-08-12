//
//  Message.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface Message : NSMutableDictionary

@property NSString *messageString;

@property User *fromUser;
@property NSNumber *toUser;
@property BOOL isRead;
- (BOOL)isMessageFromLastDay;
- (NSString *)timeOfCreation;
- (void)setTimeOfCreation:(NSString *)timeOfCreation;
- (void)save;
- (void)saveAsynchronously;
- (BOOL)expired;

- (User *)otherUser;
+ (NSString *)randomStringWithLength:(int)len;
- (BOOL)isEqualToMessage:(Message *)otherMessage;
@end
