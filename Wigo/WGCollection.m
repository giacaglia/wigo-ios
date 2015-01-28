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

-(id) initWithType:(Class)type {
    self = [super init];
    if (self) {
        self.objects = [[NSMutableArray alloc] init];
        self.type = type;
        self.currentPosition = 0;
    }
    return self;
}

+(WGCollection *)serializeResponse:(NSDictionary *) jsonResponse andClass:(Class)type {
    WGCollection *newCollection = [[WGCollection alloc] initWithType:type];
    
    [newCollection setPagination: [jsonResponse objectForKey:@"meta"]];
    [newCollection initObjects: [jsonResponse objectForKey:@"objects"]];
    
    return newCollection;
}

+(WGCollection *)serializeArray:(NSArray *) array andClass:(Class)type {
   WGCollection *newCollection = [[WGCollection alloc] initWithType:type];
    
    newCollection.type = type;
    [newCollection initObjects:array];
    
    return newCollection;
}

-(NSArray *) deserialize {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (WGObject *object in self.objects) {
        [array addObject:[object deserialize]];
    }
    return array;
}

#pragma mark - Objects

-(void) initObjects:(NSArray *)objects {
    self.objects = [[NSMutableArray alloc] init];
    for (NSDictionary *objectDict in objects) {
        [self.objects addObject: [[self.type alloc] initWithJSON:objectDict]];
    }
}

-(BOOL) isEqual:(id)object {
    if (!object || ![object isKindOfClass:[WGCollection class]]) {
        return NO;
    }
    WGCollection *otherCollection = (WGCollection *)object;
    if ([self count] != [otherCollection count]) {
        return NO;
    }
    for (int i = 0; i < [self count]; i++) {
        if (![[self objectAtIndex:i] isEqual:[otherCollection objectAtIndex:i]]) {
            return NO;
        }
    }
    return YES;
}

-(void) reverse {
    if ([self count] == 0)
        return;
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {
        [self exchangeObjectAtIndex:i
                  withObjectAtIndex:j];
        
        i++;
        j--;
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
    if (!object) {
        NSLog(@"Tried to add nil object to WGCollection");
        return;
    }
    [self.objects addObject:object];
}

-(void) insertObject:(WGObject *)object atIndex:(NSUInteger)index {
    if (!object) {
        NSLog(@"Tried to insert nil object to WGCollection at index %lu", (unsigned long)index);
        return;
    }
    [self.objects insertObject:object atIndex:index];
}

-(void) addObjectsFromCollectionToBeginning:(WGCollection *)collection {
    for (WGObject *object in collection) {
        [self insertObject:object atIndex:0];
    }
}

-(WGObject *) objectAtIndex:(NSInteger)index {
    return [self.objects objectAtIndex:index];
}

-(void) removeObjectAtIndex:(NSUInteger)index {
    [self.objects removeObjectAtIndex:index];
}

-(void) removeAllObjects {
    self.objects = [[NSMutableArray alloc] init];
    self.currentPosition = 0;
}

-(WGObject *) objectWithID:(NSNumber *)searchID {
    for (WGObject *object in self.objects) {
        if ([searchID isEqualToNumber:object.id]) {
            return object;
        }
    }
    return nil;
}

-(NSInteger) indexOfObject:(WGObject *)object {
    return [self.objects indexOfObject:object];
}

-(BOOL) containsObject:(WGObject *)other {
    for (WGObject *object in self.objects) {
        if ([object isEqual:other]) {
            return YES;
        }
    }
    return NO;
}

-(void) removeObject:(WGObject *)object {
    [self.objects removeObject:object];
}

-(NSUInteger) count {
    return [self.objects count];
}

-(NSArray *) idArray {
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    for (WGObject *object in self.objects) {
        if (!object.id) {
            NSLog(@"No Object ID for object: %@", object);
            continue;
        }
        [ids addObject:object.id];
    }
    return ids;
}

#pragma mark - Enumeration

-(id) nextObject {
    if (self.currentPosition >= [self.objects count]) {
        self.currentPosition = 0;
        return nil;
    }
    self.currentPosition += 1;
    return [self.objects objectAtIndex: (self.currentPosition - 1)];
}

-(NSArray *) allObjects {
    return [self.objects subarrayWithRange:NSMakeRange(self.currentPosition, [self.objects count] - self.currentPosition)];
}

#pragma mark - Pagination

-(void) addNextPage:(BoolResultBlock)handler {
    if (!self.nextPage) {
        handler(NO, [NSError errorWithDomain: @"WGCollection" code: 0 userInfo: @{NSLocalizedDescriptionKey : @"no next page" }]);
        return;
    }
    __weak typeof(self) weakSelf = self;
    [WGApi get:self.nextPage withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            handler(NO, error);
            return;
        }
        NSError *dataError;
        @try {
            WGCollection *objects = [WGCollection serializeResponse:jsonResponse andClass:strongSelf.type];
            [strongSelf addObjectsFromCollection:objects];
            strongSelf.hasNextPage = objects.hasNextPage;
            strongSelf.nextPage = objects.nextPage;
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGCollection" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}

-(void) getNextPage:(WGCollectionResultBlock)handler {
    if (!self.nextPage) {
        handler(nil, [NSError errorWithDomain: @"WGCollection" code: 0 userInfo: @{NSLocalizedDescriptionKey : @"no next page" }]);
        return;
    }
    __weak typeof(self) weakSelf = self;
    [WGApi get:self.nextPage withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:strongSelf.type];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGCollection" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

-(void)setPagination:(NSDictionary *)metaDictionary {
    self.hasNextPage = [metaDictionary objectForKey:@"has_next_page"];
    if (self.hasNextPage && [self.hasNextPage  boolValue]) {
        self.nextPage = [metaDictionary objectForKey:@"next"];
        self.nextPage = [self.nextPage substringFromIndex:5];
    }
}

@end
