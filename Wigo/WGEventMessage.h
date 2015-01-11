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

typedef void (^WGEventMessageResultBlock)(WGEventMessage *object, NSError *error);

@property WGUser *user;

@property NSNumber *eventOwner;
@property NSNumber *isRead;

@property NSDictionary *properties;

@property NSNumber *vote;
@property NSNumber *downVotes;
@property NSNumber *upVotes;

@property NSString *message;
@property NSString *thumbnail;
@property NSString *media;
@property NSString *mediaMimeType;

+(WGEventMessage *)serialize:(NSDictionary *)json;

-(void) addPhoto:(NSData *)fileData withName:(NSString *)filename andHandler:(WGEventMessageResultBlock)handler;

-(void) addVideo:(NSData *)fileData withName:(NSString *)filename thumbnail:(NSData *)thumbnailData thumbnailName:(NSString *)thumbnailName andHandler:(WGEventMessageResultBlock) handler;

-(void) vote:(BOOL)upVote withHandler:(BoolResultBlock)handler;

@end
