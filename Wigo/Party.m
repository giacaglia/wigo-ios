 //
//  Party.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Party.h"
#import "User.h"
#import "Event.h"

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
    }
}

- (void)addObject:(NSMutableDictionary *)objectDictionary {
    NSLog(@"object dictionary: %@", objectDictionary);
    [objectArray addObject:objectDictionary];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [objectArray removeObjectAtIndex:index];
}

- (NSMutableDictionary *)getObjectWithId:(NSNumber *)objectID {
    for (NSMutableDictionary *object in objectArray) {
        if ([objectID isEqualToNumber:[object valueForKey:@"id"]]) {
            return object;
        }
    }
    return nil;
}

- (BOOL)containsObject:(NSMutableDictionary *)otherObjectDictionary {
    for (NSMutableDictionary *object in objectArray) {
        if ([otherObjectDictionary valueForKey:@"id"] == [object valueForKey:@"id"]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeUserFromParty:(User*)newUser {
    for (int i = 0; i < [[self getObjectArray] count]; i++) {
        User *user = [[self getObjectArray] objectAtIndex:i];
        if ([user isEqualToUser:newUser]) {
            [self removeObjectAtIndex:i];
            break;
        }
    }
}

@end
