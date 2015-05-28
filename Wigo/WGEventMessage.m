//
//  WGEventMessage.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGEventMessage.h"
#import "WGEvent.h"
#import "WGCache.h"

#define kUserKey @"user"
#define kMessageKey @"message"
#define kThumbnailKey @"thumbnail"
#define kPropertiesKey @"properties"
#define kMediaKey @"media"
#define kIsReadKey @"is_read"
#define kEventOwnerKey @"event_owner"
#define kVoteKey @"voted"
#define kNumVotesKey @"num_votes"
#define kMediaMimeType @"media_mime_type"



#define kMetaEventMessagesProperties @"meta_event_messages_properties"

@implementation WGEventMessage

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"eventmessage";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        // NSLog(@"%@", json.description);
        self.className = @"eventmessage";
    }
    return self;
}

-(void) replaceReferences {
    [super replaceReferences];
    if ([self objectForKey:kUserKey] && [[self objectForKey:kUserKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGUser serialize:[self objectForKey:kUserKey]] forKey:kUserKey];
    }
}

+(WGEventMessage *)serialize:(NSDictionary *)json {
    return [[WGEventMessage alloc] initWithJSON:json];
}

-(void) setMessage:(NSString *)message {
    [self setObject:message forKey:kMessageKey];
}

-(NSString *) message {
    return [self objectForKey:kMessageKey];
}

-(void) setProperties:(NSDictionary *)properties {
    [self setObject:properties forKey:kPropertiesKey];
}

-(NSDictionary *) properties {
    return [self objectForKey:kPropertiesKey];
}

-(void) setMedia:(NSString *)media {
    [self setObject:media forKey:kMediaKey];
}

-(NSString *) media {
    return [self objectForKey:kMediaKey];
}

-(void) setMediaMimeType:(NSString *)mediaMimeType {
    [self setObject:mediaMimeType forKey:kMediaMimeType];
}

-(NSString *) mediaMimeType {
    return [self objectForKey:kMediaMimeType];
}

-(void) setThumbnail:(NSString *)thumbnail {
    [self setObject:thumbnail forKey:kThumbnailKey];
}

-(NSString *) thumbnail {
    return [self objectForKey:kThumbnailKey];
}

-(void) setEventOwner:(NSNumber *)eventOwner {
    [self setObject:eventOwner forKey:kEventOwnerKey];
}

-(NSNumber *) eventOwner {
    return [self objectForKey:kEventOwnerKey];
}

-(void) setUser:(WGUser *)user {
    [self setObject:user forKey:kUserKey];
}

-(WGUser *) user {
    return [self objectForKey:kUserKey];
}

- (void)postEventMessage:(BoolResultBlock)handler {
    NSString *eventID = [self.parameters objectForKey:@"event"];
    NSString *classURL = [NSString stringWithFormat:@"events/%@/messages/", eventID];
    [self.parameters removeObjectForKey:@"event"];
    __weak typeof(self) weakSelf = self;
    [WGApi post:classURL withParameters:self.parameters andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        WGParser *parser = [[WGParser alloc] init];
        NSDictionary *response = [parser replaceReferences:jsonResponse];
        NSDictionary *messageResponse = [[response objectForKey:@"objects"] objectAtIndex:0];
        if ([messageResponse objectForKey:kRefKey] &&
            [[WGCache sharedCache] objectForKey:[messageResponse objectForKey:kRefKey]]) {
            messageResponse = [[WGCache sharedCache] objectForKey:[messageResponse objectForKey:kRefKey]];
        }
        strongSelf.parameters = [NSMutableDictionary dictionaryWithDictionary:messageResponse];
        [strongSelf replaceReferences];
        handler(YES, nil);
    }];
}


-(void) addPhoto:(NSData *)fileData withName:(NSString *)filename andHandler:(WGEventMessageResultBlock)handler {
    [WGApi uploadPhoto:fileData withFileName:filename andHandler:^(NSDictionary *jsonResponse, NSDictionary *fields, NSError *error) {
        NSError *dataError;
        if (error) {
            handler(nil, error);
            return;
        }
        @try {
            self.media = [fields objectForKey:@"key"];
            self.mediaMimeType = kImageEventType;
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEventMessage" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(self, dataError);
        }
    }];

}

