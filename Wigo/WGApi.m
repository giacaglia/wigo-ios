//
//  WGApi.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGApi.h"
#import "WGProfile.h"

#define kWigoApiKeyKey @"X-Wigo-API-Key"
#define kWigoClientEnterpriseKey @"X-Wigo-Client-Enterprise"
#define kWigoClientVersionKey @"X-Wigo-Client-Version"
#define kWigoApiVersionKey @"X-Wigo-API-Version"
#define kWigoDeviceKey @"X-Wigo-Device"
#define kWigoUserKey @"X-Wigo-User-Key"

#define kContentLengthKey @"Content-Length"
#define kContentTypeKey @"Content-Type"
#define kAcceptEncodingKey @"Accept-Encoding"

#define kWigoApiKey @"oi34u53205ju34ik23"
#define kDeviceType @"iphone"
#define kWigoApiVersion @"1.0.7 (enable_refs)"
#define kGZip @"gzip"
#define kTrue @"true"
#define kPOST @"POST"
#define kContentType @"application/json; charset=utf-8"

#define kVideoKey @"video"
#define kFieldsKey @"fields"
#define kValueKey @"value"
#define kNameKey @"name"
#define kActionKey @"action"
#define kFileKey @"file"

// #ifdef DEBUG
static NSString *baseURLString = @"https://api.wigo.us/api/%@";
/* #else
static NSString *baseURLString = @"https://api.wigo.us/api/%@";
#endif */

@implementation WGApi

+(void) get:(NSString *)endpoint withHandler:(ApiResult)handler {
    [WGApi getURL:[WGApi getUrlStringForEndpoint:endpoint] withHandler:handler];
}

+(void) get:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResult)handler {
    NSString *fullEndpoint = [WGApi getStringWithEndpoint:endpoint andArguments:arguments];
    [WGApi getURL:[WGApi getUrlStringForEndpoint:fullEndpoint] withHandler:handler];
}

+(void) getURL:(NSString *)url withHandler:(ApiResult)handler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [WGApi addWigoHeaders:manager.requestSerializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *dataError;
        NSDictionary *response;
        @try {
            WGParser *parser = [[WGParser alloc] init];
            response = [parser replaceReferences:responseObject];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(response, dataError);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
}

+(void) delete:(NSString *)endpoint withHandler:(ApiResult)handler {
    [WGApi deleteURL:[WGApi getUrlStringForEndpoint:endpoint] withHandler:handler];
}

+(void) delete:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResult)handler {
    NSString *fullEndpoint = [WGApi getStringWithEndpoint:endpoint andArguments:arguments];
    [WGApi deleteURL:[WGApi getUrlStringForEndpoint:fullEndpoint] withHandler:handler];
}

+(void) deleteURL:(NSString *)url withHandler:(ApiResult)handler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [WGApi addWigoHeaders:manager.requestSerializer];
    
    [manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *dataError;
        NSDictionary *response;
        @try {
            WGParser *parser = [[WGParser alloc] init];
            response = [parser replaceReferences:responseObject];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(response, dataError);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
}

+(void) post:(NSString *)endpoint withParameters:(id)parameters andHandler:(ApiResult)handler {
    [WGApi postURL:[WGApi getUrlStringForEndpoint:endpoint] withParameters:parameters andHandler:handler];
}

+(void) post:(NSString *)endpoint withHandler:(ApiResult)handler {
    [WGApi postURL:[WGApi getUrlStringForEndpoint:endpoint] withParameters:@{} andHandler:handler];
}

+(void) post:(NSString *)endpoint withArguments:(NSDictionary *)arguments andParameters:(id)parameters andHandler:(ApiResult)handler {
    NSString *fullEndpoint = [WGApi getStringWithEndpoint:endpoint andArguments:arguments];
    [WGApi postURL:[WGApi getUrlStringForEndpoint:fullEndpoint] withParameters:parameters andHandler:handler];
}

+(void) postURL:(NSString *)url withParameters:(id)parameters andHandler:(ApiResult)handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    [request setHTTPBody:jsonData];
    NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long) jsonData.length];
    [request addValue:contentLength forHTTPHeaderField:kContentLengthKey];
    [request setHTTPMethod:kPOST];
    
    [WGApi addWigoHeaders:request];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *dataError;
        NSDictionary *response;
        @try {
            WGParser *parser = [[WGParser alloc] init];
            response = [parser replaceReferences:responseObject];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(response, dataError);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];
    
    [operation start];
}

