//
//  WGApi.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGApi.h"

#define kWigoApiKey @"oi34u53205ju34ik23"
#define kDeviceType @"iphone"

// #ifdef DEBUG
static NSString *baseURLString = @"https://dev-api.wigo.us/api/%@";
/* #else
static NSString *baseURLString = @"https://api.wigo.us/api/%@";
#endif */

@implementation WGApi

+(NSString *) getUrlStringForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:baseURLString, endpoint];
}

+(void) get:(NSString *)endpoint withHandler:(ApiResult)handler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [WGApi addWigoHeaders:manager.requestSerializer];
    
    [manager GET:[WGApi getUrlStringForEndpoint:endpoint] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        handler(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
}

+(void) post:(NSString *)endpoint withParameters:(NSDictionary *)parameters andHandler:(ApiResult)handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[WGApi getUrlStringForEndpoint:endpoint]]];
    
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters
                                                         options:NSJSONWritingPrettyPrinted
                                                           error:nil]];
    
    unsigned long long postLength = jsonData.length;
    NSString *contentLength = [NSString stringWithFormat:@"%llu", postLength];
    [request addValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    
    [WGApi addWigoHeaders:request];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        handler(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
    
    [operation start];
}

+(void)addWigoHeaders:(id)serializer {
    [serializer setValue:kWigoApiKey forHTTPHeaderField:@"X-Wigo-API-Key"];
#if ENTERPRISE
    [serializer setValue:@"true" forHTTPHeaderField:@"X-Wigo-Client-Enterprise"];
#endif
    
    [serializer setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forHTTPHeaderField:@"X-Wigo-Client-Version"];
    [serializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [serializer setValue:API_VERSION forHTTPHeaderField:@"X-Wigo-API-Version"];
    [serializer setValue:kDeviceType forHTTPHeaderField:@"X-Wigo-Device"];
    [serializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
#warning TODO: find out how to 'actually' get the key
    
    NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:@"key"];
    [serializer setValue:key forHTTPHeaderField:@"X-Wigo-User-Key"];
}

@end
