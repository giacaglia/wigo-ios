
//
//  AWSUploader.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "AWSUploader.h"
#import "AFNetworking.h"

@implementation AWSUploader

+ (void)uploadFields:(NSArray *)fields
       withActionURL:(NSString *)action
            withFile:(NSData *)fileData
         andFileName:(NSString *)filename
      withCompletion:(void(^)(void))callback {
    NSMutableDictionary *parametersDictionary = [NSMutableDictionary new];
    for (NSDictionary *field in fields) {
        [parametersDictionary setObject:[field objectForKey:@"value"] forKey:[field objectForKey:@"name"]];
    }
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                                                                                              URLString:action
                                                                                             parameters:[NSDictionary dictionaryWithDictionary:parametersDictionary]
                                                                              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                                  [formData appendPartWithFileData:fileData
                                                                                                              name:@"file" //N.B.! To post to S3 name should be "file", not real file name
                                                                                                          fileName:filename
                                                                                                          mimeType:[AWSUploader valueOfFieldWithName:@"Content-Type" ofDictionary:fields]];
                                                                              } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSProgress *progress = nil;
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback();
            });
        }
    }];
    
    [uploadTask resume];
    
}

+ (void)uploadFields:(NSArray *)fields
      withActionURL:(NSString *)action
           withFile:(NSData *)fileData
        andFileName:(NSString *)filename {
    
    NSMutableDictionary *parametersDictionary = [NSMutableDictionary new];
    for (NSDictionary *field in fields) {
        [parametersDictionary setObject:[field objectForKey:@"value"] forKey:[field objectForKey:@"name"]];
    }

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                            URLString:action
                           parameters:[NSDictionary dictionaryWithDictionary:parametersDictionary]
            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:fileData
                                            name:@"file" //N.B.! To post to S3 name should be "file", not real file name
                                        fileName:filename
                                        mimeType:[AWSUploader valueOfFieldWithName:@"Content-Type" ofDictionary:fields]];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSProgress *progress = nil;
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
        }
    }];
    
    [uploadTask resume];
}

+ (NSString *)valueOfFieldWithName:(NSString *)name ofDictionary:(NSArray *)fields {
    NSUInteger index = [fields indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *field = (NSDictionary *)obj;
        if ([[field objectForKey:@"name"] isEqualToString:name]) return YES;
        else return NO;
    }];
    NSDictionary *field = [fields objectAtIndex:index];
    return (NSString *)[field objectForKey:@"value"];
}

@end
