//
//  Query.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/17/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
//#import "AFNetworking.h"
//#import "Profile.h"

typedef void (^QueryResult)(NSDictionary *jsonResponse, NSError *error);

@interface Query : NSObject

@property NSDictionary *users;


// Settings
- (void)queryWithClassName:(NSString *)className;
- (void)setValue:(id)value forKey:(NSString *)key;
- (void)setProfileKey:(NSString *)key;

// Get Object
- (NSDictionary *)sendGETRequest;
- (NSDictionary *)sendPOSTRequest;
- (void)sendAsynchronousGETRequestHandler:(QueryResult) handler;

@end