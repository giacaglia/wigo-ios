//
//  WGObject.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+STHelper.h"
#import "WGApi.h"

@interface WGObject : NSObject

typedef void (^ObjectResult)(WGObject *object, NSError *error);

@property NSMutableDictionary *parameters;
@property NSMutableArray *modifiedKeys;

@property NSString *className;

@property NSNumber* id;

+(WGObject *)serialize:(NSDictionary *)json;

- (BOOL)isEqual:(WGObject*)object;

- (void)save:(ObjectResult)handler;

-(NSDictionary *)deserialize;

@end
