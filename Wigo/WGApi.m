//
//  WGApi.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

dispatch_queue_t postQueue;

#import "WGApi.h"
#import "WGProfile.h"
#import <dispatch/dispatch.h>
#import <CoreLocation/CoreLocation.h>

#define kWigoApiKeyKey @"X-Wigo-API-Key"
#define kWigoClientEnterpriseKey @"X-Wigo-Client-Enterprise"
#define kWigoClientVersionKey @"X-Wigo-Client-Version"
#define kWigoApiVersionKey @"X-Wigo-API-Version"
#define kWigoDeviceKey @"X-Wigo-Device"
#define kWigoUserKey @"X-Wigo-User-Key"
#define kPeekGroupKey @"X-Wigo-Group-ID"
#define kGeoLocationKey @"Geolocation"

#define kContentLengthKey @"Content-Length"
#define kContentTypeKey @"Content-Type"
#define kAcceptEncodingKey @"Accept-Encoding"

#define kWigoApiKey @"oi34u53205ju34ik23"
#define kDeviceType @"iphone"
#define kWigoApiVersion @"2.0.0"
#define kGZip @"gzip"
#define kTrue @"true"
#define kPOST @"POST"
#define kDELETE @"DELETE"
#define kContentType @"application/json; charset=utf-8"

#define kVideoKey @"video"
#define kFieldsKey @"fields"
#define kValueKey @"value"
#define kNameKey @"name"
#define kActionKey @"action"
#define kFileKey @"file"
#define kReferenceIdKey @"$id"
#define kReferenceKey @"$ref"

static NSString *baseURLString = @"https://api2.wigo.us/api/%@";
static CLLocationManager *locationManager;
#import "LocationPrimer.h"

@implementation WGApi

+ (CLLocationManager *)defaultLocationManager {
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = 10;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        [locationManager startUpdatingLocation];
    }
    return locationManager;
  
}

+(void) get:(NSString *)endpoint withSerializedHandler:(SerializedApiResultBlock)handler {
    [WGApi getURL:[WGApi getUrlStringForEndpoint:endpoint] withSerializedHandler:handler];
}

+(void) get:(NSString *)endpoint withArguments:(NSDictionary *)arguments andSerializedHandler:(SerializedApiResultBlock)handler {
    NSString *fullEndpoint = [WGApi getStringWithEndpoint:endpoint andArguments:arguments];
    [WGApi getURL:[WGApi getUrlStringForEndpoint:fullEndpoint] withSerializedHandler:handler];
}


+(void) getURL:(NSString *)url withSerializedHandler:(SerializedApiResultBlock)handler {
    NSLog(@"GET %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];
    // Hack for Ambassador View
    BOOL shouldPassKey = [url rangeOfString:@"key="].location != NSNotFound;
    
    [WGApi addWigoHeaders:manager.requestSerializer passKey:shouldPassKey];
    
    if (!postQueue) {
        postQueue = dispatch_queue_create("com.whoisgoingout.wigo.postqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    dispatch_async(postQueue, ^(void) {
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(operation.response.URL, response, dataError);
                });
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(operation.response.URL, operation.responseObject, error);
            });
        }];
    });
}


+(void) get:(NSString *)endpoint withHandler:(ApiResultBlock)handler {
    [WGApi getURL:[WGApi getUrlStringForEndpoint:endpoint] withHandler:handler];
}

+(void) get:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResultBlock)handler {
    NSString *fullEndpoint = [WGApi getStringWithEndpoint:endpoint andArguments:arguments];
    [WGApi getURL:[WGApi getUrlStringForEndpoint:fullEndpoint] withHandler:handler];
}



+(void) getURL:(NSString *)url withHandler:(ApiResultBlock)handler {
    NSLog(@"GET %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];

    // Hack for Ambassador View
    BOOL shouldPassKey = [url rangeOfString:@"key="].location != NSNotFound;
    [WGApi addWigoHeaders:manager.requestSerializer passKey:shouldPassKey];
    
    if (!postQueue) {
        postQueue = dispatch_queue_create("com.whoisgoingout.wigo.postqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    dispatch_async(postQueue, ^(void) {
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(response, dataError);
                });
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(operation.responseObject, error);
            });
        }];
    });
}

+(void) delete:(NSString *)endpoint withHandler:(ApiResultBlock)handler {
    [WGApi deleteURL:[WGApi getUrlStringForEndpoint:endpoint]
      withParameters:nil
          andHandler:handler];
}

+(void) delete:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResultBlock)handler {
    NSString *fullEndpoint = [WGApi getStringWithEndpoint:endpoint andArguments:arguments];
    [WGApi deleteURL:[WGApi getUrlStringForEndpoint:fullEndpoint]
      withParameters:nil
          andHandler:handler];
}

+(void) delete:(NSString *)endpoint
withParameters:(id)parameters
    andHandler:(ApiResultBlock)handler {
    [WGApi deleteURL:[WGApi getUrlStringForEndpoint:endpoint]
     withParameters:parameters
         andHandler:handler];
}

