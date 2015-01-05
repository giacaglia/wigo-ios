//
//  WGEvent.h
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGEventAttendee.h"
#import "WGEventMessage.h"

@interface WGEvent : WGObject

typedef void (^EventResult)(WGEvent *object, NSError *error);

@property NSString *name;
@property NSNumber *numAttending;
@property NSNumber *numMessages;
@property WGCollection *attendees;

+(WGEvent *)serialize:(NSDictionary *)json;

-(void) addAttendee:(WGEventAttendee *)attendee;

-(void) setRead:(BoolResult)handler;
-(void) setMessagesRead:(WGCollection *) messages andHandler:(BoolResult)handler;

-(void) getMessages:(CollectionResult)handler;

+(void) getWithGroupNumber: (NSInteger)groupNumber andHandler:(CollectionResult)handler;

+(void) createEventWithName:(NSString *)name andHandler:(EventResult)handler;

@end
