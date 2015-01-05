//
//  WGNotification.h
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"

@interface WGNotification : WGObject

typedef void (^WGNotificationResultBlock)(WGNotification *object, NSError *error);

@property WGUser *fromUser;
@property NSString *type;;

+(WGNotification *)serialize:(NSDictionary *)json;

@end
