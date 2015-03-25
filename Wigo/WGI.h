//
//  NSObject+WGI.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Globals.h"


@interface WGI : NSObject

+(void)setClientMetadata;
+(void)setGroup:(WGGroup *)group;
+(void)setUser:(WGUser *)user;
+(void)setValue:(id)value forKey:(NSString *)key;
+(void)postActionWithName:(NSString *)actionName;
+(void)setEvent:(WGEvent *)event;
+(void)setEventMessage:(WGEventMessage *)eventMessage;
+(void)postDictionary:(NSDictionary *)dict;

@end