+(void) deleteURL:(NSString *)url
   withParameters:(id)parameters
       andHandler:(ApiResultBlock)handler {
    NSLog(@"DELETE %@, %@", url, parameters);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    if (parameters) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        [request setHTTPBody:jsonData];
        NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long) jsonData.length];
        [request addValue:contentLength forHTTPHeaderField:kContentLengthKey];
    }
    
    BOOL shouldPassKey = [url rangeOfString:@"key="].location != NSNotFound;
    [WGApi addWigoHeaders:request passKey:shouldPassKey];

   
    [request setHTTPMethod:kDELETE];

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
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(response, dataError);
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(operation.responseObject, error);
        });
    }];
    
    if (!postQueue) {
        postQueue = dispatch_queue_create("com.whoisgoingout.wigo.postqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    dispatch_barrier_async(postQueue, ^(void) {
        [operation start];
    });
}

+(void) post:(NSString *)endpoint withParameters:(id)parameters andHandler:(ApiResultBlock)handler {
    [WGApi postURL:[WGApi getUrlStringForEndpoint:endpoint] withParameters:parameters andHandler:handler];
}

+(void) post:(NSString *)endpoint withHandler:(ApiResultBlock)handler {
    [WGApi postURL:[WGApi getUrlStringForEndpoint:endpoint] withParameters:@{} andHandler:handler];
}

+(void) post:(NSString *)endpoint withArguments:(NSDictionary *)arguments andParameters:(id)parameters andHandler:(ApiResultBlock)handler {
    NSString *fullEndpoint = [WGApi getStringWithEndpoint:endpoint andArguments:arguments];
    [WGApi postURL:[WGApi getUrlStringForEndpoint:fullEndpoint] withParameters:parameters andHandler:handler];
}

+(void) postURL:(NSString *)url withParameters:(id)parameters andHandler:(ApiResultBlock)handler {
    NSLog(@"POST %@, %@", url, parameters);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    [request setHTTPBody:jsonData];
    NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long) jsonData.length];
    [request addValue:contentLength forHTTPHeaderField:kContentLengthKey];
    [request setHTTPMethod:kPOST];
    
    BOOL shouldPassKey = [url rangeOfString:@"key="].location != NSNotFound;

    [WGApi addWigoHeaders:request passKey:shouldPassKey];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];
    
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
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                handler(response, dataError);
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            handler(operation.responseObject, error);
        });
    }];
    
    if (!postQueue) {
        postQueue = dispatch_queue_create("com.whoisgoingout.wigo.postqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    dispatch_barrier_async(postQueue, ^(void) {
        [operation start];
    });
}

+(NSString *) getUrlStringForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:baseURLString, endpoint];
}

+ (void) setBaseURLString:(NSString *)newBaseURLString {
    baseURLString = newBaseURLString;
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

+(void)addWigoHeaders:(id)serializer passKey:(BOOL) shouldPassKey {
#if ENTERPRISE
    [serializer setValue:kTrue forHTTPHeaderField:kWigoClientEnterpriseKey];
#endif
    [serializer setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forHTTPHeaderField:kWigoClientVersionKey];
    [serializer setValue:kGZip forHTTPHeaderField:kAcceptEncodingKey];
    [serializer setValue:kWigoApiVersion forHTTPHeaderField:kWigoApiVersionKey];
    [serializer setValue:kDeviceType forHTTPHeaderField:kWigoDeviceKey];
    [serializer setValue:kContentType forHTTPHeaderField:kContentTypeKey];
    if (WGProfile.peekingGroupID) [serializer setValue:WGProfile.peekingGroupID.stringValue forHTTPHeaderField:kPeekGroupKey];
    if ([LocationPrimer shouldFetchEvents]) [serializer setValue:WGApi.getGeoVal forHTTPHeaderField:kGeoLocationKey];
    if (!shouldPassKey) {
        [serializer setValue:kWigoApiKey forHTTPHeaderField:kWigoApiKeyKey];
        [serializer setValue:WGProfile.currentUser.key forHTTPHeaderField:kWigoUserKey];
    }
}

+ (NSString *)getGeoVal {
    return [NSString stringWithFormat:@"geo: %f,%f", WGApi.defaultLocationManager.location.coordinate.latitude, WGApi.defaultLocationManager.location.coordinate.longitude];
}

#pragma mark AWS Uploader

+(void) uploadPhoto:(NSData *)fileData withFileName:(NSString *)fileName andHandler:(UploadResultBlock) handler {
    [WGApi get:[NSString stringWithFormat: @"uploads/photos/?filename=%@", fileName] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(jsonResponse, nil, error);
            return;
        }
        
        NSError *dataError = nil;
        NSString *action;
        NSMutableDictionary *fields;
        @try {
            action = [jsonResponse objectForKey:kActionKey];
            
            fields = [[NSMutableDictionary alloc] init];
            for (NSDictionary *field in (NSArray *)[jsonResponse objectForKey:kFieldsKey]) {
                [fields setObject:[field objectForKey:kValueKey] forKey:[field objectForKey:kNameKey]];
            }
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
             
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            if (dataError) {
                handler(jsonResponse, fields, dataError);
                return;
            }
            [WGApi upload:action fields:fields file:fileData fileName:fileName andHandler:^(NSDictionary *jsonResponse, NSError *error) {
                handler(jsonResponse, fields, error);
            }];
        }
    }];
}

