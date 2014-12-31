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
#define kReferenceIdKey @"$id"
#define kReferenceKey @"$ref"

@implementation WGObject

+(WGObject *) serialize:(NSDictionary *)json {
    WGObject *newWGObject = [[WGObject alloc] init];
    
    newWGObject.className = @"object";
    [newWGObject initializeWithJSON:json];
    
    return newWGObject;
}

-(void) initializeWithJSON:(NSDictionary *)json {
    [self initDateFormatter];
    
    self.modifiedKeys = [[NSMutableArray alloc] init];
    self.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
    
    [self pullFromCache];
    [self insertIntoCache];
}

-(void) initDateFormatter {
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
}

-(void) setId:(NSNumber *)id {
    [self setObject:id forKey:kIdKey];
}

-(NSNumber *) id {
    return [self objectForKey:kIdKey];
}

-(void) setCreated:(NSDate *)created {
    [self setObject:[self.dateFormatter stringFromDate:created] forKey:kCreatedKey];
}

-(NSDate *) created {
    return [self.dateFormatter dateFromString: [self objectForKey:kCreatedKey]];
}

-(void) setReferenceId:(NSString *)referenceId {
    [self setObject:referenceId forKey:kReferenceIdKey];
}

-(NSString *) referenceId {
    return [self objectForKey:kReferenceIdKey];
}

-(void) setReference:(NSString *)reference {
    [self setObject:reference forKey:kReferenceKey];
}

-(NSString *) reference {
    return [self objectForKey:kReferenceKey];
}

#warning TODO: make this pretty
-(BOOL) wasCreatedLastDay {
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [self.created dateByAddingTimeInterval:timeZoneSeconds];
    NSDate *nowDate = [NSDate date];
    
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:dateInLocalTimezone];
   
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit fromDate:nowDate];

    if ([today day] == [otherDay day] && [today month] == [otherDay month] && [today year] == [otherDay year]) {
        return NO;
    }
    
    return YES;
}

-(BOOL) isEqual:(WGObject*)other {
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

-(void) save:(ObjectResult)handler {
    NSMutableDictionary *properties = (NSMutableDictionary *) [self modifiedDictionary];
    
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@", self.className, self.id];
    
    [WGApi post:thisObjectURL withParameters:properties andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        [self.modifiedKeys removeAllObjects];
        WGObject *object = [self.class serialize:jsonResponse];
        handler(object, error);
    }];
}

-(void) insertIntoCache {
    [[WGApi cache] setObject:[self deserialize] forKey:self.referenceId];
}

-(void) pullFromCache {
    if (self.reference) {
        if ([[WGApi cache] objectForKey:self.reference]) {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary: [[WGApi cache] objectForKey:self.reference]];
        } else {
            NSLog(@"Error: Found $ref but found no matching $id");
        }
    }
    /*
    // Loop through and replace any $ref dicts with cached objects
    for (id key in [self.parameters allKeys]) {
        id object = [self.parameters objectForKey:key];
        // If this object is a dictionary
        if ([object isKindOfClass:[NSDictionary class]]) {
            // If this dictionary contains a $ref
            if ([[object allKeys] containsObject:kReferenceKey]) {
                NSString *reference = [object objectForKey:kReferenceKey];
                // If the cache contains the $ref
                if ([[WGApi cache] objectForKey:reference]) {
                    // Replace the $ref with the associated dictionary
                    NSLog(@"Success: Updating $ref to cached dictionary");
                    NSLog(@"%@", [[WGApi cache] objectForKey:reference]);
                    [self.parameters setObject:[[WGApi cache] objectForKey:reference] forKey:key];
                } else {
                    NSLog(@"Error: Found $ref but found no matching $id");
                }
            }
        }
    } */
}

-(void) setObject:(id)object forKey:(id<NSCopying>)key {
    [self.parameters setObject:object forKey:key];
    [self.modifiedKeys addObject:key];
}

-(id) objectForKey:(NSString *)key {
    id object = [self.parameters objectForKey:key];
    // If this object is a dictionary
    if ([object isKindOfClass:[NSDictionary class]]) {
        // If this dictionary contains a $ref
        if ([[object allKeys] containsObject:kReferenceKey]) {
            NSString *reference = [object objectForKey:kReferenceKey];
            // If the cache contains the $ref
            if ([[WGApi cache] objectForKey:reference]) {
                // Replace the $ref with the associated dictionary
                NSLog(@"Success: Updating $ref to cached dictionary");
                [self.parameters setObject:[[WGApi cache] objectForKey:reference] forKey:key];
            } else {
                NSLog(@"Error: Found $ref but found no matching $id");
            }
        }
    }
    return [self.parameters objectForKey:key];
}

+(void) get:(CollectionResult)handler {
    handler(nil, nil);
}

@end
