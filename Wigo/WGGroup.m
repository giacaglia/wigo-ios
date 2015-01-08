//
//  WGGroup.m
//  Wigo
//
//  Created by Adam Eagle on 1/7/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGGroup.h"

#define kNameKey @"name"
#define kLockedKey @"locked"
#define kUnlockAtKey @"unlock_at"
#define kNumMembersKey @"num_members"
#define kNumEventsKey @"num_events"

@implementation WGGroup

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"group";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"group";
    }
    return self;
}

+(WGGroup *) serialize:(NSDictionary *)json {
    return [[WGGroup alloc] initWithJSON:json];
}

-(void) setName:(NSString *)name {
    [self setObject:name forKey:kNameKey];
}

-(NSString *) name {
    return [self objectForKey:kNameKey];
}

-(void) setLocked:(NSNumber *)locked {
    [self setObject:locked forKey:kLockedKey];
}

-(NSNumber *) locked {
    return [self objectForKey:kLockedKey];
}

-(void) setUnlockAt:(NSNumber *)unlockAt {
    [self setObject:unlockAt forKey:kUnlockAtKey];
}

-(NSNumber *) unlockAt {
    return [self objectForKey:kUnlockAtKey];
}

-(void) setNumEvents:(NSNumber *)numEvents {
    [self setObject:numEvents forKey:kNumEventsKey];
}

-(NSNumber *) numEvents {
    return [self objectForKey:kNumEventsKey];
}

-(void) setNumMembers:(NSNumber *)numMembers {
    [self setObject:numMembers forKey:kNumMembersKey];
}

-(NSNumber *) numMembers {
    return [self objectForKey:kNumMembersKey];
}

@end
