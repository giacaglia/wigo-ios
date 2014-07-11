//
//  Party.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Party.h"

@implementation Party

- (id)init {
    self = [super init];
    if (self) {
        self.objectArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

// In the implementation
-(id)copyWithZone:(NSZone *)zone
{
    // We'll ignore the zone for now
    Party *another = [[Party alloc] init];
    another.objectName = [self.objectName copyWithZone:zone];
    another.objectArray = [self.objectArray copyWithZone:zone];
    return another;
}

- (NSArray *)getObjectArray {
    return [NSArray arrayWithArray:self.objectArray];
}

- (id)initWithObjectName:(NSString *)objectName {
    self = [super init];
    if (self) {
        self.objectName = objectName;
        self.objectArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (NSArray *)getNameArray {
    NSMutableArray *nameArray = [[NSMutableArray alloc] initWithCapacity:[self.objectArray count]];
    for (NSDictionary *objectDictionary in self.objectArray) {
        [nameArray addObject:[objectDictionary objectForKey:@"name"]];
    }
    return [nameArray copy];
}

- (NSArray *)getFullNameArray {
    NSMutableArray *nameArray = [[NSMutableArray alloc] initWithCapacity:[self.objectArray count]];
    for (NSDictionary *objectDictionary in self.objectArray) {
        if ([[objectDictionary allKeys] containsObject:@"first_name"] && [[objectDictionary allKeys] containsObject:@"last_name"])
        {
            NSString *fullName = [NSString stringWithFormat:@"%@ %@", [objectDictionary objectForKey:@"first_name"], [objectDictionary objectForKey:@"last_name"]];
            [nameArray addObject:fullName];
        }
    }
    return [nameArray copy];
}

- (void)addObjectsFromArray:(NSArray *)newObjectArray{
    for (int i = 0; i < [newObjectArray count]; i++) {
        if ([self.objectName isEqualToString:@"User"]) {
            User *newUser = [[User alloc] initWithDictionary:newObjectArray[i]];
            [self.objectArray addObject:newUser];
        }
        else if ([self.objectName isEqualToString:@"Event"]) {
            Event *newEvent = [[Event alloc] initWithDictionary:newObjectArray[i]];
            [self.objectArray addObject:newEvent];
        }
        else if ([self.objectName isEqualToString:@"Message"]) {
            Message *newMessage = [[Message alloc] initWithDictionary:newObjectArray[i]];
            [self.objectArray addObject:newMessage];
        }
        else if ([self.objectName isEqualToString:@"Notification"]) {
            Notification *newNotification = [[Notification alloc] initWithDictionary:newObjectArray[i]];
            [self.objectArray addObject:newNotification];
        }
    }
}

- (void)addObject:(NSMutableDictionary *)objectDictionary {
    if ([objectDictionary isKindOfClass:[NSDictionary class]]) {
        [self.objectArray addObject:objectDictionary];
    }
    else {
        NSLog(@"Error adding object: %@", objectDictionary);
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [self.objectArray removeObjectAtIndex:index];
}

- (void)removeAllObjects {
    self.objectArray = [[NSMutableArray alloc] init];
}

- (NSMutableDictionary *)getObjectWithId:(NSNumber *)objectID {
    if ([objectID isKindOfClass:[NSDictionary class]]) {
        return [[User alloc] initWithDictionary:(NSDictionary *)objectID];
    }
    for (NSMutableDictionary *object in self.objectArray) {
        if ([objectID isEqualToNumber:[object valueForKey:@"id"]]) {
            return object;
        }
    }
    return nil;
}

- (BOOL)containsObject:(NSMutableDictionary *)otherObjectDictionary {
    for (NSMutableDictionary *object in self.objectArray) {
        if ([[otherObjectDictionary valueForKey:@"id"] isEqualToNumber:[object valueForKey:@"id"]]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeUser:(User*)newUser {
    for (int i = 0; i < [self.objectArray count]; i++) {
        User *user = [self.objectArray objectAtIndex:i];
        if ([user isEqualToUser:newUser]) {
            [self removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2 {
    [self.objectArray exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

#pragma mark - Pagination Control

// Pagination control
- (BOOL)hasNextPage {
    if (self.metaDictionary) {
        if ([[self.metaDictionary allKeys] containsObject:@"has_next_page"]) {
            return [(NSNumber *)[self.metaDictionary objectForKey:@"has_next_page"] boolValue];
        }
    }
    return NO;
}
- (void)addMetaInfo:(NSDictionary *)metaDictionary {
    self.metaDictionary = metaDictionary;
}


@end
