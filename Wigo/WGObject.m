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

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"object";
        self.modifiedKeys = [[NSMutableArray alloc] init];
        self.parameters = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    if (json == nil || ![json isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.className = @"object";
        self.modifiedKeys = [[NSMutableArray alloc] init];
        self.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
    }
    return self;
}

+(WGObject *) serialize:(NSDictionary *)json {
    return [[WGObject alloc] initWithJSON:json];
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

-(void) save:(BoolResultBlock)handler {
    NSMutableDictionary *properties = (NSMutableDictionary *) [self modifiedDictionary];
    
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    
    [WGApi post:thisObjectURL withParameters:properties andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self.modifiedKeys removeAllObjects];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGObject" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}

-(void) refresh:(BoolResultBlock)handler {
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    
    [WGApi get:thisObjectURL withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self.modifiedKeys removeAllObjects];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGObject" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}

-(void) create:(BoolResultBlock)handler {
    NSString *classURL = [NSString stringWithFormat:@"%@s/", self.className];
    
    [WGApi post:classURL withParameters:self.parameters andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self.modifiedKeys removeAllObjects];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGObject" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}

-(void) remove:(BoolResultBlock)handler {
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    [WGApi delete:thisObjectURL withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) setObject:(id)object forKey:(id<NSCopying>)key {
    [self.parameters setObject:object forKey:key];
    [self.modifiedKeys addObject:key];
}

-(id) objectForKey:(NSString *)key {
    return [self.parameters objectForKey:key];
}

+(void) get:(WGCollectionResultBlock)handler {
    handler(nil, nil);
}

@end
