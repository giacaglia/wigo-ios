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

#pragma mark - Pagination

-(void)setPagination:(NSDictionary *)metaDictionary {
    self.hasNextPage = [metaDictionary objectForKey:@"has_next_page"];
    if (self.hasNextPage && [self.hasNextPage  boolValue]) {
        self.nextPage = [metaDictionary objectForKey:@"next"];
    }
}

@end
