//
//  Party.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Party.h"

@implementation Party

- (id)initWithObjectType:(OBJECT_TYPE)type {
    self = [super init];
    if (self) {
        self.objectType = type;
        self.mutableObjectArray = [NSMutableArray new];
    }
    return self;
}


- (id)init {
    self = [super init];
    if (self) {
        self.mutableObjectArray = [NSMutableArray new];
    }
    return self;
}

// In the implementation
-(id)copyWithZone:(NSZone *)zone
{
    // We'll ignore the zone for now
    Party *another = [[Party alloc] init];
    another.objectType = self.objectType;
    another.mutableObjectArray = [self.mutableObjectArray copyWithZone:zone];
    return another;
}

- (NSUInteger)count {
    return [self.mutableObjectArray count];
}

- (NSArray *)getObjectArray {
    return [NSArray arrayWithArray:self.mutableObjectArray];
}



- (NSArray *)getNameArray {
    NSMutableArray *nameArray = [[NSMutableArray alloc] initWithCapacity:[self.mutableObjectArray count]];
    for (NSDictionary *objectDictionary in self.mutableObjectArray) {
        [nameArray addObject:[objectDictionary objectForKey:@"name"]];
    }
    return [nameArray copy];
}

- (NSArray *)getFullNameArray {
    NSMutableArray *nameArray = [[NSMutableArray alloc] initWithCapacity:[self.mutableObjectArray count]];
    for (NSDictionary *objectDictionary in self.mutableObjectArray) {
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
        if (self.objectType == USER_TYPE) {
            User *newUser = [[User alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray addObject:newUser];
        }
        else if (self.objectType == EVENT_TYPE) {
            Event *newEvent = [[Event alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray addObject:newEvent];
        }
        else if (self.objectType == MESSAGE_TYPE) {
            Message *newMessage = [[Message alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray addObject:newMessage];
        }
        else if (self.objectType == NOTIFICATION_TYPE) {
            Notification *newNotification = [[Notification alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray addObject:newNotification];
        }
    }
}

- (void)addObjectsFromArray:(NSArray *)newObjectArray notInParty:(Party *)otherParty {
    NSArray *arrayOfKeyOfOtherParty = [[otherParty getObjectArray] valueForKey:@"id"];
    for (int i = 0; i < [newObjectArray count]; i++) {
        NSDictionary *dict = newObjectArray[i];
        if (![arrayOfKeyOfOtherParty containsObject:[dict objectForKey:@"id"]]) {
            if (self.objectType == USER_TYPE) {
                User *newUser = [[User alloc] initWithDictionary:dict];
                [self.mutableObjectArray addObject:newUser];
            }
            else if (self.objectType == EVENT_TYPE) {
                Event *newEvent = [[Event alloc] initWithDictionary:dict];
                [self.mutableObjectArray addObject:newEvent];
            }
            else if (self.objectType == MESSAGE_TYPE) {
                Message *newMessage = [[Message alloc] initWithDictionary:dict];
                [self.mutableObjectArray addObject:newMessage];
            }
            else if (self.objectType == NOTIFICATION_TYPE) {
                Notification *newNotification = [[Notification alloc] initWithDictionary:dict];
                [self.mutableObjectArray addObject:newNotification];
            }
        }
       
    }
}

- (void)addObject:(NSMutableDictionary *)objectDictionary {
    if ([objectDictionary isKindOfClass:[NSDictionary class]]) {
        [self.mutableObjectArray addObject:objectDictionary];
    }
    else {
        NSLog(@"Error adding object: %@", objectDictionary);
    }
}

- (void)insertObject:(NSDictionary *)object inObjectArrayAtIndex:(NSUInteger)index {
    if ([object isKindOfClass:[NSDictionary class]]) {
        [self.mutableObjectArray insertObject:object atIndex:index];
    }
    else {
        NSLog(@"Error adding object: %@", object);
    }
}

- (void)insertObjectsFromArrayAtBeginning:(NSArray *)newObjectArray {
    for (int i = 0; i < [newObjectArray count]; i++) {
        if (self.objectType == USER_TYPE) {
            User *newUser = [[User alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray insertObject:newUser atIndex:0];
        }
        else if (self.objectType == EVENT_TYPE) {
            Event *newEvent = [[Event alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray insertObject:newEvent atIndex:0];
        }
        else if (self.objectType == MESSAGE_TYPE) {
            Message *newMessage = [[Message alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray insertObject:newMessage atIndex:0];
        }
        else if (self.objectType == NOTIFICATION_TYPE) {
            Notification *newNotification = [[Notification alloc] initWithDictionary:newObjectArray[i]];
            [self.mutableObjectArray insertObject:newNotification atIndex:0];
        }
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [self.mutableObjectArray removeObjectAtIndex:index];
}

- (void)removeAllObjects {
    self.mutableObjectArray = [NSMutableArray new];
}

- (NSMutableDictionary *)getObjectWithId:(NSNumber *)objectID {
    if ([objectID isKindOfClass:[NSDictionary class]]) {
        return [[User alloc] initWithDictionary:(NSDictionary *)objectID];
    }
    for (NSMutableDictionary *object in self.mutableObjectArray) {
        if ([objectID isEqualToNumber:[object valueForKey:@"id"]]) {
            return object;
        }
    }
    return nil;
}

- (BOOL)containsObject:(NSMutableDictionary *)otherObjectDictionary {
    for (NSMutableDictionary *object in self.mutableObjectArray) {
        if ([[otherObjectDictionary valueForKey:@"id"] isEqualToNumber:[object valueForKey:@"id"]]) {
            return YES;
        }
    }
    return NO;
}


- (void)removeUser:(User*)newUser {
    for (int i = 0; i < [self.mutableObjectArray count]; i++) {
        User *user = [self.mutableObjectArray objectAtIndex:i];
        if (user && [user isEqualToUser:newUser]) {
            [self removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2 {
    [self.mutableObjectArray exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    if ([self.mutableObjectArray count] > 0) [self.mutableObjectArray replaceObjectAtIndex:index withObject:anObject];
}

#pragma mark - Pagination Control

- (BOOL)hasNextPage {
    if (self.metaDictionary) {
        if ([[self.metaDictionary allKeys] containsObject:@"has_next_page"]) {
            return [(NSNumber *)[self.metaDictionary objectForKey:@"has_next_page"] boolValue];
        }
    }
    return NO;
}

- (NSString *)nextPageString {
    if (self.metaDictionary) {
        if ([[self.metaDictionary allKeys] containsObject:@"next"]) {
            NSString *nextAPIString = (NSString *)[self.metaDictionary objectForKey:@"next"];
            return [nextAPIString substringWithRange:NSMakeRange(5, nextAPIString.length - 5)];
        }
    }
    return nil;
}

- (void)addMetaInfo:(NSDictionary *)metaDictionary {
    self.metaDictionary = metaDictionary;
}


@end
