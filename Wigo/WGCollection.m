//
//  WGCollection.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGCollection.h"

@implementation WGCollection {
    BOOL _hasNextPage;
    NSString *_nextPage;
}

#pragma mark - Init

+(WGCollection *)initWithResponse:(NSDictionary *) jsonResponse {
    WGCollection *newCollection = [WGCollection new];
    [newCollection setPaginationFromDictionary: [jsonResponse objectForKey:@"meta"]];
    [newCollection setObjectsFromJson: [jsonResponse objectForKey:@"objects"]];
    return newCollection;
}

#pragma mark - Objects

-(void) setObjectsFromJson:(NSArray *)objects {
    for (NSDictionary *objectDict in objects) {
        [self addObject: [WGObject initWithJson: objectDict]];
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

-(void)setHasNextPage:(BOOL)hasNextPage {
    _hasNextPage = hasNextPage;
}

-(void)setNextPage:(NSString *)nextPage {
    _nextPage = nextPage;
}

-(BOOL)hasNextPage {
    return _hasNextPage;
}

-(NSString *)nextPage {
    return _nextPage;
}

@end
