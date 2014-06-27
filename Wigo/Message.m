//
//  Message.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Message.h"

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

- (User *)toUser {
    if ([[_proxy objectForKey:@"to_user"] isKindOfClass:[NSDictionary class]]) {
        return [[User alloc] initWithDictionary:[_proxy objectForKey:@"to_user"]];
    }
    return nil;
}

- (void)setToUser:(User *)toUser {
    [_proxy setObject:toUser forKey:@"to_user"];
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

- (BOOL)wasMessageRead {
    NSString *wasMessageRead = [[_proxy objectForKey:@"properties"] objectForKey:@"wasMessageRead"];
    if (wasMessageRead) {
        return YES;
    }
    [self setWasMessageRead:YES];
    return NO;
}

- (void)setWasMessageRead:(BOOL)wasMessageRead {
    [[_proxy objectForKey:@"properties"] setObject:@"read" forKey:@"wasMessageRead"];
    [modifiedKeys addObject:@"properties"];
}

- (NSString *)timeOfCreation {
    NSString *utcCreationTime = [_proxy objectForKey:@"created"];
    return [utcCreationTime substringWithRange:NSMakeRange(11, 5)];
}

- (void)setTimeOfCreation:(NSString *)timeOfCreation {
    [_proxy setObject:timeOfCreation forKey:@"created"];
    [modifiedKeys addObject:@"created"];
}

@end
