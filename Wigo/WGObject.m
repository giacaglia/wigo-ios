//
//  WGObject.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <objc/runtime.h>
#import "WGObject.h"

#define kIdKey @"id"

@implementation WGObject

+(WGObject *)serialize:(NSDictionary *)json {
    WGObject *newWGObject = [WGObject new];
    
    newWGObject.className = @"class";
    newWGObject.id = [json st_integerForKey:kIdKey];
    
    return newWGObject;
}

- (BOOL)isEqual:(WGObject*)other {
    return self.id == other.id;
}

-(NSDictionary *) deserialize {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    // Regex to find camel case
    NSRegularExpression *regexp = [NSRegularExpression
                                   regularExpressionWithPattern:@"([a-z])([A-Z])"
                                   options:0
                                   error:NULL];
    
    unsigned int count, i;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    for (i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithFormat:@"%s", property_getName(property)];
        id value = [self valueForKey:(NSString *)key];
        
        if (value) {
            // Convert property name (camel case) to server format (lowercase & underscores)
            NSString *keyAddUnderscore = [regexp
                                   stringByReplacingMatchesInString:key
                                   options:0 
                                   range:NSMakeRange(0, key.length)
                                   withTemplate:@"$1_$2"];
            NSString *lowercasedKey = [keyAddUnderscore lowercaseString];
            
            [props setObject:value forKey:lowercasedKey];
        }
    }
    return props;
}

- (void)save:(ObjectResult)handler {
    NSMutableDictionary *properties = (NSMutableDictionary *) [self deserialize];
    [properties removeObjectForKey:@"facebook_id"];
    [properties removeObjectForKey:@"id"];
    [properties removeObjectForKey:@"key"];
    [properties removeObjectForKey:@"group_rank"];
    [properties removeObjectForKey:@"group"];
    [properties removeObjectForKey:@"created"];
    [properties removeObjectForKey:@"properties"];
    [properties removeObjectForKey:@"is_going_out"];
    
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%ld", self.className, (long)self.id];
    
    [WGApi post:thisObjectURL withParameters:properties andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        WGObject *object = [self.class serialize:jsonResponse];
        handler(object, error);
    }];
}


@end
