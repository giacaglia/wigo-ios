//
//  WGFollow.m
//  Wigo
//
//  Created by Adam Eagle on 1/7/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGFollow.h"

#define kUserKey @"user"
#define kFollowKey @"follow"

@implementation WGFollow

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"follow";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"follow";
    }
    return self;
}

+(WGFollow *)serialize:(NSDictionary *)json {
    return [[WGFollow alloc] initWithJSON:json];
}

-(void) setUser:(WGUser *)user {
    [self setObject:[user deserialize] forKey:kUserKey];
}

-(WGUser *) user {
    return [WGUser serialize: [self objectForKey:kUserKey]];
}

-(void) setFollow:(WGUser *)follow {
    [self setObject:[follow deserialize] forKey:kFollowKey];
}

-(WGUser *) follow {
    return [WGUser serialize: [self objectForKey:kFollowKey]];
}

+(void) get:(WGCollectionResultBlock)handler {
    [WGApi get:@"follows" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getFollowsForFollow:(WGUser *)user withHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"follows/" withArguments:@{ @"follow" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }

    }];
}

+(void) searchFollows:(NSString *)query forFollow:(WGUser *)user withHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"follow" : user.id, @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getFollowsForUser:(WGUser *)user withHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"follows/" withArguments:@{ @"user" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) searchFollows:(NSString *)query forUser:(WGUser *)user withHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"user" : user.id, @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

@end