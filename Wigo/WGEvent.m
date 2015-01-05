//
//  WGEvent.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGEvent.h"

#define kNameKey @"name"

#define kNumAttendingKey @"num_attending"
#define kNumMessagesKey @"num_messages"
#define kAttendeesKey @"attendees"

@interface WGEvent()

@end

@implementation WGEvent

+(WGEvent *)serialize:(NSDictionary *)json {
    WGEvent *newWGEvent = [WGEvent new];
    
    newWGEvent.className = @"event";
    [newWGEvent initializeWithJSON:json];
    
    return newWGEvent;
}

-(void) setName:(NSString *)name {
    [self setObject:name forKey:kNameKey];
}

-(NSString *) name {
    return [self objectForKey:kNameKey];
}

-(void) setNumAttending:(NSNumber *)numAttending {
    [self setObject:numAttending forKey:kNumAttendingKey];
}

-(NSNumber *) numAttending {
    return [self objectForKey:kNumAttendingKey];
}

-(void) setNumMessages:(NSNumber *)numMessages {
    [self setObject:numMessages forKey:kNumMessagesKey];
}

-(NSNumber *) numMessages {
    return [self objectForKey:kNumMessagesKey];
}

-(void) setAttendees:(WGCollection *)attendees {
    [self setObject:[attendees deserialize] forKey:kAttendeesKey];
}

-(WGCollection *) attendees {
    return [WGCollection serializeArray:[self objectForKey:kAttendeesKey] andClass:[WGEventAttendee class]];
}

-(void) addAttendee:(WGEventAttendee *)attendee {
    if (self.attendees) {
        [self.attendees addObject:attendee];
        return;
    }
    NSArray *array = [[NSArray alloc] initWithObjects:[attendee deserialize], nil];
    self.attendees = [WGCollection serializeArray:array andClass:[WGEventAttendee class]];
}

-(void) setRead:(BoolResult)handler {
    [WGApi post:@"events/read/" withParameters:@[ self.id ] andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) setMessagesRead:(WGCollection *) messages andHandler:(BoolResult)handler {
    [WGApi post:[NSString stringWithFormat:@"events/%@/messages/read/", self.id] withParameters:[messages idArray] andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) getMessages:(CollectionResult)handler {
    [WGApi get:@"eventmessages/" withArguments:@{ @"event" : self.id, @"ordering" : @"id" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[WGEventMessage class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) get:(CollectionResult)handler {
    [WGApi get:@"events" withArguments:@{ @"attendees_limit" : @10 } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getWithGroupNumber: (NSNumber *)groupNumber andHandler:(CollectionResult)handler {
    [WGApi get:@"events" withArguments:@{ @"group" : groupNumber, @"date" : @"tonight", @"attendees_limit" : @10 } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) createEventWithName:(NSString *)name andHandler:(EventResult)handler {
    [WGApi post:@"events/" withParameters:@{ @"name" : name } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGEvent *object;
        @try {
            object = [WGEvent serialize:jsonResponse];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(object, dataError);
        }
    }];
}

@end
