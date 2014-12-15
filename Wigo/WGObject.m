//
//  WGObject.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"

#define kIdKey @"id"

@implementation WGObject

+(WGObject *)serialize:(NSDictionary *)json {
    WGObject *newWGObject = [WGObject new];
    
    for (id key in [json allKeys])
    {
        [newWGObject setValue:[[json objectForKey:key] mutableCopy] forKey:key];
    }
    
    newWGObject.id = [newWGObject numberAtKey:kIdKey];
    
    return newWGObject;
}

-(NSNumber *) numberAtKey:(NSString *)key {
    return (NSNumber *) [self objectForKey:key];
}

-(NSString *) stringAtKey:(NSString *)key {
    return (NSString *) [self objectForKey:key];
}

-(NSDictionary *) dictionaryAtKey:(NSString *)key {
    return (NSDictionary *) [self objectForKey:key];
}

-(NSDate *) dateAtKey:(NSString *)key {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    return [dateFormatter dateFromString: [self stringAtKey:key]];
}

@end
