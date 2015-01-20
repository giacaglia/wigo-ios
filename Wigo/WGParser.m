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

-(id) init {
    if (self = [super init]) {
        self.cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(id) replaceReferences:(id) object {
    [self addReferencesToCache:object];
    
    if ([[self.cache allKeys] count] > 0) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            return [self replaceReferencesInDictionary:object];
        } else if ([object isKindOfClass:[NSArray class]]) {
            return [self replaceReferencesInArray: object];
        } else {
            return object;
        }
    } else {
        return object;
    }
}

-(void) addReferencesToCache:(id) object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        [self addReferencesInDictionary:object];
    } else if ([object isKindOfClass:[NSArray class]]) {
        [self addReferencesInArray:object];
    }
}

-(void) addReferencesInDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:kReferenceIdKey]) {
        [self.cache setObject:dictionary forKey:[dictionary objectForKey:kReferenceIdKey]];
    }
    for (id key in [dictionary allKeys]) {
        id object = [dictionary objectForKey:key];
        if (object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [self addReferencesInDictionary:object];
            } else if ([object isKindOfClass:[NSArray class]]) {
                [self addReferencesInArray:object];
            }
        }
    }
}

-(void) addReferencesInArray:(NSArray *) array {
    for (int i = 0; i < [array count]; i++) {
        id object = [array objectAtIndex:i];
        if (object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [self addReferencesInDictionary:object];
            } else if ([object isKindOfClass:[NSArray class]]) {
                [self addReferencesInArray:object];
            }
        }
    }
}

-(NSDictionary *) replaceReferencesInDictionary:(NSDictionary *) dictionary {
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    if ([dictionary objectForKey:kReferenceKey]) {
        return [self.cache objectForKey:[dictionary objectForKey:kReferenceKey]];
    }
    
    for (id key in [dictionary allKeys]) {
        id object = [dictionary objectForKey:key];
        if (object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [newDict setObject:[self replaceReferencesInDictionary: object] forKey:key];
            } else if ([object isKindOfClass:[NSArray class]]) {
                [newDict setObject:[self replaceReferencesInArray: object] forKey:key];
            } else {
                [newDict setObject:object forKey:key];
            }
        }
    }
    
    return newDict;
}

-(NSArray *) replaceReferencesInArray:(NSArray *) array {
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [array count]; i++) {
        id object = [array objectAtIndex:i];
        if (object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [newArray addObject:[self replaceReferencesInDictionary: object]];
            } else if ([object isKindOfClass:[NSArray class]]) {
                [newArray addObject:[self replaceReferencesInArray: object]];
            } else {
                [newArray addObject:object];
            }
        }
    }
    return newArray;
}

@end
