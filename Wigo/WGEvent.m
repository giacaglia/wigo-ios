//
//  WGEvent.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGEvent.h"

#define kNameKey @"name"

#define kNumAttendingKey @"num_attending" //: 5,
#define kNumMessagesKey @"num_messages"
#define kAttendeesKey @"attendees"

@interface WGEvent()

@end

@implementation WGEvent

+(WGEvent *)serialize:(NSDictionary *)json {
    WGEvent *newWGEvent = [WGEvent new];
    
    newWGEvent.className = @"event";
    newWGEvent.dateFormatter = [[NSDateFormatter alloc] init];
    [newWGEvent.dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    
    newWGEvent.modifiedKeys = [[NSMutableArray alloc] init];
    newWGEvent.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
    
    return newWGEvent;
}

-(void) setName:(NSString *)name {
    [self.parameters setObject:name forKey:kNameKey];
    [self.modifiedKeys addObject:kNameKey];
}

-(NSString *) name {
    return [self.parameters objectForKey:kNameKey];
}

-(void) setNumAttending:(NSNumber *)numAttending {
    [self.parameters setObject:numAttending forKey:kNumAttendingKey];
    [self.modifiedKeys addObject:kNumAttendingKey];
}

-(NSNumber *) numAttending {
    return [self.parameters objectForKey:kNumAttendingKey];
}

-(void) setNumMessages:(NSNumber *)numMessages {
    [self.parameters setObject:numMessages forKey:kNumMessagesKey];
    [self.modifiedKeys addObject:kNumMessagesKey];
}

-(NSNumber *) numMessages {
    return [self.parameters objectForKey:kNumMessagesKey];
}

-(void) setAttendees:(WGCollection *)attendees {
    [self.parameters setObject:[attendees deserialize] forKey:kAttendeesKey];
    [self.modifiedKeys addObject:kAttendeesKey];
}

-(WGCollection *) attendees {
    return [WGCollection serialize:[self.parameters objectForKey:kAttendeesKey] andClass:[WGUser class]];
}

-(void) addAttendee:(WGUser *)attendee {
    if (self.attendees) {
        [self.attendees addObject:attendee];
        return;
    }
    NSArray *array = [[NSArray alloc] initWithObjects:[attendee deserialize], nil];
    self.attendees = [WGCollection serialize:@{ @"objects" : array } andClass:[WGUser class]];
}

+(void) getEvents:(CollectionResult)handler {
    [WGApi get:@"events/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *events = [WGCollection serialize:jsonResponse andClass:[self class]];
        handler(events, error);
    }];
}

+(void) getEventsWithGroupNumber: (NSInteger)groupNumber andHandler:(CollectionResult)handler {
    [WGApi get:[NSString stringWithFormat:@"events/?group=%ld&date=tonight&attendees_limit=10", (long) groupNumber] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *events = [WGCollection serialize:jsonResponse andClass:[self class]];
        handler(events, error);
    }];
}

@end
