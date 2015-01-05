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

@implementation WGNotification

+(WGNotification *)serialize:(NSDictionary *)json {
    WGNotification *newWGNotification = [WGNotification new];
    
    newWGNotification.className = @"notification";
    [newWGNotification initializeWithJSON:json];
    
    return newWGNotification;
}

-(void) setType:(NSString *)type {
    [self setObject:type forKey:kTypeKey];
}

-(NSString *) type {
    return [self objectForKey:kTypeKey];
}

-(void) setFromUser:(WGUser *)fromUser {
    [self setObject:[fromUser deserialize] forKey:kFromUserKey];
}

-(WGUser *) fromUser {
    return [WGUser serialize:[self objectForKey:kFromUserKey]];
}

-(NSString *) message {
    NSString *type = self.type;
    if ([type isEqualToString:@"tap"]) {
        if ([self.created isFromLastDay]) {
            // if ([self.fromUser isAttending] && [self.fromUser attendingEventName]) {
            //    return [NSString stringWithFormat:@"wants to see you out at %@", [fromUser attendingEventName]];
            // }
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
    return @"";
}

+(void) get:(CollectionResult)handler {
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


@end
