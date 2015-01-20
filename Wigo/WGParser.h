//
//  WGCache.h
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WGParser : NSObject

@property NSMutableDictionary *cache;

-(id) replaceReferences:(id) object;

@end
