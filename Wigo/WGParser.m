//
//  WGCache.m
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGParser.h"

#define kReferenceIdKey @"$id"
#define kReferenceKey @"$ref"

@implementation WGParser


-(id) replaceReferences:(id) object {
    [self addReferencesToCache:object];
    
    if ([self.localCache.allKeys count] > 0) {
        id newObject = [self  replaceReferencesInObject:object];
        return newObject;
    } else {
        return object;
    }
}

-(void) addReferencesToCache:(id) object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *objDict = (NSMutableDictionary *)object;
        if ([objDict objectForKey:kReferenceIdKey]) {
            if (!self.localCache) self.localCache = [NSMutableDictionary new];
            [self.localCache setObject:objDict
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
        NSMutableDictionary *objDict = (NSMutableDictionary *)object;
        if ([objDict objectForKey:kReferenceKey] &&
            [self.localCache objectForKey:[objDict objectForKey:kReferenceKey]]) {
            return [self.localCache objectForKey:[objDict objectForKey:kReferenceKey]];
        }
        for (id key in [objDict allKeys]) {
            id element = [objDict objectForKey:key];
            id newElement = [self replaceReferencesInObject:element];
            [objDict setObject:newElement forKeyedSubscript:key];
        }
        return objDict;
    }
   
    else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *objArray = (NSMutableArray *)object;
        for (int i = 0; i < objArray.count; i++) {
            id newElement = [self replaceReferencesInObject:[objArray objectAtIndex:i]];
            [objArray setObject:newElement atIndexedSubscript:i];
        }
        return objArray;
    }
    return object;
}

@end
