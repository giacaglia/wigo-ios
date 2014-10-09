//
//  Party.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Event.h"
#import "Message.h"
#import "Notification.h"

typedef enum
{
    USER_TYPE,
    MESSAGE_TYPE,
    NOTIFICATION_TYPE,
    EVENT_TYPE,
    FOLLOW_TYPE
} OBJECT_TYPE;

@interface Party : NSObject

@property OBJECT_TYPE objectType;
@property NSMutableArray *objectArray;
@property NSDictionary *metaDictionary;

- (id)initWithObjectType:(OBJECT_TYPE)type;
- (NSArray *)getObjectArray;
- (NSArray *)getNameArray;
- (NSArray *)getFullNameArray;
- (void)addObjectsFromArray:(NSArray *)newObjectArray;
- (void)addObjectsFromArray:(NSArray *)newObjectArray notInParty:(Party *)otherParty;
- (void)addObject:(NSMutableDictionary *)objectDictionary;
- (void)insertObject:(NSDictionary *)object inObjectArrayAtIndex:(NSUInteger)index;
- (void)removeAllObjects;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (NSMutableDictionary *)getObjectWithId:(NSNumber *)objectID;
- (BOOL)containsObject:(NSMutableDictionary *)otherObjectDictionary;
- (void)removeUser:(User*)newUser;
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (void)insertObjectsFromArrayAtBeginning:(NSArray *)newObjectArray;
// Pagination control
- (BOOL)hasNextPage;
- (void)addMetaInfo:(NSDictionary *)metaDictionary;

@end
