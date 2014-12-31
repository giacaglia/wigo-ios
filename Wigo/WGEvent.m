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
        handler(jsonResponse != nil, error);
    }];
}

-(void) setMessagesRead:(WGCollection *) messages andHandler:(BoolResult)handler {
    [WGApi post:[NSString stringWithFormat:@"events/%@/messages/read/", self.id] withParameters:[messages idArray] andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(jsonResponse != nil, error);
    }];
}

-(void) getMessages:(CollectionResult)handler {
    [WGApi get:[NSString stringWithFormat:@"eventmessages/?event=%@&ordering=id", self.id] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
#warning CHANGE TO EVENT_MESSAGE
        WGCollection *events = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        handler(events, error);
    }];
}

+(void) get:(CollectionResult)handler {
    [WGApi get:@"events?attendees_limit=10" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *events = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        handler(events, error);
    }];
}

+(void) getWithGroupNumber: (NSInteger)groupNumber andHandler:(CollectionResult)handler {
    [WGApi get:[NSString stringWithFormat:@"events?group=%ld&date=tonight&attendees_limit=10", (long) groupNumber] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *events = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        handler(events, error);
    }];
}

@end
