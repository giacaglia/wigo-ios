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
#import "WGError.h"
#import "NSDate+WGDate.h"
#define kRefKey @"$ref"

@class WGCollection;

@interface WGObject : NSObject

typedef void (^WGCollectionResultBlock)(WGCollection *collection, NSError *error);
typedef void (^WGObjectResultBlock)(WGObject *object, NSError *error);
typedef void (^BoolResultBlock)(BOOL success, NSError *error);

@property NSMutableDictionary *parameters;
@property NSMutableArray *modifiedKeys;

@property NSString *className;

@property NSNumber* id;
@property NSDate* created;

-(id) init;
-(id) initWithJSON:(NSDictionary *)json;

+(WGObject *)serialize:(NSDictionary *)json;
-(NSDictionary *) deserialize;
-(void) replaceReferences;

-(BOOL) isFetched;

-(BOOL) isEqual:(WGObject*)object;

-(BOOL) isFromLastDay;

-(void) setObject:(id)object forKey:(id<NSCopying>)key;
-(id) objectForKey:(NSString *)key;

-(void) refresh:(BoolResultBlock)handler;
-(void) save:(BoolResultBlock)handler;
-(void) saveKey:(NSString *)key withValue:(id)value andHandler:(BoolResultBlock)handler;
-(void) remove:(BoolResultBlock)handler;
+(void) get:(WGCollectionResultBlock)handler;
-(void) create:(BoolResultBlock)handler;

@end
