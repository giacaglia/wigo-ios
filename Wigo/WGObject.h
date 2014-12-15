//
//  WGObject.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WGObject : NSMutableDictionary

+(WGObject *)serialize:(NSDictionary *)json;

-(NSNumber *) numberAtKey:(NSString *)key;
-(NSString *) stringAtKey:(NSString *)key;
-(NSDictionary *) dictionaryAtKey:(NSString *)key;
-(NSDate *) dateAtKey:(NSString *)key;

@property NSNumber* id;

@end
