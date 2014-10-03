//
//  Event.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/19/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface Event : NSObject

@property NSString *name;
@property NSNumber* eventID;
@property NSNumber *numberAttending;

- (id)initWithDictionary:(NSDictionary *)otherDictionary;
- (void)addEventAttendeesWithDictionary:(NSDictionary *)eventAttendeesDictionary;
- (NSArray *)getEventAttendees;
- (NSDictionary *)dictionary;

@end
