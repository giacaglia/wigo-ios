//
//  Network.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/26/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Network.h"

@implementation Network

#pragma mark - Asynchronous Methods

+ (void)fetchAsynchronousAPI:(NSString *)apiName withResult:(FetchResult)fetchResult {
    [self queryAsynchronousAPI:apiName withHandler: ^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *result = [jsonResponse objectForKey:@"objects"];
        fetchResult(result,error);
    }];
}

+ (void)queryAsynchronousAPI:(NSString *)apiName
         withInputDictionary:(NSDictionary *)inputDictionary
                 withHandler:(QueryResultWithInput)resultWithInput {
    [self queryAsynchronousAPI:apiName withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        resultWithInput(inputDictionary, jsonResponse, error);
    }];
}

+ (void)queryAsynchronousAPI:(NSString *)apiName withHandler:(QueryResult)handler {
    [Network sendAsynchronousHTTPMethod:GET withAPIName:apiName withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(jsonResponse, error);
    }];
}

+ (void)sendAsynchronousHTTPMethod:(NSString *)httpMethod withAPIName:(NSString *)apiName withHandler:(QueryResult)handler {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:apiName];
    [query setProfileKey:[[Profile user] key]];
    [query sendAsynchronousHTTPMethod:(NSString *)httpMethod withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(jsonResponse, error);
    }];
}

+ (void)sendAsynchronousHTTPMethod:(NSString *)httpMethod
                       withAPIName:(NSString *)apiName
                       withHandler:(QueryResult)handler
                       withOptions:(id)options
{
    Query *query = [[Query alloc] init];
    [query queryWithClassName:apiName];
    [query setProfileKey:[[Profile user] key]];
    if ([options isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in [options allKeys]) {
            [query setValue:[options objectForKey:key] forKey:key];
        }
    }
    else if ([options isKindOfClass:[NSArray class]]){
        [query setArray:(NSArray *)options];
    }

    [query sendAsynchronousHTTPMethod:(NSString *)httpMethod withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(jsonResponse, error);
    }];
}


+ (void)sendAsynchronousTapToUserWithIndex:(NSNumber *)indexOfUser {
    Query *query = [[Query alloc] init];
    [query setProfileKey:[[Profile user] key]];
    [query queryWithClassName:@"taps/"];
    [query setValue:indexOfUser forKey:@"tapped"];
    [query sendAsynchronousHTTPMethod:POST withHandler:^(NSDictionary *jsonResponse, NSError *error){}];
}

+ (void)sendUntapToUserWithId:(NSNumber*)idOfUser {
    NSString *queryString = [NSString stringWithFormat:@"users/%@/", [idOfUser stringValue]];
    NSDictionary *options = @{@"is_tapped": @NO};
    [Network sendAsynchronousHTTPMethod:POST
                            withAPIName:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                            withOptions:options];
}


# pragma mark - Synchronous Methods

+ (void)unfollowUser:(User *)user {
    NSString *queryString = [NSString stringWithFormat:@"follows/?user=me&follow=%d", [(NSNumber *)[user objectForKey:@"id"] intValue]];
    [self queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if ([[jsonResponse allKeys] containsObject:@"objects"]) {
            NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
            if ([arrayOfFollowObjects count] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    NSDictionary *followObject = [arrayOfFollowObjects objectAtIndex:0];
                    NSNumber *followObjectNumber = [followObject objectForKey:@"id"];
                    Query *query = [[Query alloc] init];
                    NSString *apiName = [NSString stringWithFormat:@"follows/%d/", [followObjectNumber intValue]];
                    [query queryWithClassName:apiName];
                    [query setProfileKey:[[Profile user] key]];
                    [query sendAsynchronousHTTPMethod:DELETE withHandler:^(NSDictionary *jsonResponse, NSError *error) {}];
                });
            }
        }
    }];
}

+ (void)followUser:(User *)user {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"follows/"];
    [query setProfileKey:[[Profile user] key]];
    [query setValue:[user objectForKey:@"id"] forKey:@"follow"];
    [query sendAsynchronousHTTPMethod:POST withHandler:^(NSDictionary *jsonResponse, NSError *error) {}];

}

+ (void)acceptFollowRequestForUser:(User *)user {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:[NSString stringWithFormat:@"follows/accept?from=%d", [(NSNumber*)[user objectForKey:@"id"] intValue]]];
    [query setProfileKey:[[Profile user] key]];
    [query sendAsynchronousHTTPMethod:GET withHandler:^(NSDictionary *jsonResponse, NSError *error) {}];
}

+ (void)rejectFollowRequestForUser:(User *)user {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:[NSString stringWithFormat:@"follows/reject?from=%d", [(NSNumber*)[user objectForKey:@"id"] intValue]]];
    [query setProfileKey:[[Profile user] key]];
    [query sendAsynchronousHTTPMethod:GET withHandler:^(NSDictionary *jsonResponse, NSError *error) {}];
}



+ (void)sendTapToUserWithIndex:(NSNumber *)indexOfUser {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"taps/"];
    [query setProfileKey:[[Profile user] key]];
    [query setValue:indexOfUser forKey:@"tapped"];
    [query sendAsynchronousHTTPMethod:POST withHandler:^(NSDictionary *jsonResponse, NSError *error) {}];
}

+ (void)postGoOut {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"goingouts/"];
    [query setProfileKey:[[Profile user] key]];
    [query sendPOSTRequest];
}

+ (void) postGoingToEventNumber:(int)indexOfObject {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"eventattendees/"];
    [query setProfileKey:[[Profile user] key]];
    [query setValue:[NSNumber numberWithInt:indexOfObject] forKey:@"event"];
    [query sendPOSTRequest];
}

+ (NSNumber *)createEventWithName:(NSString *)nameString {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"events/"];
    [query setProfileKey:[[Profile user] key]];
    [query setValue:nameString forKey:@"name"];
    NSDictionary *result = [query sendPOSTRequest];
    return (NSNumber *)[result objectForKey:@"id"];
}

+ (NSArray *)queryWithAPI:(NSString *)apiName {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:apiName];
    [query setProfileKey:[[Profile user] key]];
    NSDictionary *result = [query sendGETRequest];
    return [result objectForKey:@"objects"];
}


@end
