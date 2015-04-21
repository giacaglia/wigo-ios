//
//  WGCache.m
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGParser.h"
#import "WGCache.h"

#define kReferenceIdKey @"$id"
#define kReferenceKey @"$ref"

@implementation WGParser


-(id) replaceReferences:(id) object {
    [self addReferencesToCache:object];
    
    if ([[[WGCache sharedCache] allKeys] count] > 0) {
        return [self replaceReferencesInObject:object];
    } else {
        return object;
    }
}

-(void) addReferencesToCache:(id) object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *objDict = (NSDictionary *)object;
        if ([objDict objectForKey:kReferenceIdKey]) {
            [[WGCache sharedCache] setObject:objDict
                                      forKey:[objDict objectForKey:kReferenceIdKey]];
            return;
        }
        for (id key in [objDict allKeys]) {
            id element = [objDict objectForKey:key];
            [self addReferencesToCache:element];
        }
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *objArray = (NSArray *)object;
        for (id element in objArray) {
            [self addReferencesToCache:element];
        }
    }
}

- (id)replaceReferencesInObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *objDict = (NSDictionary *)object;
        if ([objDict objectForKey:kReferenceKey] &&
            [[WGCache sharedCache] objectForKey:[objDict objectForKey:kReferenceKey]]) {
            return [[WGCache sharedCache] objectForKey:[objDict objectForKey:kReferenceKey]];
        }
        NSMutableDictionary *newDict = [NSMutableDictionary new];
        for (id key in [objDict allKeys]) {
            id element = [objDict objectForKey:key];
            id newElement = [self replaceReferencesInObject:element];
            [newDict setObject:newElement forKeyedSubscript:key];
        }
        return newDict;
    }
   
    else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *objArray = (NSArray *)object;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id element in objArray) {
            id newElement = [self replaceReferencesInObject:element];
            [newArray addObject:newElement];
        }
        return newArray;
    }
    return object;
}

@end
