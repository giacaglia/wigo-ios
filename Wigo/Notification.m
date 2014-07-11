//
//  Notification.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Notification.h"

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
        return @"wants to see you out";
    }
    else if( [[self type] isEqualToString:@"follow"] || [[self type] isEqualToString:@"facebook.follow"]) {
        return @"is now following you";
    }
    else if ([[self type] isEqualToString:@"joined"]) {
        return @"joined WiGo";
    }
    else if ([[self type] isEqualToString:@"goingOut"]) {
        return @"is going out tonight";
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
    return  [_proxy objectForKey:@"from_user"];
}

- (void)setFromUserID:(NSNumber *)fromUserID {
    [_proxy setObject:fromUserID forKey:@"from_user"];
}

- (NSString *)timeString {
    NSString *utcCreationTime = [_proxy objectForKey:@"created"];
    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    [dateformat setDateFormat:@"YYYY-MM-dd h:mm:ss"];
    NSDate *dateInUTC = [dateformat dateFromString:utcCreationTime];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone localTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [dateInUTC dateByAddingTimeInterval:timeZoneSeconds];
    NSString *localTimeString = [dateformat stringFromDate:dateInLocalTimezone];
    return [localTimeString substringWithRange:NSMakeRange(11, 5)];
}

- (void)setTimeString:(NSString *)timeString {
    [_proxy setObject:timeString forKey:@"created"];
    [modifiedKeys addObject:@"created"];
}


@end
