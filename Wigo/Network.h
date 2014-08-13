//
//  Network.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/26/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Query.h"
#import "User.h"
#import "Profile.h"

typedef void (^FetchResult)(NSArray *arrayResponse, NSError *error);

@interface Network : NSObject

+ (void)fetchAsynchronousAPI:(NSString *)apiName withResult:(FetchResult)fetchResult;
+ (void)queryAsynchronousAPI:(NSString *)apiName withInputDictionary:(NSDictionary *)inputDictionary withHandler:(QueryResultWithInput)resultWithInput;
+ (void)queryAsynchronousAPI:(NSString *)apiName withHandler:(QueryResult)handler;
+ (void)sendAsynchronousHTTPMethod:(NSString *)httpMethod withAPIName:(NSString *)apiName withHandler:(QueryResult)handler;
+ (void)sendAsynchronousHTTPMethod:(NSString *)httpMethod
                       withAPIName:(NSString *)apiName
                       withHandler:(QueryResult)handler
                       withOptions:(NSDictionary *)options;
+ (void)sendAsynchronousTapToUserWithIndex:(NSNumber *)indexOfUser;

// Synchronous methods
+ (void)unfollowUser:(User *)user;
+ (void)followUser:(User *)user;
+ (void)acceptFollowRequestForUser:(User *)user;
+ (void)rejectFollowRequestForUser:(User *)user;
+ (void)sendTapToUserWithIndex:(NSNumber *)indexOfUser;
+ (void)sendUntapToUserWithId:(NSNumber*)idOfUser;
+ (void)postGoOut;
+ (void) postGoingToEventNumber:(int)indexOfObject;
+ (NSNumber *)createEventWithName:(NSString *)nameString;
+ (NSArray *)queryWithAPI:(NSString *)apiName;

@end
