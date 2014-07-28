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

- (void)addEventAttendeesWithDictionary:(NSDictionary *)eventAttendeesDictionary {
    NSMutableArray *usersArray = [[NSMutableArray alloc] init];
    for (NSString *key in [eventAttendeesDictionary allKeys]) {
        NSDictionary *userAndEventDictionary = eventAttendeesDictionary[key];
        User *user = [[User alloc] initWithDictionary:[userAndEventDictionary objectForKey:@"user"]];
        [usersArray addObject:user];
    }
    [_proxy setObject:usersArray forKey:@"userArray"];
}

-(NSArray *)getEventAttendees {
    return [_proxy objectForKey:@"userArray"];
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
