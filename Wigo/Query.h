//
//  Query.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/17/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

#define POST @"POST"
#define GET @"GET"
#define DELETE @"DELETE"


typedef void (^QueryResult)(NSDictionary *jsonResponse, NSError *error);
typedef void (^QueryResultWithInput)(NSDictionary *input, NSDictionary *jsonResponse, NSError *error);


@interface Query : NSObject

@property NSDictionary *users;


// Settings
- (void)queryWithClassName:(NSString *)className;
- (void)setValue:(id)value forKey:(NSString *)key;
- (void)setProfileKey:(NSString *)key;

- (NSDictionary *)sendGETRequest;
- (NSDictionary *)sendPOSTRequest;
- (NSDictionary *)sendDELETERequest;

- (void) sendAsynchronousHTTPMethod:(NSString *)httpMethod withHandler:(QueryResult)handler;
- (void)sendAsynchronousGETRequestHandler:(QueryResult) handler;

@end