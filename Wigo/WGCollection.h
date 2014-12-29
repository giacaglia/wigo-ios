//
//  WGCollection.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGObject.h"

@interface WGCollection : NSObject

typedef void (^CollectionResult)(WGCollection *collection, NSError *error);

@property NSMutableArray *objects;
@property NSNumber *hasNextPage;
@property NSString *nextPage;

+(WGCollection *)initWithResponse:(NSDictionary *) jsonResponse andClass:(Class)type;

-(void) exchangeObjectAtIndex:(NSUInteger)id1 withObjectAtIndex:(NSUInteger)id2;
-(void) replaceObjectAtIndex:(NSUInteger)index withObject:(WGObject *)object;
-(void) addObjectsFromCollection:(WGCollection *)newCollection;
-(void) addObjectsFromCollection:(WGCollection *)newCollection notInCollection:(WGCollection *)notCollection;
-(void) addObject:(WGObject *)object;
-(void) insertObject:(WGObject *)object atIndex:(NSUInteger)index;
-(void) addObjectsFromCollectionToBeginning:(WGCollection *)collection;
-(void) removeObjectAtIndex:(NSUInteger)index;
-(void) removeAllObjects;
-(WGObject *) objectWithID:(NSNumber *)searchID;
-(BOOL) containsObject:(WGObject *)object;
-(NSUInteger) count;

-(void) getNextPage:(CollectionResult)handler;

@end