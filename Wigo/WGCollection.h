//
//  WGCollection.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGObject.h"

@interface WGCollection : NSEnumerator

typedef void (^WGSerializedCollectionResultBlock)(NSURL *urlSent, WGCollection *collection, NSError *error);
typedef void (^WGCollectionResultBlock)(WGCollection *collection, NSError *error);

@property Class type;

@property NSMutableArray *objects;
@property NSInteger currentPosition;

@property NSNumber *hasNextPage;
@property NSString *nextPage;
@property NSString *previousPage;
@property NSNumber *metaNumResults;

-(id) initWithType:(Class)type;

+(WGCollection *)serializeResponse:(NSDictionary *) jsonResponse andClass:(Class)type;
+(WGCollection *)serializeArray:(NSArray *) array andClass:(Class)type;

-(NSArray *) deserialize;

-(void) reverse;
-(void) exchangeObjectAtIndex:(NSUInteger)id1 withObjectAtIndex:(NSUInteger)id2;
-(void) replaceObjectAtIndex:(NSUInteger)index withObject:(WGObject *)object;
-(void) addObjectsFromCollection:(WGCollection *)newCollection;
-(void) addObjectsFromCollection:(WGCollection *)newCollection notInCollection:(WGCollection *)notCollection;
-(void) addObject:(WGObject *)object;
-(WGObject *) objectAtIndex:(NSInteger)index;
-(NSInteger) indexOfObject:(WGObject *)object;
-(void) insertObject:(WGObject *)object atIndex:(NSUInteger)index;
-(void) addObjectsFromCollectionToBeginning:(WGCollection *)collection;
-(void) addObjectsFromCollectionToBeginning:(WGCollection *)collection notInCollection:(WGCollection *)notCollection;
-(void) removeObjectAtIndex:(NSUInteger)index;
-(void) removeAllObjects;
-(void) removeObject:(WGObject *)object;
-(WGObject *) objectWithID:(NSNumber *)searchID;
-(BOOL) containsObject:(WGObject *)object;
-(NSUInteger) count;
-(NSArray *) idArray;

-(void) addPreviousPage:(BoolResultBlock)handler;
-(void) addNextPage:(BoolResultBlock)handler;
-(void) getNextPage:(WGCollectionResultBlock)handler;

@end