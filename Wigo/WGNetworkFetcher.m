//
//  NSObject+NetworkFetcher.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/27/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "NetworkFetcher.h"

static WGGetter *getter;

@implementation NetworkFetcher : NSObject

+ (WGGetter *)defaultGetter {
    if (getter == nil) {
        getter = [WGGetter new];
    }
    return getter;
}


@end
