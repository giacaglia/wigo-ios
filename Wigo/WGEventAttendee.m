//
//  WGEventAttendee.m
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGEventAttendee.h"

#define kUserKey @"user"

@implementation WGEventAttendee

+(WGEventAttendee *)serialize:(NSDictionary *)json {
    WGEventAttendee *newWGEventAttendee = [WGEventAttendee new];
    
    newWGEventAttendee.className = @"eventattendee";
    [newWGEventAttendee initializeWithJSON:json];
    
    return newWGEventAttendee;
}

-(void) setUser:(WGUser *)user {
    [self setObject:[user deserialize] forKey:kUserKey];
}

-(WGUser *) user {
    return [WGUser serialize: [self objectForKey:kUserKey]];
}

@end
