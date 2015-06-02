//
//  WGMessage.m
//  Wigo
//
//  Created by Adam Eagle on 12/30/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGMessage.h"
#import "WGCache.h"

#define kToUserKey @"to_user"
#define kUserKey @"user"
#define kMessageKey @"message"
#define kIsReadKey @"is_read"
#define kReadDateKey @"read_date"
#define kExpiredKey @"expired"
#define kMessagesKey @"messages"

@implementation WGMessage

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"message";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"message";
    }
    return self;
}

-(void) replaceReferences {
    [super replaceReferences];
    if ([self objectForKey:kUserKey] && [[self objectForKey:kUserKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGUser serialize:[self objectForKey:kUserKey]] forKey:kUserKey];
    }
    if ([self objectForKey:kToUserKey] && [[self objectForKey:kToUserKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGUser serialize:[self objectForKey:kToUserKey]] forKey:kToUserKey];
    }
}

+(WGMessage *)serialize:(NSDictionary *)json {
    return [[WGMessage alloc] initWithJSON:json];
}

-(void) setMessage:(NSString *)message {
    [self setObject:message forKey:kMessageKey];
}

-(NSString *) message {
    return [self objectForKey:kMessageKey];
}

-(void) setExpired:(NSNumber *)expired {
    [self setObject:expired forKey:kExpiredKey];
}

-(NSNumber *) expired {
    return [self objectForKey:kExpiredKey];
}

-(void) setIsRead:(NSNumber *)isRead {
    [self setObject:isRead forKey:kIsReadKey];
}

-(NSNumber *) isRead {
    return [self objectForKey:kIsReadKey];
}

-(WGUser *) otherUser {
    if (self.user.isCurrentUser) {
        return self.toUser;
    }
    return self.user;
}

-(void) setUser:(WGUser *)user {
    [self setObject:user forKey:kUserKey];
}

-(WGUser *) user {
    return [self objectForKey:kUserKey];
}

-(void) setToUser:(WGUser *)toUser {
    [self setObject:toUser forKey:kToUserKey];
}

-(WGUser *) toUser {
    return [self objectForKey:kToUserKey];
}


+(void) getConversations:(WGCollectionResultBlock)handler {
    [WGApi get:@"conversations/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGMessage" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

-(void) sendMessage:(WGMessageResultBlock)handler {
    [WGApi post:@"messages/"
 withParameters:@{@"to_user_id": self.toUser.id,
                    @"user_id": self.user.id,
                    @"message": self.message  }
     andHandler:^(NSDictionary *jsonResponse, NSError *error) {
         if (error) {
             handler(nil, error);
             return;
         }
         WGParser *parser = [[WGParser alloc] init];
         NSDictionary *response = [parser replaceReferences:jsonResponse];
         NSDictionary *messageResponse = [[response objectForKey:@"objects"] objectAtIndex:0];
         WGMessage *message = [[WGMessage alloc] initWithJSON:messageResponse];
         handler(message, error);
     }];
}

-(void) deleteConversation:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.toUser.id];
    [WGApi delete:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        handler(YES, error);
    }];
    
}

#pragma mark - Meta Message Properties

-(void) setReadDate:(NSDate *)readDate {
    [self setMetaObject:readDate forKey:kReadDateKey];
}

-(NSDate *)readDate {
    return [self metaObjectForKey:kReadDateKey];
}

-(void) setMetaObject:(id)object forKey:(NSString *)key {
    if (!self.otherUser.id) return;
    NSDictionary *metaMessageProperties = self.metaMessageProperties;
    if (!metaMessageProperties) metaMessageProperties = [NSDictionary new];
    NSMutableDictionary *mutFriendsMetaDict = [NSMutableDictionary dictionaryWithDictionary:metaMessageProperties];
    if (!mutFriendsMetaDict) mutFriendsMetaDict = [NSMutableDictionary new];
    if ([mutFriendsMetaDict.allKeys containsObject:self.otherUser.id.stringValue]) {
        NSMutableDictionary *metaEventMsg = [NSMutableDictionary dictionaryWithDictionary:[mutFriendsMetaDict objectForKey:self.otherUser.id.stringValue]];
        if (!metaEventMsg) metaEventMsg = [NSMutableDictionary dictionaryWithDictionary:@{key: object}];
        else [metaEventMsg setObject:object forKey:key];
        [mutFriendsMetaDict setObject:metaEventMsg forKey:self.otherUser.id.stringValue];
    }
    else {
        [mutFriendsMetaDict setObject:@{key: object} forKey:self.otherUser.id.stringValue];
    }
    self.metaMessageProperties = mutFriendsMetaDict;
}

-(id) metaObjectForKey:(NSString *)key {
    if (!self.otherUser.id) return nil;
    NSDictionary *metaProperties = self.metaMessageProperties;
    if (!metaProperties) return nil;
    if ([metaProperties.allKeys containsObject:self.otherUser.id.stringValue]) {
        NSDictionary *metaDict = [metaProperties objectForKey:self.otherUser.id.stringValue];
        if ([metaDict.allKeys containsObject:key]) return [metaDict objectForKey:key];
    }
    return nil;
}


-(NSDictionary *) metaMessageProperties {
    return [[WGCache sharedCache] objectForKey:kMessagesKey];
}

-(void) setMetaMessageProperties:(NSDictionary *)metaMessageProperties {
    [[WGCache sharedCache] setObject:metaMessageProperties forKey:kMessagesKey];
}

#pragma mark JSQMessageData protocol

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%@", self.user.id];
}

- (NSString *)senderDisplayName {
    return [self.user fullName];
}

- (NSDate *)date {
    return self.created;
}

- (BOOL)isMediaMessage {
    return NO;
}

- (NSUInteger)hash {
    return [self.id integerValue];
}

- (NSString *)text {
    return self.message;
}

/**
 *  @return The media item of the message.
 *
 *  @warning You must not return `nil` from this method.
 */
- (id<JSQMessageMediaData>)media {
    return nil;
}

@end
