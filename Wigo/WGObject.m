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
    [self initDateFormatter];
    
    self.modifiedKeys = [[NSMutableArray alloc] init];
    self.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
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
