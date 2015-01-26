//
//  WGMessage.h
//  Wigo
//
//  Created by Adam Eagle on 12/30/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGUser.h"
#import "JSQMessagesViewController/JSQMessages.h"

@interface WGMessage : WGObject<JSQMessageData>

typedef void (^WGMessageResultBlock)(WGMessage *object, NSError *error);

@property WGUser *user;
@property WGUser *toUser;
@property NSString *message;
@property NSNumber *isRead;
@property NSNumber *expired;

-(WGUser *) otherUser;

+(WGMessage *)serialize:(NSDictionary *)json;
+(void) getConversations:(WGCollectionResultBlock)handler;

-(void) deleteConversation:(BoolResultBlock)handler;
-(void) readConversation:(BoolResultBlock)handler;

@end
