//
//  Query.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/17/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Query.h"

static NSString * const BaseURLString = @"https://api.wigo.us%@";

@interface Query ()
@property NSString *urlSuffix;
@property NSMutableDictionary *options;
@property NSString *key;


@end


@implementation Query

- (id) init {
    if (self = [super init]) {
        _options = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setProfileKey:(NSString *)key {
    _key = key;
}

- (void)queryWithClassName:(NSString *)className {
    _urlSuffix = [NSString stringWithFormat:@"/api/%@", className];
}

- (void)setValue:(id)value forKey:(NSString *)key  {
    [_options setValue:value forKey:key];
}

#pragma mark - Synchronous Calls

- (NSDictionary *)sendGETRequest {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_options options:NSJSONWritingPrettyPrinted error:nil];
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:BaseURLString, _urlSuffix]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:@"oi34u53205ju34ik23" forHTTPHeaderField:@"X-Wigo-API-Key"];
    [req setValue:_key forHTTPHeaderField:@"X-Wigo-User-Key"];
    [req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPMethod:@"GET"];
    if ([_options count] != 0) {
        [req setHTTPBody:jsonData];
    }
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return json;
}

- (NSDictionary *)sendPOSTRequest {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_options options:NSJSONWritingPrettyPrinted error:nil];
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:BaseURLString, _urlSuffix]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:@"oi34u53205ju34ik23" forHTTPHeaderField:@"X-Wigo-API-Key"];
    if (_key) {
        [req setValue:_key forHTTPHeaderField:@"X-Wigo-User-Key"];
    }
    [req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:jsonData];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    if (!data) {
        return nil;
    }
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return json;
}

- (NSDictionary *)sendDELETERequest {
//    NSLog(@"options %@", _options);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_options options:NSJSONWritingPrettyPrinted error:nil];
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:BaseURLString, _urlSuffix]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:@"oi34u53205ju34ik23" forHTTPHeaderField:@"X-Wigo-API-Key"];
    if (_key) {
        [req setValue:_key forHTTPHeaderField:@"X-Wigo-User-Key"];
    }
    [req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPMethod:@"DELETE"];
    [req setHTTPBody:jsonData];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return json;
}

#pragma mark - Asynchronous calls

- (void)sendAsynchronousGETRequestHandler:(QueryResult)handler {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_options options:NSJSONWritingPrettyPrinted error:nil];
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:BaseURLString, _urlSuffix]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:@"oi34u53205ju34ik23" forHTTPHeaderField:@"X-Wigo-API-Key"];
    [req setValue:_key forHTTPHeaderField:@"X-Wigo-User-Key"];
    [req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPMethod:@"GET"];
    if ([_options count] != 0) {
        [req setHTTPBody:jsonData];
    }
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init]  completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSDictionary* json;
        if (data) {
            json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        }
        handler(json, error);
    }];
}


@end
