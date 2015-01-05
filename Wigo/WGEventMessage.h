//
//  WGEventMessage.h
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"

@interface WGEventMessage : WGObject

typedef void (^EventMessageResult)(WGEventMessage *object, NSError *error);

@property WGUser *user;

@property NSNumber *eventOwner;
@property NSNumber *isRead;

@property NSNumber *downVotes;
@property NSNumber *upVotes;

@property NSString *message;
@property NSString *thumbnail;
@property NSString *media;

+(WGEventMessage *)serialize:(NSDictionary *)json;

@end
