//
//  Notification.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Notification.h"
#import "Time.h"

@implementation Notification {
    NSMutableDictionary* _proxy;
    NSMutableArray* modifiedKeys;
}

#pragma mark - NSMutableDictionary functions

- (id)initWithDictionary:(NSDictionary *)otherDictionary {
    self = [super init];
    if (self) {
        _proxy = [NSMutableDictionary dictionaryWithDictionary:otherDictionary];
        modifiedKeys = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id) init {
    if (self = [super init]) {
        _proxy = [[NSMutableDictionary alloc] init];
        modifiedKeys = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) setObject:(id)obj forKey:(id)key {
    if (obj) {
        [_proxy setObject:obj forKey:key];
        [modifiedKeys addObject:key];
    } else {
        [_proxy removeObjectForKey:key];
    }
}

- (void)removeObjectForKey:(id)aKey
{
    [_proxy removeObjectForKey:aKey];
}

- (NSUInteger)count
{
    return [_proxy count];
}

- (id)objectForKey:(id)aKey
{
    return [_proxy objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [_proxy objectEnumerator];
}

- (NSArray *)allKeys {
    return [_proxy allKeys];
}

- (NSString *)description {
    return [_proxy description];
}

- (NSString *)message {
    if ([[self type] isEqualToString:@"tap"]) {

        User *fromUser = [[User alloc] initWithDictionary:[self fromUser]];
        if (![self expired]) {
            if ([fromUser isAttending] && [fromUser attendingEventName]) {
                return [NSString stringWithFormat:@"wants to see you out at %@", [fromUser attendingEventName]];
            }
            return @"wants to see you out";
        }
        else {
            return @"wanted to see you out";
        }
    }
    else if( [[self type] isEqualToString:@"follow"] || [[self type] isEqualToString:@"facebook.follow"]) {
        return @"is now following you";
    }
    else if ([[self type] isEqualToString:@"joined"]) {
        return @"joined WiGo";
    }
    else if ([[self type] isEqualToString:@"goingout"]) {
        return @"is going out";
    }
    else if ([[self type] isEqualToString:@"follow.accepted"]) {
        return @"accepted your follow request";
    }
    return @"";
}


- (NSString *)type {
    return [_proxy objectForKey:@"type"];
}

- (void)setType:(NSString *)type {
    [_proxy setObject:type forKey:@"type"];
    [modifiedKeys addObject:@"type"];
}


- (NSNumber *)fromUserID {
    return [_proxy objectForKey:@"from_user"];
}

- (void)setFromUserID:(NSNumber *)fromUserID {
    [_proxy setObject:fromUserID forKey:@"from_user"];
}

- (NSDictionary *)fromUser {
    return [_proxy objectForKey:@"from_user"];
}

- (void)setFromUser:(NSDictionary *)fromUser {
    [_proxy setObject:fromUser forKey:@"from_user"];
}

- (BOOL)expired {
    NSString *utcCreationTime = [_proxy objectForKey:@"created"];
    return [Time isUTCtimeStringFromLastDay:utcCreationTime];
//    return NO;
}

- (NSString *)timeString {
    NSString *utcCreationTime = [_proxy objectForKey:@"created"];
    return [Time getUTCTimeStringToLocalTimeString:utcCreationTime];
}

- (void)setTimeString:(NSString *)timeString {
    [_proxy setObject:timeString forKey:@"created"];
}


@end
