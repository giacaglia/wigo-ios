//
//  Party.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Party.h"

@implementation Party {
    NSMutableArray *objectArray;
}

- (id)init {
    self = [super init];
    if (self) {
        objectArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (id)initWithObjectName:(NSString *)objectName {
    self = [super init];
    if (self) {
        self.objectName = objectName;
        objectArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (NSArray *)getObjectArray {
  return objectArray;
}

- (NSArray *)getNameArray {
    NSMutableArray *nameArray = [[NSMutableArray alloc] initWithCapacity:[objectArray count]];
    for (NSDictionary *objectDictionary in objectArray) {
        [nameArray addObject:[objectDictionary objectForKey:@"name"]];
    }
    return [nameArray copy];
}

- (void)addObjectsFromArray:(NSArray *)newObjectArray{
    for (int i = 0; i < [newObjectArray count]; i++) {
        if ([self.objectName isEqualToString:@"User"]) {
            User *newUser = [[User alloc] initWithDictionary:newObjectArray[i]];
            [objectArray addObject:newUser];
        }
        else if ([self.objectName isEqualToString:@"Event"]) {
            Event *newEvent = [[Event alloc] initWithDictionary:newObjectArray[i]];
            [objectArray addObject:newEvent];
        }
        else if ([self.objectName isEqualToString:@"Message"]) {
            Message *newMessage = [[Message alloc] initWithDictionary:newObjectArray[i]];
            [objectArray addObject:newMessage];
        }
        else if ([self.objectName isEqualToString:@"Notification"]) {
            Notification *newNotification = [[Notification alloc] initWithDictionary:newObjectArray[i]];
            [objectArray addObject:newNotification];
        }
    }
}

- (void)addObject:(NSMutableDictionary *)objectDictionary {
    if ([objectDictionary isKindOfClass:[NSDictionary class]]) {
        [objectArray addObject:objectDictionary];
    }
    else {
        NSLog(@"Error adding object: %@", objectDictionary);
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [objectArray removeObjectAtIndex:index];
}

- (NSMutableDictionary *)getObjectWithId:(NSNumber *)objectID {
    if ([objectID isKindOfClass:[NSDictionary class]]) {
        return [[User alloc] initWithDictionary:(NSDictionary *)objectID];
    }
    for (NSMutableDictionary *object in objectArray) {
        if ([objectID isEqualToNumber:[object valueForKey:@"id"]]) {
            return object;
        }
    }
    return nil;
}

- (BOOL)containsObject:(NSMutableDictionary *)otherObjectDictionary {
    for (NSMutableDictionary *object in objectArray) {
        if ([[otherObjectDictionary valueForKey:@"id"] isEqualToNumber:[object valueForKey:@"id"]]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeUser:(User*)newUser {
    for (int i = 0; i < [[self getObjectArray] count]; i++) {
        User *user = [[self getObjectArray] objectAtIndex:i];
        if ([user isEqualToUser:newUser]) {
            [self removeObjectAtIndex:i];
            break;
        }
    }
}
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2 {
    [objectArray exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

@end
