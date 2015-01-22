//
//  WGEvent.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGEvent.h"
#import "WGProfile.h"

#define kNameKey @"name"

#define kIsReadKey @"is_read"
#define kIsExpiredKey @"is_expired"
#define kExpiresKey @"expires"
#define kNumAttendingKey @"num_attending"
#define kNumMessagesKey @"num_messages"
#define kAttendeesKey @"attendees"
#define kHighlightKey @"highlight"

@interface WGEvent()

@end

@implementation WGEvent

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"event";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"event";
    }
    return self;
}

-(void) replaceReferences {
    [super replaceReferences];
    if ([self objectForKey:kAttendeesKey]  && [[self objectForKey:kAttendeesKey] isKindOfClass:[NSArray class]]) {
        [self.parameters setObject:[WGCollection serializeArray:[self objectForKey:kAttendeesKey] andClass:[WGEventAttendee class]] forKey:kAttendeesKey];
    }
    if ([self objectForKey:kHighlightKey]  && [[self objectForKey:kHighlightKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGEventMessage serialize:[self objectForKey:kHighlightKey]] forKey:kHighlightKey];
    }
}

+(WGEvent *)serialize:(NSDictionary *)json {
    return [[WGEvent alloc] initWithJSON:json];
}

-(void) setName:(NSString *)name {
    [self setObject:name forKey:kNameKey];
}

-(NSString *) name {
    return [self objectForKey:kNameKey];
}

-(void) setExpires:(NSDate *)expires {
    [self setObject:[expires deserialize] forKey:kExpiresKey];
}

-(NSDate *) expires {
    return [NSDate serialize:[self objectForKey:kExpiresKey]];
}

-(void) setNumAttending:(NSNumber *)numAttending {
    [self setObject:numAttending forKey:kNumAttendingKey];
}

-(NSNumber *) numAttending {
    return [self objectForKey:kNumAttendingKey];
}

-(void) setIsRead:(NSNumber *)isRead {
    [self setObject:isRead forKey:kIsReadKey];
}

-(NSNumber *) isRead {
    return [self objectForKey:kIsReadKey];
}

-(void) setIsExpired:(NSNumber *)isExpired {
    [self setObject:isExpired forKey:kIsExpiredKey];
}

-(NSNumber *) isExpired {
    return [self objectForKey:kIsExpiredKey];
}

-(void) setNumMessages:(NSNumber *)numMessages {
    [self setObject:numMessages forKey:kNumMessagesKey];
}

-(NSNumber *) numMessages {
    return [self objectForKey:kNumMessagesKey];
}

-(void) setHighlight:(WGEventMessage *)highlight {
    [self setObject:highlight forKey:kHighlightKey];
}

-(WGEventMessage *) highlight {
    return [self objectForKey:kHighlightKey];
}

-(void) setAttendees:(WGCollection *)attendees {
    [self setObject:attendees forKey:kAttendeesKey];
}

-(WGCollection *) attendees {
    return [self objectForKey:kAttendeesKey];
}

-(void) addAttendee:(WGEventAttendee *)attendee {
    if (self.attendees) {
        [self.attendees addObject:attendee];
        return;
    }
    self.attendees = [WGCollection serializeArray:@[ [attendee deserialize] ] andClass:[WGEventAttendee class]];
}

-(void) setRead:(BoolResultBlock)handler {
    [WGApi post:@"events/read/" withParameters:@[ self.id ] andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) setMessagesRead:(WGCollection *) messages andHandler:(BoolResultBlock)handler {
    [WGApi post:[NSString stringWithFormat:@"events/%@/messages/read/", self.id] withParameters:[messages idArray] andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) getMessages:(WGCollectionResultBlock)handler {
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

+(void) get:(WGCollectionResultBlock)handler {
    [WGApi get:@"events" withArguments:@{ @"attendees_limit" : @10, @"limit" : @10 } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

+(void) getWithGroupNumber: (NSNumber *)groupNumber andHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"events" withArguments:@{ @"group" : groupNumber, @"attendees_limit" : @10, @"limit" : @10 } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

+(void) createEventWithName:(NSString *)name andHandler:(WGEventResultBlock)handler {
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

-(void) refresh:(BoolResultBlock)handler {
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@?attendees_limit=10", self.className, self.id];
    
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


@end
