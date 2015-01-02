//
//  WGMessage.m
//  Wigo
//
//  Created by Adam Eagle on 12/30/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGMessage.h"

#define kToUserKey @"to_user"
#define kUserKey @"user"
#define kMessageKey @"message"
#define kIsReadKey @"is_read"
#define kExpiredKey @"expired"

@implementation WGMessage

+(WGMessage *)serialize:(NSDictionary *)json {
    WGMessage *newWGMessage = [WGMessage new];
    
    newWGMessage.className = @"message";
    [newWGMessage initializeWithJSON:json];
    
    return newWGMessage;
}

-(void) setMessage:(NSString *)message {
    [self setObject:message forKey:kMessageKey];
}

-(NSString *) message {
    return [self objectForKey:kMessageKey];
}

-(void) setIsRead:(NSNumber *)isRead {
    [self setObject:isRead forKey:kIsReadKey];
}

-(NSNumber *) isRead {
    return [self objectForKey:kIsReadKey];
}

-(void) setExpired:(NSNumber *)expired {
    [self setObject:expired forKey:kExpiredKey];
}

-(NSNumber *) expired {
    return [self objectForKey:kExpiredKey];
}

-(void) setUser:(WGUser *)user {
    [self setObject:[user deserialize] forKey:kUserKey];
}

-(WGUser *) user {
    return [WGUser serialize:[self objectForKey:kUserKey]];
}

-(void) setToUser:(WGUser *)toUser {
    [self setObject:[toUser deserialize] forKey:kToUserKey];
}

-(WGUser *) toUser {
    return [WGUser serialize:[self objectForKey:kToUserKey]];
}

+(void) get:(CollectionResult)handler {
    [WGApi get:@"messages/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *messages = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        handler(messages, error);
    }];
}

-(void) deleteConversation:(BoolResult)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.toUser.id];
    [WGApi delete:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        handler(YES, error);
    }];
    
}

-(void) readConversation:(BoolResult)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.toUser.id];
    
    NSDictionary *options = @{ @"read": [NSNumber numberWithBool:YES] };
    
    [WGApi post:queryString withParameters:options andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        handler(YES, error);
    }];
}

@end
