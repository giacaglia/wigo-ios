//
//  WGObject.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+STHelper.h"

@interface WGObject : NSObject

@property NSInteger id;

+(WGObject *)serialize:(NSDictionary *)json;

- (BOOL)isEqual:(WGObject*)object;

@end
