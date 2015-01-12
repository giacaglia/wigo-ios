//
//  WGEventAttendee.h
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"

@interface WGEventAttendee : WGObject

@property WGUser *user;
@property NSNumber* eventOwner;

+(WGEventAttendee *)serialize:(NSDictionary *)json;

+(void) getForEvent:(WGEvent *)event withHandler:(WGCollectionResultBlock)handler;

@end
