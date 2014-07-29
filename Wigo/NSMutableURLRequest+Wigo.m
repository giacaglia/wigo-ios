//
//  NSMutableURLRequest+Wigo.m
//  Wigo
//
//  Created by Dennis Doughty on 7/17/14.
//  Copyright (c) 2014 Dennis Doughty. All rights reserved.
//

#import "NSMutableURLRequest+Wigo.h"
#define WIGO_API_KEY @"oi34u53205ju34ik23"

@implementation NSMutableURLRequest (Wigo)

- (void)setWigoHeadersAndUserKey:(NSString *)userKey {
    [self setValue:WIGO_API_KEY forHTTPHeaderField:@"X-Wigo-API-Key"];
    if (userKey) {
        [self setValue:userKey forHTTPHeaderField:@"X-Wigo-User-Key"];
    }
#if ENTERPRISE
    [self setValue:@"true" forHTTPHeaderField:@"X-Wigo-Client-Enterprise"];
#endif
    [self setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forHTTPHeaderField:@"X-Wigo-Client-Version"];
    [self setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
}

@end