-(void) addVideo:(NSData *)fileData withName:(NSString *)filename thumbnail:(NSData *)thumbnailData thumbnailName:(NSString *)thumbnailName andHandler:(WGEventMessageResultBlock) handler {
    [WGApi uploadVideo:fileData withFileName:filename thumbnailData:thumbnailData thumbnailName:thumbnailName andHandler:^(NSDictionary *jsonResponseVideo, NSDictionary *jsonResponseThumbnail, NSDictionary *videoFields, NSDictionary *thumbnailFields, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        @try {
            self.media = [videoFields objectForKey:@"key"];
            self.mediaMimeType = kVideoEventType;
            self.thumbnail = [thumbnailFields objectForKey:@"key"];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEventMessage" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(self, dataError);
        }
    }];
}

-(void) vote:(BOOL)upVote forEvent:(WGEvent *)event withHandler:(BoolResultBlock)handler {
    [WGApi post:[NSString stringWithFormat:@"events/%@/messages/%@/votes/", event.id, self.id]
    withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

#pragma - mark Meta data

-(void) setIsRead:(NSNumber *)isRead {
    [self setMetaObject:isRead forKey:kIsReadKey];
}

-(NSNumber *) isRead {
    return [self metaObjectForKey:kIsReadKey];
}

-(void) setVote:(NSNumber *)vote {
    [self setMetaObject:vote forKey:kVoteKey];
}

-(NSNumber *) vote {
    return [self metaObjectForKey:kVoteKey];
}


-(void) setUpVotes:(NSNumber *)upVotes {
    [self setMetaObject:upVotes forKey:kNumVotesKey];
}

-(NSNumber *) upVotes {
    return [self metaObjectForKey:kNumVotesKey];
}

-(void) setMetaObject:(id)object forKey:(NSString *)key {
    if (!self.id) return;
    NSDictionary *metaEventMessagesProperties = self.metaEventMessageProperties;
    if (!metaEventMessagesProperties) metaEventMessagesProperties = [NSDictionary new];
    NSMutableDictionary *mutFriendsMetaDict = [NSMutableDictionary dictionaryWithDictionary:metaEventMessagesProperties];
    if (!mutFriendsMetaDict) mutFriendsMetaDict = [NSMutableDictionary new];
    if ([mutFriendsMetaDict.allKeys containsObject:self.dayString]) {
        NSMutableDictionary *eventMessagesDict = [NSMutableDictionary dictionaryWithDictionary:[mutFriendsMetaDict objectForKey:self.dayString]];
        if (!eventMessagesDict) eventMessagesDict = [NSMutableDictionary new];
        if ([eventMessagesDict.allKeys containsObject:self.id.stringValue]) {
            NSMutableDictionary *metaEventMsg = [NSMutableDictionary dictionaryWithDictionary:[eventMessagesDict objectForKey:self.id.stringValue]];
            if (!metaEventMsg) metaEventMsg = [NSMutableDictionary dictionaryWithDictionary:@{key: object}];
            else [metaEventMsg setObject:object forKey:key];
            [eventMessagesDict setObject:metaEventMsg forKey:self.id.stringValue];
        }
        else {
            [eventMessagesDict setObject:@{key: object} forKey:self.id.stringValue];
        }
        [mutFriendsMetaDict setObject:eventMessagesDict forKey:self.dayString];
    }
    else {
        [mutFriendsMetaDict setObject:@{self.id.stringValue: @{key: object}} forKey:self.dayString];
    }
    self.metaEventMessageProperties = mutFriendsMetaDict;
}

-(id) metaObjectForKey:(NSString *)key {
    if (!self.id) return nil;
    NSDictionary *metaProperties = self.metaEventMessageProperties;
    if (!metaProperties) return nil;
    if ([metaProperties.allKeys containsObject:self.dayString]) {
        NSDictionary *eventMessagesDict = [metaProperties objectForKey:self.dayString];
        if ([eventMessagesDict.allKeys containsObject:self.id.stringValue]) {
            NSDictionary *metaDict = [eventMessagesDict objectForKey:self.id.stringValue];
            if ([metaDict.allKeys containsObject:key]) return [metaDict objectForKey:key];
        }
    }
    
    return nil;
}

-(NSString *) dayString {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    return [dateFormatter stringFromDate:self.created];
}

-(NSDictionary *) metaEventMessageProperties {
    return [[WGCache sharedCache] objectForKey:kEventMessagesKey];
}


-(void) setMetaEventMessageProperties:(NSDictionary *)metaEventMessageProperties {
    [[WGCache sharedCache] setObject:metaEventMessageProperties forKey:kEventMessagesKey];
}

#pragma mark JSQMessageData protocol

- (NSString *)senderId {
    return self.user.id.stringValue;
}

- (NSString *)senderDisplayName {
    return self.user.fullName;
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

@end
