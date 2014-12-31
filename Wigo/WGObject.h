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

@class WGCollection;

@interface WGObject : NSObject

typedef void (^CollectionResult)(WGCollection *collection, NSError *error);
typedef void (^ObjectResult)(WGObject *object, NSError *error);
typedef void (^BoolResult)(BOOL success, NSError *error);

@property NSMutableDictionary *parameters;
@property NSMutableArray *modifiedKeys;

@property NSDateFormatter *dateFormatter;
@property NSString *className;

@property NSNumber* id;
@property NSDate* created;
@property NSString* referenceId;
@property NSString* reference;

+(WGObject *)serialize:(NSDictionary *)json;

-(void) initializeWithJSON:(NSDictionary *)json;

-(BOOL) wasCreatedLastDay;

-(BOOL) isEqual:(WGObject*)object;

-(void) save:(ObjectResult)handler;

-(NSDictionary *) deserialize;

-(void) setObject:(id)object forKey:(id<NSCopying>)key;
-(id) objectForKey:(NSString *)key;

+(void) get:(CollectionResult)handler;

@end
