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
    [newCollection setPaginationFromDictionary: [jsonResponse objectForKey:@"meta"]];
    [newCollection setObjectsFromJson: [jsonResponse objectForKey:@"objects"] andType:type];
    return newCollection;
}

#pragma mark - Objects

-(void) setObjectsFromJson:(NSArray *)objects andType:(Class)type {
    _objects = [[NSMutableArray alloc] init];
    for (NSDictionary *objectDict in objects) {
        WGObject *object = [type serialize:objectDict];
        [_objects addObject: object];
    }
}

#pragma mark - Pagination

-(void)setPaginationFromDictionary:(NSDictionary *)metaDictionary {
    if ([[metaDictionary allKeys] containsObject:@"has_next_page"]) {
        BOOL hasNextPage = [(NSNumber *) [metaDictionary objectForKey:@"has_next_page"] boolValue];
        [self setHasNextPage:hasNextPage];
    }
    if ([[metaDictionary allKeys] containsObject:@"next"]) {
        NSString *nextPage = (NSString *)[metaDictionary objectForKey:@"next"];
        [self setNextPage:nextPage];
    }
}

@end
