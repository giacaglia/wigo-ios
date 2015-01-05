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

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"eventattendee";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"eventattendee";
    }
    return self;
}

+(WGEventAttendee *)serialize:(NSDictionary *)json {
    return [[WGEventAttendee alloc] initWithJSON:json];
}

-(void) setUser:(WGUser *)user {
    [self setObject:[user deserialize] forKey:kUserKey];
}

-(WGUser *) user {
    return [WGUser serialize: [self objectForKey:kUserKey]];
}

@end
