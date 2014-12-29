//
//  WGCollection.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGCollection.h"

@implementation WGCollection

#pragma mark - Init

+(WGCollection *)initWithResponse:(NSDictionary *) jsonResponse andClass:(Class)type {
    WGCollection *newCollection = [WGCollection new];
    
    [newCollection setPagination: [jsonResponse objectForKey:@"meta"]];
    [newCollection setObjects: [jsonResponse objectForKey:@"objects"] andType:type];
    
    return newCollection;
}

#pragma mark - Objects

-(void) setObjects:(NSArray *)objects andType:(Class)type {
    self.objects = [[NSMutableArray alloc] init];
    for (NSDictionary *objectDict in objects) {
        WGObject *object = [type serialize:objectDict];
        [self.objects addObject: object];
    }
}

-(void) exchangeObjectAtIndex:(NSUInteger)id1 withObjectAtIndex:(NSUInteger)id2 {
    [self.objects exchangeObjectAtIndex:id1 withObjectAtIndex:id2];
}

-(void) replaceObjectAtIndex:(NSUInteger)index withObject:(WGObject *)object {
    [self.objects replaceObjectAtIndex:index withObject:object];
}

-(void) addObjectsFromCollection:(WGCollection *)newCollection {
    [self.objects addObjectsFromArray:newCollection.objects];
}

-(void) addObjectsFromCollection:(WGCollection *)newCollection notInCollection:(WGCollection *)notCollection {
    for (int i = 0; i < [newCollection.objects count]; i++) {
        WGObject *object = [newCollection.objects objectAtIndex:i];
        if (![notCollection containsObject:object]) {
            [self.objects addObject:object];
        }
    }
}

-(void) addObject:(WGObject *)object {
    [self.objects addObject:object];
}

-(void) insertObject:(WGObject *)object atIndex:(NSUInteger)index {
    [self.objects insertObject:object atIndex:index];
}

-(void) addObjectsFromCollectionToBeginning:(WGCollection *)collection {
    for (int i = 0; i < [collection.objects count]; i++) {
        [self insertObject:[collection.objects objectAtIndex:i] atIndex:0];
    }
}

-(void) removeObjectAtIndex:(NSUInteger)index {
    [self.objects removeObjectAtIndex:index];
}

-(void) removeAllObjects {
    self.objects = [[NSMutableArray alloc] init];
}

-(WGObject *) objectWithID:(NSNumber *)searchID {
    for (WGObject *object in self.objects) {
        if ([searchID isEqualToNumber:object.id]) {
            return object;
        }
    }
    return nil;
}

-(BOOL) containsObject:(WGObject *)object {
    return [self.objects containsObject:object];
}

-(NSUInteger) count {
    return [self.objects count];
}

#pragma mark - Pagination

-(void) getNextPage:(CollectionResult)handler {
    if (!self.nextPage) {
        handler(nil, [NSError errorWithDomain:@"WGApi" code:0 userInfo:@{}]);
        return;
    }
    [WGApi getURL:self.nextPage withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *objects = [WGCollection initWithResponse:jsonResponse andClass:[self class]];
        handler(objects, error);
    }];
}

-(void)setPagination:(NSDictionary *)metaDictionary {
    self.hasNextPage = [metaDictionary objectForKey:@"has_next_page"];
    if (self.hasNextPage && [self.hasNextPage  boolValue]) {
        self.nextPage = [metaDictionary objectForKey:@"next"];
    }
}

@end
