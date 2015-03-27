//
//  NSObject+NetworkFetcher.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/27/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGGetter.h"

@interface NetworkFetcher : NSObject

+ (WGGetter *)defaultGetter;


@end