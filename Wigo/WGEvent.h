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
@property BOOL isPrivate;
@property NSDate *expires;
@property NSNumber *isRead;
@property NSNumber *isExpired;
@property NSNumber *numAttending;
@property NSNumber *numMessages;
@property WGCollection *messages;
@property WGCollection *attendees;
@property WGEventMessage *highlight;
@property NSArray *tags;
@property BOOL isAggregate;
@property (nonatomic, assign) BOOL isVerified;

-(WGUser *) owner;
+(WGEvent *) serialize:(NSDictionary *)json;

-(void) addAttendee:(WGEventAttendee *)attendee;

-(void) setPrivacyOn:(BOOL)privacy andHandler:(BoolResultBlock)handler;
-(void) setRead:(BoolResultBlock)handler;
-(void) setMessagesRead:(WGCollection *) messages andHandler:(BoolResultBlock)handler;

-(void) getMeta:(WGCollectionResultBlock)handler;
-(void) getInvites:(WGCollectionResultBlock)handler;
-(void) getMessages:(WGCollectionResultBlock)handler;
-(void) getMessagesForHighlights:(WGEventMessage *)highlight
        withHandler:(WGCollectionResultBlock)handler;

+(void) getAggregateStatsWithHandler:(WGAggregateStats)handler;
+(void) getWithGroupNumber:(NSNumber *)groupNumber andHandler:(WGCollectionResultBlock)handler;
+(void) createEventWithName:(NSString *)name andPrivate:(BOOL)isPrivate andHandler:(WGEventResultBlock)handler;
@end
