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
#define kCreatedKey @"created"

@implementation WGObject

+(WGObject *) serialize:(NSDictionary *)json {
    WGObject *newWGObject = [[WGObject alloc] init];
    
    newWGObject.className = @"object";
    [newWGObject initializeWithJSON:json];
    
    return newWGObject;
}

-(void) initializeWithJSON:(NSDictionary *)json {
    self.modifiedKeys = [[NSMutableArray alloc] init];
    self.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
}

-(void) setId:(NSNumber *)id {
    [self setObject:id forKey:kIdKey];
}

-(NSNumber *) id {
    return [self objectForKey:kIdKey];
}

-(void) setCreated:(NSDate *)created {
    [self setObject:[created deserialize] forKey:kCreatedKey];
}

-(NSDate *) created {
    return [NSDate serialize:[self objectForKey:kCreatedKey]];
}

-(BOOL) isEqual:(WGObject*)other {
    return [self.id isEqualToNumber:other.id];
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

-(void) save:(ObjectResult)handler {
    NSMutableDictionary *properties = (NSMutableDictionary *) [self modifiedDictionary];
    
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    
    [WGApi post:thisObjectURL withParameters:properties andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        WGObject *object;
        @try {
            object = [WGObject serialize:jsonResponse];
            [self.modifiedKeys removeAllObjects];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGObject" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(object, dataError);
        }
    }];
}

-(void) setObject:(id)object forKey:(id<NSCopying>)key {
    [self.parameters setObject:object forKey:key];
    [self.modifiedKeys addObject:key];
}

-(id) objectForKey:(NSString *)key {
    return [self.parameters objectForKey:key];
}

+(void) get:(CollectionResult)handler {
    handler(nil, nil);
}

@end
