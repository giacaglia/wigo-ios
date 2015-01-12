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

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"message";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"message";
    }
    return self;
}

+(WGMessage *)serialize:(NSDictionary *)json {
    return [[WGMessage alloc] initWithJSON:json];
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

-(WGUser *) otherUser {
    if ([self.user isCurrentUser]) {
        return self.toUser;
    }
    return self.user;
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

+(void) get:(WGCollectionResultBlock)handler {
    [WGApi get:@"messages/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGMessage" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getConversations:(WGCollectionResultBlock)handler {
    [WGApi get:@"conversations/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGMessage" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

-(void) deleteConversation:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.toUser.id];
    [WGApi delete:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        handler(YES, error);
    }];
    
}

-(void) readConversation:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.toUser.id];
    
    NSDictionary *options = @{ @"read": @YES };
    
    [WGApi post:queryString withParameters:options andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        handler(YES, error);
    }];
}

@end
