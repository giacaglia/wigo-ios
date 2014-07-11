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

@interface Party : NSObject

@property NSString *objectName;
@property NSMutableArray *objectArray;
@property NSDictionary *metaDictionary;



- (id)initWithObjectName:(NSString *)objectName;
- (NSArray *)getObjectArray;
- (NSArray *)getNameArray;
- (NSArray *)getFullNameArray;
- (void)addObjectsFromArray:(NSArray *)newObjectArray;
- (void)addObject:(NSMutableDictionary *)objectDictionary;
- (void)removeAllObjects;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (NSMutableDictionary *)getObjectWithId:(NSNumber *)objectID;
- (BOOL)containsObject:(NSMutableDictionary *)otherObjectDictionary;
- (void)removeUser:(User*)newUser;
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;

// Pagination control
- (BOOL)hasNextPage;
- (void)addMetaInfo:(NSDictionary *)metaDictionary;

@end
