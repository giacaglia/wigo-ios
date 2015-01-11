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

typedef void (^WGEventResultBlock)(WGEvent *object, NSError *error);

@property NSString *name;
@property NSString *expires;
@property NSNumber *isRead;
@property NSNumber *isExpired;
@property NSNumber *numAttending;
@property NSNumber *numMessages;
@property WGCollection *attendees;
@property WGEventMessage *highlight;

+(WGEvent *)serialize:(NSDictionary *)json;

-(void) addAttendee:(WGEventAttendee *)attendee;

-(void) setRead:(BoolResultBlock)handler;
-(void) setMessagesRead:(WGCollection *) messages andHandler:(BoolResultBlock)handler;

-(void) getMessages:(WGCollectionResultBlock)handler;

+(void) getWithGroupNumber:(NSNumber *)groupNumber andHandler:(WGCollectionResultBlock)handler;
+(void) createEventWithName:(NSString *)name andHandler:(WGEventResultBlock)handler;

@end
