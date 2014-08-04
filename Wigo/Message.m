//
//  Message.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Message.h"
#import "Profile.h"
#import "Time.h"

@implementation Message{
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

#pragma mark

- (NSNumber *)toUser {
    if ([[_proxy objectForKey:@"to_user"] isKindOfClass:[NSNumber class]]) {
        return [_proxy objectForKey:@"to_user"];
    }
    return nil;
}

- (void)setToUser:(NSNumber *)toUser {
    [_proxy setObject:toUser forKey:@"to_user"];
    [modifiedKeys addObject:@"to_user"];
}

//
- (User *)otherUser {
    NSDictionary *userDictionary = [_proxy objectForKey:@"user"];
    if ([Profile isUserDictionaryProfileUser:userDictionary]) {
        return [[User alloc] initWithDictionary:[_proxy objectForKey:@"to_user"]];
    }
    else {
        return [[User alloc] initWithDictionary:userDictionary];
    }
}


- (User *)fromUser {
    if ([[_proxy objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
        return [[User alloc] initWithDictionary:[_proxy objectForKey:@"user"]];
    }
    return nil;
}

- (void)setFromUser:(User *)fromUser {
    [_proxy setObject:fromUser forKey:@"user"];
}

- (NSString *)messageString {
    return [_proxy objectForKey:@"message"];
}

- (void) setMessageString:(NSString *)messageString {
    [_proxy setObject:messageString forKey:@"message"];
    [modifiedKeys addObject:@"message"];
}

- (BOOL)isRead {
    NSNumber *isRead = (NSNumber *)[_proxy objectForKey:@"is_read"];
    return [isRead boolValue];
}

- (void)setIsRead:(BOOL)isRead {
    [_proxy setObject:[NSNumber numberWithBool:isRead] forKey:@"is_read"];
    [modifiedKeys addObject:@"is_read"];
}

- (BOOL)isMessageFromLastDay {
    NSString *utcCreationTime = [_proxy objectForKey:@"created"];
    return [Time isUTCtimeStringFromLastDay:utcCreationTime];
}

- (NSString *)timeOfCreation {
    NSString *utcCreationTime = [_proxy objectForKey:@"created"];
    return [Time getUTCTimeStringToLocalTimeString:utcCreationTime];
}

- (void)setTimeOfCreation:(NSString *)timeOfCreation {
    [_proxy setObject:timeOfCreation forKey:@"created"];
}



+ (NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *randomString = [[NSMutableString alloc] initWithCapacity:len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length]) % [letters length]]];
    }
    
    return randomString;
}

- (BOOL)isEqualToMessage:(Message *)otherMessage {
    if ([[_proxy objectForKey:@"id"] isEqualToNumber:[otherMessage objectForKey:@"id"]]) {
        return YES;
    }
    return NO;
}

- (void)save {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"messages/"];
    [query setProfileKey:[Profile user].key];
    for (NSString *key in modifiedKeys) {
        [query setValue:[_proxy objectForKey:key] forKey:key];
    }
    NSDictionary *dictionaryUser = [query sendPOSTRequest];
    if  (!(dictionaryUser == nil)) {
        [_proxy addEntriesFromDictionary:dictionaryUser];
        modifiedKeys = [[NSMutableArray alloc] init];
    }
}


@end
