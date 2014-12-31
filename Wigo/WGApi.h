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

+(void) post:(NSString *)endpoint withParameters:(id)parameters andHandler:(ApiResult)handler;

@end