+(void) uploadVideo:(NSData *)fileData withFileName:(NSString *)fileName stillImageData:(NSData *)stillImageData stillImageName:(NSString *)stillImageName andHandler:(UploadVideoResultBlock) handler {
    [WGApi get:[NSString stringWithFormat: @"uploads/videos/?filename=%@", fileName] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(jsonResponse, nil, nil, nil, error);
            return;
        }
        
        NSError *dataError = nil;
        NSString *videoAction;
        NSString *stillImageAction;
        NSMutableDictionary *videoFields;
        NSMutableDictionary *stillImageFields;
        NSDictionary *videoDictionary;
        NSDictionary *stillImageDictionary;
        @try {
            videoDictionary = [jsonResponse objectForKey:kVideoKey];
            stillImageDictionary = [jsonResponse objectForKey:@"image"];
            
            videoAction = [videoDictionary objectForKey:kActionKey];
            videoFields = [[NSMutableDictionary alloc] init];
            for (NSDictionary *field in [videoDictionary objectForKey:kFieldsKey]) {
                [videoFields setObject:[field objectForKey:kValueKey] forKey:[field objectForKey:kNameKey]];
            }
            
            stillImageAction = [stillImageDictionary objectForKey:kActionKey];
            stillImageFields = [[NSMutableDictionary alloc] init];
            for (NSDictionary *field in [stillImageDictionary objectForKey:kFieldsKey]) {
                [stillImageFields setObject:[field objectForKey:kValueKey] forKey:[field objectForKey:kNameKey]];
            }
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            if (dataError) {
                handler(jsonResponse, nil, videoFields, stillImageFields, dataError);
                return;
            }
            [WGApi upload:videoAction fields:videoFields file:fileData fileName:fileName andHandler:^(NSDictionary *jsonResponse, NSError *error) {
                if (error) {
                    handler(jsonResponse, nil, videoFields, stillImageFields, error);
                    return;
                }
                [WGApi upload:stillImageAction fields:stillImageFields file:stillImageData fileName:stillImageName andHandler:^(NSDictionary *jsonResponse2, NSError *error) {
                    handler(jsonResponse, jsonResponse2, videoFields, stillImageFields, error);
                }];
            }];
        }
    }];
}

+(void) upload:(NSString *)url fields:(NSDictionary *)fields file:(NSData *)fileData fileName:(NSString *)filename andHandler:(ApiResultBlock)handler {
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:kPOST  URLString:[NSString stringWithString: url] parameters:fields constructingBodyWithBlock:^(id<AFMultipartFormData> formData) { [formData appendPartWithFileData:fileData name:kFileKey fileName:filename mimeType:[fields objectForKey:kContentTypeKey]];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        handler(responseObject, error);
    }];
    
    [uploadTask resume];
}

+(void) startup:(WGStartupResult)handler {
    [WGApi get:@"app/startup" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, nil, nil, nil, NO, NO, nil, error);
            return;
        }
        NSString *cdnPrefix;
        NSNumber *googleAnalyticsEnabled;
        NSNumber *schoolStatistics;
        NSNumber *privateEvents;
        BOOL videoEnabled;
        BOOL crossEventPhotosEnabled;
        NSError *dataError;
        NSDictionary *imageProperties;
        @try {
            NSDictionary *cdn = [jsonResponse objectForKey:@"cdn"];
            cdnPrefix = [cdn objectForKey:@"uploads"];
            
            NSDictionary *analytics = [jsonResponse objectForKey:@"analytics"];
            googleAnalyticsEnabled = [analytics objectForKey:@"gAnalytics"];
            
            NSDictionary *provisioning = [jsonResponse objectForKey:@"provisioning"];
            schoolStatistics = [provisioning objectForKey:@"school_statistics"];
            privateEvents = [provisioning objectForKey:@"private_events"];
            videoEnabled = [[provisioning objectForKey:@"video"] boolValue];
            crossEventPhotosEnabled = [[provisioning objectForKey:@"cross_event_messages"] boolValue];
            
            NSDictionary *uploadsProperties = [jsonResponse objectForKey:@"uploads"];
            imageProperties = [uploadsProperties objectForKey:@"image"];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            if (dataError) {
                handler(cdnPrefix, googleAnalyticsEnabled, schoolStatistics, privateEvents, videoEnabled, crossEventPhotosEnabled,  imageProperties, dataError);
                return;
            }
            handler(cdnPrefix, googleAnalyticsEnabled, schoolStatistics, privateEvents, videoEnabled, crossEventPhotosEnabled, imageProperties, dataError);
        }
    }];
}

@end
