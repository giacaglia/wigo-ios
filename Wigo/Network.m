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

+ (void)queryAsynchronousAPI:(NSString *)apiName withInputDictionary:(NSDictionary *)inputDictionary withHandler:(QueryResultWithInput)resultWithInput {
    [self queryAsynchronousAPI:apiName withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        resultWithInput(inputDictionary, jsonResponse, error);
    }];
}

+ (void)queryAsynchronousAPI:(NSString *)apiName withHandler:(QueryResult)handler {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:apiName];
    User *user = [Profile user];
    [query setProfileKey:user.key];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [query sendAsynchronousGETRequestHandler:^(NSDictionary *jsonResponse, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        handler(jsonResponse, error);
    }];
}

# pragma mark - Synchronous Methods

+ (void)unfollowUser:(User *)user {
    NSString *queryString = [NSString stringWithFormat:@"follows/?follow=%d", [(NSNumber *)[user objectForKey:@"id"] intValue]];
    [self queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if ([[jsonResponse allKeys] containsObject:@"objects"]) {
            NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
            if ([arrayOfFollowObjects count] > 0) {
                NSDictionary *followObject = [arrayOfFollowObjects objectAtIndex:0];
                NSNumber *followObjectNumber = [followObject objectForKey:@"id"];
                Query *query = [[Query alloc] init];
                NSString *apiName = [NSString stringWithFormat:@"follows/%d", [followObjectNumber intValue]];
                [query queryWithClassName:apiName];
                User *profileUser = [Profile user];
                [query setProfileKey:profileUser.key];
                [query sendDELETERequest];
            }
        }
    }];
}

+ (void)followUser:(User *)user {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"follows/"];
    User *profileUser = [Profile user];
    [query setProfileKey:profileUser.key];
    [query setValue:[user objectForKey:@"id"] forKey:@"follow"];
    NSDictionary *result = [query sendPOSTRequest];
}

+ (void)sendTapToUserWithIndex:(NSNumber *)indexOfUser {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"taps/"];
    User *user = [Profile user];
    [query setProfileKey:user.key];
    [query setValue:indexOfUser forKey:@"tapped"];
    NSDictionary *result = [query sendPOSTRequest];
}

+ (void)postGoOut {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"goingouts/"];
    User *user = [Profile user];
    [query setProfileKey:user.key];
    [query sendPOSTRequest];
}

+ (void) postGoingToEventNumber:(int)indexOfObject {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"eventattendees/"];
    User *user = [Profile user];
    [query setProfileKey:user.key];
    [query setValue:[NSNumber numberWithInt:indexOfObject] forKey:@"event"];
    [query sendPOSTRequest];
}

+ (NSNumber *)createEventWithName:(NSString *)nameString {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"events/"];
    User *user = [Profile user];
    [query setProfileKey:user.key];
    [query setValue:nameString forKey:@"name"];
    NSDictionary *result = [query sendPOSTRequest];
    return (NSNumber *)[result objectForKey:@"id"];
}

+ (NSArray *)queryWithAPI:(NSString *)apiName {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:apiName];
    User *user = [Profile user];
    [query setProfileKey:user.key];
    NSDictionary *result = [query sendGETRequest];
    return [result objectForKey:@"objects"];
}


@end
