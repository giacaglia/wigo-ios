//
//  WGObject.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <objc/runtime.h>
#import "WGObject.h"
#import "WGCollection.h"
#import "WGCache.h"

#define kIdKey @"id"
#define kCreatedKey @"created"
#define kDateKey @"date"

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
    if ([json objectForKey:kRefKey] &&
        [[WGCache sharedCache] objectForKey:[json objectForKey:kRefKey]]) {
        json = [[WGCache sharedCache] objectForKey:[json objectForKey:kRefKey]];
    }
    self = [super init];
    if (self) {
        self.className = @"object";
        self.modifiedKeys = [[NSMutableArray alloc] init];
        self.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
        [self replaceReferences];
    }
    return self;
}

-(void) replaceReferences {
    // Nothing to replace!
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

-(void) setDate:(NSDate *)date {
    [self setObject:[date deserialize] forKey:kDateKey];
}

-(NSDate *) date {
    return [NSDate serialize:[self objectForKey:kDateKey]];
}


-(BOOL) isFetched {
    return self.id && [self.id intValue] > 0;
}

-(BOOL) isFromLastDay {
    return [self.created isFromLastDay];
}

-(BOOL) isEqual:(id)other {
    if (!other || ![other isKindOfClass:[WGObject class]]) {
        return NO;
    }
    WGObject *otherObject = (WGObject *) other;
    if (!self.id || !otherObject.id) {
        return NO;
    }
    return [self.id isEqualToNumber:otherObject.id];
}

-(NSDictionary *) deserializeShallow {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    for (NSString* key in [self.parameters allKeys]) {
        id value = [self.parameters objectForKey:key];
        if ([value isKindOfClass:[WGCollection class]]) {
            [props setObject:[value deserialize] forKey:key];
        } else if (value && ![value isKindOfClass:[WGObject class]] && ![value isEqual:[NSNull null]]) {
            [props setObject:value forKey:key];
        }
    }
    
    return props;
}

-(NSDictionary *) deserialize {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    for (NSString* key in [self.parameters allKeys]) {
        id value = [self.parameters objectForKey:key];
        if ([value isKindOfClass:[WGObject class]]) {
            [props setObject:[value deserializeShallow] forKey:key];
        } else if ([value isKindOfClass:[WGCollection class]]) {
            [props setObject:[value deserialize] forKey:key];
        } else if (value && ![value isEqual:[NSNull null]]) {
            [props setObject:value forKey:key];
        }
    }
    
    return props;
}

-(NSDictionary *) modifiedDictionary {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    for (NSString* key in self.modifiedKeys) {
        id value = [self.parameters objectForKey:key];
        if ([value isKindOfClass:[WGObject class]]) {
            [props setObject:[value deserializeShallow] forKey:key];
        } else if ([value isKindOfClass:[WGCollection class]]) {
            [props setObject:[value deserialize] forKey:key];
        } else if (value && ![value isEqual:[NSNull null]]) {
            [props setObject:value forKey:key];
        }
    }
    
    return props;
}

-(void) save:(BoolResultBlock)handler {
    NSMutableDictionary *properties = (NSMutableDictionary *) [self modifiedDictionary];
    
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    
    [WGApi post:thisObjectURL withParameters:properties andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        
        NSError *dataError;
        @try {
            WGParser *parser = [[WGParser alloc] init];
            NSDictionary *response = [parser replaceReferences:jsonResponse];
            NSDictionary *userDictionary = [[response objectForKey:@"objects"] objectAtIndex:0];
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:userDictionary];
            [self replaceReferences];
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

-(void) saveKey:(NSString *)key withValue:(id)value andHandler:(BoolResultBlock)handler {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    if ([value isKindOfClass:[WGObject class]]) {
        [properties setObject:[value deserialize] forKey:key];
    } else if (value && ![value isEqual:[NSNull null]]) {
        [properties setObject:value forKey:key];
    }
    
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    
    [WGApi post:thisObjectURL withParameters:properties andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        
        NSError *dataError;
        @try {
            [self.parameters setObject:value forKey:key];
            [self.modifiedKeys removeObject:key];
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
            handler(NO, error);
            return;
        }
        
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self replaceReferences];
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
    
    NSMutableDictionary *parametersWithIds = [[NSMutableDictionary alloc] init];
    for (NSString *key in [self.parameters allKeys]) {
        id value = [self.parameters objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] && [value objectForKey:@"id"]) {
            [parametersWithIds setObject:[value objectForKey:@"id"] forKey:key];
        } else if ([value isKindOfClass:[WGObject class]]) {
            WGObject *valueObject = (WGObject *)value;
            [parametersWithIds setObject:valueObject.id forKey:key];
        } else if (value && ![value isEqual:[NSNull null]]) {
            [parametersWithIds setObject:value forKey:key];
        }
    }
    
    [WGApi post:classURL withParameters:parametersWithIds andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self replaceReferences];
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
