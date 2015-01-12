//
//  WGNotification.h
//  Wigo
//
//  Created by Adam Eagle on 12/31/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"
#import "WGEvent.h"

@interface WGNotification : WGObject

typedef void (^WGNotificationResultBlock)(WGNotification *object, NSError *error);
typedef void (^WGNotificationSummaryResultBlock)(NSNumber *follow, NSNumber *followRequest, NSNumber *total, NSNumber *tap, NSNumber *facebookFollow, NSError *error);

@property WGUser *fromUser;
@property NSString *type;;

+(WGNotification *)serialize:(NSDictionary *)json;

-(NSString *) message;

+(void) getFollowRequests:(WGCollectionResultBlock)handler;
+(void) getFollowSummary:(WGNotificationSummaryResultBlock)handler;

@end
