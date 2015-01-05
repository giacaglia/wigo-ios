//
//  WGApi.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGParser.h"

typedef void (^ApiResult)(NSDictionary *jsonResponse, NSError *error);

@interface WGApi : NSObject

@property NSCache *cache;

+(void) get:(NSString *)endpoint withHandler:(ApiResult)handler;

+(void) get:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResult)handler;

+(void) delete:(NSString *)endpoint withHandler:(ApiResult)handler;

+(void) delete:(NSString *)endpoint withArguments:(NSDictionary *)arguments andHandler:(ApiResult)handler;

+(void) post:(NSString *)endpoint withParameters:(id)parameters andHandler:(ApiResult)handler;

+(void) post:(NSString *)endpoint withHandler:(ApiResult)handler;

+(void) post:(NSString *)endpoint withArguments:(NSDictionary *)arguments andParameters:(id)parameters andHandler:(ApiResult)handler;

+(void) uploadPhoto:(NSData *)fileData withFileName:(NSString *)fileName andHandler:(ApiResult) handler;

+(void) uploadVideo:(NSData *)fileData withFileName:(NSString *)fileName andHandler:(ApiResult) handler;

@end
