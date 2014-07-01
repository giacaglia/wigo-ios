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
@property NSDictionary *toUser;
@property BOOL wasMessageRead;
- (NSString *)timeOfCreation;
- (void)setTimeOfCreation:(NSString *)timeOfCreation;
- (void)save;
@end
