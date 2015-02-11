//
//  WGApi.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGParser.h"

typedef void (^ApiResultBlock)(NSDictionary *jsonResponse, NSError *error);
typedef void (^UploadResultBlock)(NSDictionary *jsonResponse, NSDictionary *fields, NSError *error);
typedef void (^UploadVideoResultBlock)(NSDictionary *jsonResponseVideo, NSDictionary *jsonResponseThumbnail, NSDictionary *videoFields, NSDictionary *thumbnailFields, NSError *error);
typedef void (^WGStartupResult)(NSString *cdnPrefix, NSNumber *googleAnalyticsEnabled, NSNumber *schoolStatistics, NSDictionary *imageProperties, NSError *error);

@class WGObject;

@interface WGApi : NSObject

+ (void) setBaseURLString:(NSString *)newBaseURLString;

@property NSCache *cache;

+(void) get:(NSString *)endpoint withHandler:(ApiResultBlock)handler;

+(void) get:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResultBlock)handler;

+(void) delete:(NSString *)endpoint withHandler:(ApiResultBlock)handler;

+(void) delete:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResultBlock)handler;

+(void) post:(NSString *)endpoint withParameters:(id)parameters andHandler:(ApiResultBlock)handler;

+(void) post:(NSString *)endpoint withHandler:(ApiResultBlock)handler;

+(void) post:(NSString *)endpoint withArguments:(NSDictionary *)arguments andParameters:(id)parameters andHandler:(ApiResultBlock)handler;

+(void) uploadPhoto:(NSData *)fileData withFileName:(NSString *)fileName andHandler:(UploadResultBlock) handler;

+(void) uploadVideo:(NSData *)fileData withFileName:(NSString *)fileName thumbnailData:(NSData *)thumbnailData thumbnailName:(NSString *)thumbnailName andHandler:(UploadVideoResultBlock) handler;

+(void) startup:(WGStartupResult)handler;

@end
