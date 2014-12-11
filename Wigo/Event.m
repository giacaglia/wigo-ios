//
//  Event.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Event.h"

@implementation Event
{
    NSMutableDictionary* _proxy;
}

#pragma mark - Accessory methods

- (void)addEventAttendees:(NSArray *)newEventAttendees {
    NSMutableArray *attendees = [NSMutableArray arrayWithArray:[_proxy objectForKey:@"attendees"]];
    [attendees addObjectsFromArray:newEventAttendees];
    [_proxy setObject:[NSArray arrayWithArray:attendees] forKey:@"attendees"];
}

- (void)addUser:(User *)user {
    NSMutableArray *attendees = [NSMutableArray arrayWithArray:[_proxy objectForKey:@"attendees"]];
    NSDictionary *newAttendee = @{ @"user": [user dictionary] };
    [attendees insertObject:newAttendee atIndex:0];
    [_proxy setObject:[NSArray arrayWithArray:attendees] forKey:@"attendees"];
}

-(NSArray *)getEventAttendees {
    return [_proxy objectForKey:@"attendees"];
}

- (NSDictionary *)dictionary {
    return _proxy;
}

#pragma mark - Property methods

- (NSNumber *)eventID {
    return (NSNumber *)[_proxy objectForKey:@"id"];
}

- (void)setEventID:(NSNumber *)eventID {
    [_proxy setObject:eventID forKey:@"id"];
}

- (NSNumber *)numberAttending {
    if ([[_proxy allKeys] containsObject:@"num_attending"]) return [_proxy objectForKey:@"num_attending"];
    return @0;
}

- (void)setNumberAttending:(NSNumber *)numberAttending {
    if ([[_proxy allKeys] containsObject:@"num_attending"]) {
        [_proxy setObject:numberAttending forKey:@"num_attending"];
    }
}

- (NSNumber *)numberOfMessages {
    if ([[_proxy allKeys] containsObject:@"num_messages"]) return [_proxy objectForKey:@"num_messages"];
    return @0;
}

- (void)setNumberOfMessages:(NSNumber *)numberOfMessages {
    if ([[_proxy allKeys] containsObject:@"num_messages"]) {
        [_proxy setObject:numberOfMessages forKey:@"num_messages"];
    }
}

- (NSString *)name {
    return (NSString *)[_proxy objectForKey:@"name"];
}

- (void)setName:(NSString *)name {
    [_proxy setObject:name forKey:@"name"];
}

#pragma mark - NSMutableDictionary methods

- (id)initWithDictionary:(NSDictionary *)otherDictionary {
    self = [super init];
    if (self) {
        _proxy = [NSMutableDictionary dictionaryWithDictionary:otherDictionary];
    }
    return self;
}

- (id) init {
    if (self = [super init]) {
        _proxy = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) setObject:(id)obj forKey:(id)key {
    if (obj) {
        [_proxy setObject:obj forKey:key];
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


@end
