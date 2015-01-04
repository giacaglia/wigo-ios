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
static NSString *baseURLString = @"https://api.wigo.us/api/%@";
/* #else
static NSString *baseURLString = @"https://api.wigo.us/api/%@";
#endif */

@implementation WGApi

#warning TODO: write wrapper for NSError

+(void) get:(NSString *)endpoint withHandler:(ApiResult)handler {
    [WGApi getURL:[WGApi getUrlStringForEndpoint:endpoint] withHandler:handler];
}

+(void) getURL:(NSString *)url withHandler:(ApiResult)handler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [WGApi addWigoHeaders:manager.requestSerializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WGParser *parser = [[WGParser alloc] init];
        handler([parser replaceReferences:responseObject], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
}

+(void) delete:(NSString *)endpoint withHandler:(ApiResult)handler {
    [WGApi deleteURL:[WGApi getUrlStringForEndpoint:endpoint] withHandler:handler];
}

+(void) deleteURL:(NSString *)url withHandler:(ApiResult)handler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [WGApi addWigoHeaders:manager.requestSerializer];
    
    [manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WGParser *parser = [[WGParser alloc] init];
        handler([parser replaceReferences:responseObject], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
}

+(void) post:(NSString *)endpoint withParameters:(id)parameters andHandler:(ApiResult)handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[WGApi getUrlStringForEndpoint:endpoint]]];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    [request setHTTPBody:jsonData];
    unsigned long long postLength = jsonData.length;
    NSString *contentLength = [NSString stringWithFormat:@"%llu", postLength];
    [request addValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    
    [WGApi addWigoHeaders:request];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        WGParser *parser = [[WGParser alloc] init];
        handler([parser replaceReferences:responseObject], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
    
    [operation start];
}

+(NSString *) getUrlStringForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:baseURLString, endpoint];
}

+(void)addWigoHeaders:(id)serializer {
    [serializer setValue:kWigoApiKey forHTTPHeaderField:@"X-Wigo-API-Key"];
#if ENTERPRISE
    [serializer setValue:@"true" forHTTPHeaderField:@"X-Wigo-Client-Enterprise"];
#endif
    [serializer setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forHTTPHeaderField:@"X-Wigo-Client-Version"];
    [serializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [serializer setValue:@"1.0.7 (enable_refs)" forHTTPHeaderField:@"X-Wigo-API-Version"];
    [serializer setValue:kDeviceType forHTTPHeaderField:@"X-Wigo-Device"];
    [serializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

#warning TODO: find out how to 'actually' get the key
    
    NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:@"key"];
    [serializer setValue:key forHTTPHeaderField:@"X-Wigo-User-Key"];
}

#pragma mark AWS Uploader

+(void) upload:(NSString *)url fields:(NSDictionary *)fields file:(NSData *)fileData fileName:(NSString *)filename andHandler:(ApiResult)handler {
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:url parameters:fields constructingBodyWithBlock:^(id<AFMultipartFormData> formData) { [formData appendPartWithFileData:fileData name:@"file" fileName:filename mimeType:[fields objectForKey:@"Content-Type"]];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        handler(responseObject, error);
    }];
    
    [uploadTask resume];
    
}

@end