+(NSString *) getUrlStringForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:baseURLString, endpoint];
}

+(NSString *) getStringWithEndpoint:(NSString *)endpoint andArguments:(NSDictionary *)arguments {
    NSString *fullEndpoint = [NSString stringWithString:endpoint];
    BOOL first = YES;
    for (NSString *key in [arguments allKeys]) {
        id value = [arguments objectForKey:key];
        if (first) {
            fullEndpoint = [fullEndpoint stringByAppendingString:[NSString stringWithFormat:@"?%@=%@", key, value]];
            first = NO;
        } else {
            fullEndpoint = [fullEndpoint stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", key, value]];
        }
    }
    return fullEndpoint;
}

+(void)addWigoHeaders:(id)serializer {
    [serializer setValue:kWigoApiKey forHTTPHeaderField:kWigoApiKeyKey];
#if ENTERPRISE
    [serializer setValue:kTrue forHTTPHeaderField:kWigoClientEnterpriseKey];
#endif
    [serializer setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forHTTPHeaderField:kWigoClientVersionKey];
    [serializer setValue:kGZip forHTTPHeaderField:kAcceptEncodingKey];
    [serializer setValue:kWigoApiVersion forHTTPHeaderField:kWigoApiVersionKey];
    [serializer setValue:kDeviceType forHTTPHeaderField:kWigoDeviceKey];
    [serializer setValue:kContentType forHTTPHeaderField:kContentTypeKey];
    [serializer setValue:[WGProfile currentUser].key forHTTPHeaderField:kWigoUserKey];
}

#pragma mark AWS Uploader

+(void) uploadPhoto:(NSData *)fileData withFileName:(NSString *)fileName andHandler:(ApiResult) handler {
    [WGApi get:[NSString stringWithFormat: @"uploads/photos/?filename=%@", fileName] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError = nil;
        NSString *action;
        NSMutableDictionary *fields;
        @try {
            fields = [[NSMutableDictionary alloc] init];
            for (NSDictionary *field in [jsonResponse objectForKey:kFieldsKey]) {
                [fields setObject:[field objectForKey:kValueKey] forKey:[field objectForKey:kNameKey]];
            }
            action = [fields objectForKey:kActionKey];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
             
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            if (!action) {
                handler(nil, dataError);
                return;
            }
            [WGApi upload:action fields:fields file:fileData fileName:fileName andHandler:^(NSDictionary *jsonResponse, NSError *error) {
                handler(jsonResponse, error);
            }];
        }
    }];
}

+(void) uploadVideo:(NSData *)fileData withFileName:(NSString *)fileName andHandler:(ApiResult) handler {
    [WGApi get:[NSString stringWithFormat: @"uploads/videos/?filename=%@", fileName] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError = nil;
        NSDictionary *video;
        NSString *action;
        NSMutableDictionary *fields;
        @try {
            video = [jsonResponse objectForKey:kVideoKey];
            
            fields = [[NSMutableDictionary alloc] init];
            for (NSDictionary *field in [video objectForKey:kFieldsKey]) {
                [fields setObject:[field objectForKey:kValueKey] forKey:[field objectForKey:kNameKey]];
            }
            action = [video objectForKey:kActionKey];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            if (!action) {
                handler(nil, dataError);
                return;
            }
            [WGApi upload:action fields:fields file:fileData fileName:fileName andHandler:^(NSDictionary *jsonResponse, NSError *error) {
                handler(jsonResponse, error);
            }];
        }
    }];
}

+(void) upload:(NSString *)url fields:(NSDictionary *)fields file:(NSData *)fileData fileName:(NSString *)filename andHandler:(ApiResult)handler {
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:kPOST  URLString:url parameters:fields constructingBodyWithBlock:^(id<AFMultipartFormData> formData) { [formData appendPartWithFileData:fileData name:kFileKey fileName:filename mimeType:[fields objectForKey:kContentTypeKey]];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        handler(responseObject, error);
    }];
    
    [uploadTask resume];
}

@end
