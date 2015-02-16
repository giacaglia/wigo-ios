//
//  WGEventAttendee.m
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGEventAttendee.h"
#import "WGEvent.h"

#define kUserKey @"user"
#define kEventOwnerKey @"event_owner"

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

-(void) replaceReferences {
    [super replaceReferences];
    if ([self objectForKey:kUserKey] && [[self objectForKey:kUserKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGUser serialize:[self objectForKey:kUserKey]] forKey:kUserKey];
    }
}

+(WGEventAttendee *)serialize:(NSDictionary *)json {
    return [[WGEventAttendee alloc] initWithJSON:json];
}

-(void) setUser:(WGUser *)user {
    [self setObject:user forKey:kUserKey];
}

-(WGUser *) user {
    return [self objectForKey:kUserKey];
}

-(void) setEventOwner:(NSNumber *)eventOwner {
    [self setObject:eventOwner forKey:kEventOwnerKey];
}

-(NSNumber *) eventOwner {
    return [self objectForKey:kEventOwnerKey];
}

@end
