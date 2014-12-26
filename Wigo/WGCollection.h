//
//  WGCollection.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGObject.h"

@interface WGCollection : NSObject

typedef void (^CollectionResult)(WGCollection *collection, NSError *error);

@property NSMutableArray *objects;
@property NSNumber *hasNextPage;
@property NSString *nextPage;

+(WGCollection *)initWithResponse:(NSDictionary *) jsonResponse andClass:(Class)type;

@end