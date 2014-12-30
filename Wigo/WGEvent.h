//
//  WGEvent.h
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"
#import "WGCollection.h"

@interface WGEvent : WGObject

typedef void (^EventResult)(WGEvent *object, NSError *error);

@property NSDateFormatter *dateFormatter;

@property NSString *name;
@property NSNumber *numAttending;
@property NSNumber *numMessages;
@property WGCollection *attendees;

+(WGEvent *)serialize:(NSDictionary *)json;

-(void) addAttendee:(WGUser *)attendee;

+(void) getEvents:(CollectionResult)handler;
+(void) getEventsWithGroupNumber: (NSInteger)groupNumber andHandler:(CollectionResult)handler;

@end
