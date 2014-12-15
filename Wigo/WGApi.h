//
//  WGApi.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

typedef void (^ApiResult)(NSDictionary *jsonResponse, NSError *error);

@interface WGApi : NSObject

+(NSString *) getUrlStringForEndpoint:(NSString *)endpoint;

+(void) get:(NSString *)endpoint withHandler:(ApiResult)handler;

+(void) post:(NSString *)endpoint withParameters:(NSDictionary *)parameters andHandler:(ApiResult)handler;

@end
