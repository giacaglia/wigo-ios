//
//  WGApi.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGApi.h"

#ifdef DEBUG
static NSString *BaseURLString = @"https://dev-api.wigo.us%@";
#else
static NSString *BaseURLString = @"https://api.wigo.us%@";
#endif

@implementation WGApi

+(NSString *) getUrlStringForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:BaseURLString, endpoint];
}

+(void) get:(NSString *)endpoint withHandler:(ApiResult)handler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[self getUrlStringForEndpoint:endpoint] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        handler(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
}

+(void) post:(NSString *)endpoint withParameters:(NSDictionary *)parameters andHandler:(ApiResult)handler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self getUrlStringForEndpoint:endpoint] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        handler(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
}

@end
