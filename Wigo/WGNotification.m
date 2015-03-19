//
//  WGNotification.m
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGNotification.h"

#define kFromUserKey @"from_user"
#define kTypeKey @"type"
#define kMessageKey @"message"
#define kPropertiesKey @"properties"
#define kEventName @"event_name"
#define kEventID @"event_id"

@implementation WGNotification

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"notification";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"notification";
    }
    return self;
}

-(void) replaceReferences {
    [super replaceReferences];
    if ([self objectForKey:kFromUserKey] && [[self objectForKey:kFromUserKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGUser serialize:[self objectForKey:kFromUserKey]] forKey:kFromUserKey];
    }
}

+(WGNotification *)serialize:(NSDictionary *)json {
    return [[WGNotification alloc] initWithJSON:json];
}

-(void) setType:(NSString *)type {
    [self setObject:type forKey:kTypeKey];
}

-(NSString *) type {
    return [self objectForKey:kTypeKey];
}

-(void) setFromUser:(WGUser *)fromUser {
    [self setObject:fromUser forKey:kFromUserKey];
}

-(WGUser *) fromUser {
    return [self objectForKey:kFromUserKey];
}

-(NSDictionary *)properties {
    return [self objectForKey:kPropertiesKey];
}

-(NSString *)eventName {
    if (self.properties && [self.properties class] !=[NSNull class]){
        return [self.properties objectForKey:kEventName];
    }
    return nil;
}

- (NSNumber *)eventID {
    if (self.properties &&  [self.properties class] !=[NSNull class]) {
        return [self.properties objectForKey:kEventID];
    }
    return nil;
}
-(NSString *) message {
    NSString *type = self.type;
    if ([type isEqualToString:@"tap"]) {
        if (![self.created isFromLastDay]) {
            if (self.eventName) {
                return [NSString stringWithFormat:@"wants to see you out at %@", self.eventName];
            }
            return @"wants to see you out";
        } else {
            return @"wanted to see you out";
        }
    } else if( [type isEqualToString:@"follow"] || [type isEqualToString:@"facebook.follow"]) {
        return @"is now following you";
    } else if ([type isEqualToString:@"joined"]) {
        return @"joined WiGo";
    } else if ([type isEqualToString:@"goingout"]) {
        return @"is going out";
    } else if ([type isEqualToString:@"follow.accepted"]) {
        return @"accepted your follow request";
    }
    else {
        return [self.properties objectForKey:kMessageKey];
    }
}

+(void) get:(WGCollectionResultBlock)handler {
    [WGApi get:@"notifications/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGNotification" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getFollowRequests:(WGCollectionResultBlock)handler {
    [WGApi get:@"notifications/?type=follow.request" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGNotification" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getFollowSummary:(WGNotificationSummaryResultBlock)handler {
    [WGApi get:@"notifications/summary" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, nil, nil, nil, nil, error);
            return;
        }
        NSError *dataError;
        NSNumber *follow;
        NSNumber *followRequest;
        NSNumber *total;
        NSNumber *tap;
        NSNumber *facebookFollow;
        @try {
            follow = [jsonResponse objectForKey:@"follow"];
            followRequest = [jsonResponse objectForKey:@"follow.request"];
            total = [jsonResponse objectForKey:@"total"];
            tap = [jsonResponse objectForKey:@"tap"];
            facebookFollow = [jsonResponse objectForKey:@"facebook.follow"];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGNotification" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(follow, followRequest, total, tap, facebookFollow, dataError);
        }
    }];
}

@end
