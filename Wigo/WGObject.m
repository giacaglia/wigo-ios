//
//  WGObject.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"

#define kIdKey @"id"

@implementation WGObject

+(WGObject *)serialize:(NSDictionary *)json {
    WGObject *newWGObject = [WGObject new];
    
    newWGObject.id = [json st_integerForKey:kIdKey];
    
    return newWGObject;
}

- (BOOL)isEqual:(WGObject*)other {
    return self.id == other.id;
}

@end
