//
//  WGFollow.h
//  Wigo
//
//  Created by Adam Eagle on 1/7/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"

@interface WGFollow : WGObject

typedef void (^WGFollowResultBlock)(WGFollow *object, NSError *error);

@property NSString *name;
@property NSString *expires;
@property NSNumber *isRead;
@property NSNumber *isExpired;
@property NSNumber *numAttending;
@property NSNumber *numMessages;
@property WGUser *user;
@property WGUser *follow;

+(WGFollow *)serialize:(NSDictionary *)json;

+(void) getFollowsForUser:(WGUser *)user withHandler:(WGCollectionResultBlock)handler;

+(void) searchFollows:(NSString *)query forUser:(WGUser *)user withHandler:(WGCollectionResultBlock)handler;
+(void) searchFollows:(NSString *)query forFollow:(WGUser *)user withHandler:(WGCollectionResultBlock)handler;

@end
