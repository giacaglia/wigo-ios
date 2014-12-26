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
    
    newWGObject.modifiedKeys = [[NSMutableArray alloc] init];
    newWGObject.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
    
    return newWGObject;
}

-(void) setId:(NSNumber *)id {
    [self.parameters setObject:id forKey:kIdKey];
    [self.modifiedKeys addObject:kIdKey];
}

-(NSNumber *) id {
    return [self.parameters objectForKey:kIdKey];
}

- (BOOL)isEqual:(WGObject*)other {
    return self.id == other.id;
}

-(NSDictionary *) deserialize {
    return [[NSDictionary alloc] initWithDictionary: self.parameters];
}

-(NSDictionary *) modifiedDictionary {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    for (NSString* key in self.modifiedKeys) {
        [props setObject:[self.parameters objectForKey:key] forKey:key];
    }
    
    return props;
}

- (void)save:(ObjectResult)handler {
    NSMutableDictionary *properties = (NSMutableDictionary *) [self modifiedDictionary];
    
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    
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
