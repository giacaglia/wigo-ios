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

@interface Party : NSObject

@property NSString *objectName;

- (id)initWithObjectName:(NSString *)objectName;
- (NSArray *)getObjectArray;
- (NSArray *)getNameArray;
- (void)addObjectsFromArray:(NSArray *)newObjectArray;
- (void)addObject:(NSMutableDictionary *)objectDictionary;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (NSMutableDictionary *)getObjectWithId:(NSNumber *)objectID;
- (BOOL)containsObject:(NSMutableDictionary *)otherObjectDictionary;
- (void)removeUserFromParty:(User*)newUser;
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;

@end
