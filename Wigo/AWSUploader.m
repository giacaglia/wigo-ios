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

+ (void) uploadImage:(NSData *)image {
//    [Network sendAsynchronousHTTPMethod:GET
//                            withAPIName:@"uploads/photos/?filename=image.jpg"
//                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
//        NSArray *fields = [jsonResponse objectForKey:@"fields"];
//        NSString *actionString = [jsonResponse objectForKey:@"action"];
//        [AWSUploader uploadToAWS:fields];
//    }];
}

+ (void)uploadToAWS:(NSArray *)fields {
    NSDictionary* parametersDictionary = @{
        @"AWSAccessKeyId" : [AWSUploader valueOfFieldWithName:@"AWSAccessKeyId" ofDictionary:fields],
        @"acl" : [AWSUploader valueOfFieldWithName:@"acl" ofDictionary:fields],
        @"key" : [AWSUploader valueOfFieldWithName:@"key" ofDictionary:fields],                                @"policy" : [AWSUploader valueOfFieldWithName:@"policy" ofDictionary:fields],
        @"signature" : [AWSUploader valueOfFieldWithName:@"signature" ofDictionary:fields]
    };
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:@"http://example.com/upload" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:@"file://path/to/image.jpg"] name:@"file" fileName:@"filename.jpg" mimeType:@"image/jpeg" error:nil];
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
