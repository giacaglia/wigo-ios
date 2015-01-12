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
#define kRankKey @"rank"
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

-(void) setRank:(NSNumber *)rank {
    [self setObject:rank forKey:kRankKey];
}

-(NSNumber *) rank {
    return [self objectForKey:kRankKey];
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

+(void) getWaitlist:(WGCollectionResultBlock)handler {
    [WGApi get:@"groups/?query=waitlist" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGGroup" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getGroupSummary:(WGGroupSummaryResultBlock)handler {
    [WGApi get:@"groups/summary" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, nil, nil, nil, error);
            return;
        }
        NSError *dataError;
        NSNumber *total;
        NSNumber *numGroups;
        NSNumber *private;
        NSNumber *public;
        @try {
            total = [jsonResponse objectForKey:@"total"];
            numGroups = [jsonResponse objectForKey:@"num_groups"];
            private = [jsonResponse objectForKey:@"private"];
            public = [jsonResponse objectForKey:@"public"];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGGroup" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(total, numGroups, private, public, dataError);
        }
    }];
}

@end
