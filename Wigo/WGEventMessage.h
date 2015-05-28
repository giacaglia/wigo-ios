//
//  WGEventMessage.h
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"
#import "JSQMessagesViewController/JSQMessages.h"
#define kImageEventType @"image/jpeg"
#define kVideoEventType @"video/mp4"
#define kTextType @"text"


@interface WGEventMessage : WGObject<JSQMessageData>

typedef void (^WGEventMessageResultBlock)(WGEventMessage *object, NSError *error);

@property WGUser *user;

@property NSNumber *eventOwner;
@property NSDictionary *properties;
@property NSString *message;
@property NSString *thumbnail;
@property NSString *media;
@property NSString *mediaMimeType;


- (void)postEventMessage:(BoolResultBlock)handler;
+(WGEventMessage *)serialize:(NSDictionary *)json;

-(void) addPhoto:(NSData *)fileData withName:(NSString *)filename andHandler:(WGEventMessageResultBlock)handler;

-(void) addVideo:(NSData *)fileData withName:(NSString *)filename thumbnail:(NSData *)thumbnailData thumbnailName:(NSString *)thumbnailName andHandler:(WGEventMessageResultBlock) handler;

-(void) vote:(BOOL)upVote forEvent:(WGEvent *)event withHandler:(BoolResultBlock)handler;

// Properties saved in the client
@property NSNumber *isRead;
@property NSNumber *vote;
@property NSNumber *upVotes;
- (NSString *)dayString;
@property NSDictionary *metaEventMessageProperties;
@end
