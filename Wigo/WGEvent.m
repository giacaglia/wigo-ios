//
//  WGEvent.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGEvent.h"
#import "WGProfile.h"
#import "WGCache.h"
#import "FontProperties.h"

#define kNameKey @"name"

#define kIsReadKey @"is_read"
#define kIsExpiredKey @"is_expired"
#define kExpiresKey @"expires"
#define kNumAttendingKey @"num_attending"
#define kNumMessagesKey @"num_messages"
#define kMessagesKey @"messages"
#define kAttendeesKey @"attendees"
#define kHighlightKey @"highlight"
#define kPrivacyKey @"privacy"
#define kOwnerKey @"owner"
#define kTagsKey @"tags"
#define kAggregateKey @"aggregate"
#define kVerifiedKey @"verified"

@implementation WGEvent

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"event";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"event";
    }
    return self;
}

-(void) replaceReferences {
    [super replaceReferences];
    if ([self objectForKey:kAttendeesKey]  && [[self objectForKey:kAttendeesKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGCollection serializeResponse:[self objectForKey:kAttendeesKey] andClass:[WGUser class]] forKey:kAttendeesKey];
    }
    if ([self objectForKey:kHighlightKey]  && [[self objectForKey:kHighlightKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGEventMessage serialize:[self objectForKey:kHighlightKey]] forKey:kHighlightKey];
    }
    if ([self objectForKey:kMessagesKey] && [[self objectForKey:kMessagesKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGCollection serializeResponse:[self objectForKey:kMessagesKey] andClass:[WGEventMessage class]] forKey:kMessagesKey];
    }
}

+(WGEvent *)serialize:(NSDictionary *)json {
    return [[WGEvent alloc] initWithJSON:json];
}

-(void) setName:(NSString *)name {
    [self setObject:name forKey:kNameKey];
}

-(NSString *) name {
    return [self objectForKey:kNameKey];
}

- (BOOL)isPrivate {
    NSString *privacy = [self objectForKey:kPrivacyKey];
    if (privacy) return [privacy isEqual:@"private"];
    return NO;
}

- (void)setIsPrivate:(BOOL)isPrivate {
    NSString *privacy = isPrivate ? @"private" : @"public";
    [self setObject:privacy forKey:kPrivacyKey];
}

-(void) setExpires:(NSDate *)expires {
    [self setObject:[expires deserialize] forKey:kExpiresKey];
}

-(NSDate *) expires {
    return [NSDate serialize:[self objectForKey:kExpiresKey]];
}

-(void) setNumAttending:(NSNumber *)numAttending {
    [self setObject:numAttending forKey:kNumAttendingKey];
}

-(NSNumber *) numAttending {
    return [self objectForKey:kNumAttendingKey];
}

-(void) setIsRead:(NSNumber *)isRead {
    [self setObject:isRead forKey:kIsReadKey];
}

-(NSNumber *) isRead {
    return [self objectForKey:kIsReadKey];
}

-(void) setIsExpired:(NSNumber *)isExpired {
    [self setObject:isExpired forKey:kIsExpiredKey];
}

-(NSNumber *) isExpired {
    return [self objectForKey:kIsExpiredKey];
}

-(void) setNumMessages:(NSNumber *)numMessages {
    [self setObject:numMessages forKey:kNumMessagesKey];
}

-(NSNumber *) numMessages {
    return [self objectForKey:kNumMessagesKey];
}

-(void) setHighlight:(WGEventMessage *)highlight {
    [self setObject:highlight forKey:kHighlightKey];
}

-(WGEventMessage *) highlight {
    return [self objectForKey:kHighlightKey];
}

- (NSArray *)tags {
    return [self objectForKey:kTagsKey];
}

- (void)setTags:(NSArray *)tags {
    [self setObject:tags forKey:kTagsKey];
}


- (BOOL)isAggregate {
    return self.tags && [self.tags containsObject:kAggregateKey];
}

- (void)setIsAggregate:(BOOL)isAggregate {
    NSMutableArray *mutableTags = [NSMutableArray arrayWithArray:self.tags];
    if (isAggregate && ![mutableTags containsObject:kAggregateKey]) {
        [mutableTags addObject:kAggregateKey];
    }
    if (!isAggregate && [mutableTags containsObject:kAggregateKey]) {
        [mutableTags removeObject:kAggregateKey];
    }
    self.tags = mutableTags;
}

- (BOOL)isVerified {
    return self.tags && [self.tags containsObject:kVerifiedKey];
}

- (WGCollection *)messages {
    return [self objectForKey:kMessagesKey];
}

- (void)setMessages:(WGCollection *)messages {
    [self setObject:messages forKey:kMessagesKey];
}

-(void) setAttendees:(WGCollection *)attendees {
    [self setObject:attendees forKey:kAttendeesKey];
}

-(WGCollection *) attendees {
    return [self objectForKey:kAttendeesKey];
}

-(BOOL)isEvent2Lines {
    CGSize size = [self.name sizeWithAttributes:
                   @{NSFontAttributeName:[FontProperties semiboldFont:18.0f]}];
    if (size.width > [UIScreen mainScreen].bounds.size.width - 30) {
        return YES;
    }
    return NO;
}

-(void) addAttendee:(WGEventAttendee *)attendee {
    if (self.attendees) {
        [self.attendees addObject:attendee];
        return;
    }
    self.attendees = [WGCollection serializeArray:@[ [attendee deserialize] ] andClass:[WGEventAttendee class]];
}

- (void)setPrivacyOn:(BOOL)isPrivate andHandler:(BoolResultBlock)handler {
    NSString *privacyString = isPrivate ? @"private" : @"public";
    [WGApi post:[NSString stringWithFormat:@"events/%@/", self.id] withParameters:@{kPrivacyKey : privacyString} andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) setRead:(BoolResultBlock)handler {
    [WGApi post:@"events/read/" withParameters:@[ self.id ] andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) setMessagesRead:(WGCollection *) messages andHandler:(BoolResultBlock)handler {
    [WGApi post:[NSString stringWithFormat:@"events/%@/messages/read/", self.id] withParameters:[messages idArray] andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

- (WGUser *)owner {
    return [[WGUser alloc] initWithJSON:[self objectForKey:kOwnerKey]];
}

-(void) removeMessage:(WGEventMessage *)eventMessage withHandler:(BoolResultBlock)handler {
    [WGApi delete:[NSString stringWithFormat:@"events/%@/messages/%@", self.id, eventMessage.id] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

- (void)getMessagesForHighlights:(WGEventMessage *)highlight
                     withHandler:(WGCollectionResultBlock)handler {
    if (!self.id || !highlight.id) return;
    [WGApi get:@"eventmessages/" withArguments:@{ @"event" : self.id, @"start": highlight.id, @"limit": @10}
    andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[WGEventMessage class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];

}

-(void) getMeta:(BoolResultBlock)handler {
    __weak typeof(self) weakSelf = self;
    NSString *graphAPIURL;
    [WGApi get:[NSString stringWithFormat:@"events/%@/messages/meta/", self.id]
   withHandler:^(NSDictionary *jsonResponse, NSError *error) {
       __strong typeof(weakSelf) strongSelf = weakSelf;
       if (error) {
           handler(NO, error);
           return;
       }
       [strongSelf addMetaInfo:jsonResponse];
       handler(YES, error);
    }];
}

// The format of the dictionary is going to be like
// {
//    "2015-04-28" :  590430140402: {"num_votes": 1, "voted" : 1} },
//    "2015-04-27" :
//      { 481374382733: {"num_votes": 10, "voted" : 0}, 481374382733 : {{"num_votes": 10, "voted" : 0}  },
// }
-(void)addMetaInfo:(NSDictionary *)meta {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *timeString = [dateFormatter stringFromDate:self.created];
    NSDictionary *toDictionary = @{timeString: meta};
    NSDictionary *fromDictionary = [[WGCache sharedCache] objectForKey:kEventMessagesKey];
    NSMutableDictionary *resultingDictionary = [WGEvent addDictionary:fromDictionary
                                                         toDictionary:toDictionary];
    [[WGCache sharedCache] setObject:resultingDictionary forKey:kEventMessagesKey];
}


// addedDictionary:  {
//                     "2015-04-28" : { 590430140402: {"num_votes": 1, "voted" : 1} }
//                   }
//    toDictionary:  {
//                     "2015-04-28" : { 139204923003: {"num_votes": 1, "voted" : 1} }
//                   }
//
//         returns:  {
//                     "2015-04-28" : { 590430140402: {"num_votes": 1, "voted" : 1},
//                                      139204923003: {"num_votes": 1, "voted" : 1} }
//                   }
+ (NSMutableDictionary *)addDictionary:(NSDictionary *)fromDictionary
                   toDictionary:(NSDictionary *)toDictionary {
    if (!fromDictionary) return [NSMutableDictionary dictionaryWithDictionary:toDictionary];
    if ([fromDictionary isEqual:toDictionary]) return [NSMutableDictionary dictionaryWithDictionary:fromDictionary];
    NSMutableDictionary *resultDictionary = [NSMutableDictionary new];
    for (NSString *key in fromDictionary.allKeys) {
        if ([toDictionary.allKeys containsObject:key]) {
            id toObject = [toDictionary objectForKey:key];
            if ([toObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *fromObject = [fromDictionary objectForKey:key];
                NSMutableDictionary *subDictionary = [WGEvent addDictionary:fromObject toDictionary:toObject];
                [resultDictionary setObject:subDictionary forKey:key];
            }
            else {
                
            }
        }
        else {
            [resultDictionary setObject:[fromDictionary objectForKey:key] forKey:key];
        }
    }
    for (NSString *key in toDictionary.allKeys) {
        if (![resultDictionary.allKeys containsObject:key]) {
            [resultDictionary setObject:[toDictionary objectForKey:key] forKey:key];
        }
    }
    return resultDictionary;
}

-(void) getInvites:(WGCollectionResultBlock)handler {
    [WGApi get:[NSString stringWithFormat:@"events/%@/invites/", self.id] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[WGUser class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

-(void) getMessages:(WGCollectionResultBlock)handler {
    [WGApi get:@"eventmessages/" withArguments:@{ @"event" : self.id, @"ordering" : @"-id" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[WGEventMessage class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) get:(WGCollectionResultBlock)handler {
    NSString* eventsString;
    if (WGProfile.isLocal) eventsString = @"events/";
    else eventsString = @"users/me/events/";
    [WGApi get:eventsString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void)getAggregateStatsWithHandler:(WGAggregateStats)handler {
    if (WGProfile.peekingGroupID) {
        NSDictionary *arguments = @{@"group": WGProfile.peekingGroupID};
        [WGApi get:@"events/private_aggregate_summary"
     withArguments:arguments
        andHandler:^(NSDictionary *jsonResponse, NSError *error) {
            if (error) {
                handler(nil, nil, error);
                return;
            }
            NSError *dataError;
            NSNumber *numberOfMessages;
            NSNumber *numberOfAttending;
            @try {
                numberOfMessages = [jsonResponse objectForKey:@"num_messages"];
                numberOfAttending = [jsonResponse objectForKey:@"num_attending"];
            }
            @catch (NSException *exception) {
                NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
                
                dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
            }
            @finally {
                handler(numberOfMessages, numberOfAttending, dataError);
            }
        }];
    }
    else {
        [WGApi get:@"events/private_aggregate_summary" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            if (error) {
                handler(nil, nil, error);
                return;
            }
            NSError *dataError;
            NSNumber *numberOfMessages;
            NSNumber *numberOfAttending;
            @try {
                numberOfMessages = [jsonResponse objectForKey:@"num_messages"];
                numberOfAttending = [jsonResponse objectForKey:@"num_attending"];
            }
            @catch (NSException *exception) {
                NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
                
                dataError = [NSError errorWithDomain: @"WGApi" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
            }
            @finally {
                handler(numberOfMessages, numberOfAttending, dataError);
            }
        }];
    }
}

+(void) getWithGroupNumber: (NSNumber *)groupNumber andHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"events" withArguments:@{ @"group" : groupNumber, @"attendees_limit" : @10, @"limit" : @10, @"eventmessage_limit": @10 } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void)createEventWithName:(NSString *)name andPrivate:(BOOL)isPrivate andHandler:(WGEventResultBlock)handler {
    NSString *privacy = isPrivate ? @"private" : @"public";
    [WGApi post:@"events/" withParameters:@{ @"name" : name,
                                             @"attendees_limit" : @10 ,
                                             kPrivacyKey: privacy
                                             }
        andHandler:^(NSDictionary *jsonResponse, NSError *error) {
            
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGEvent *object;
        @try {
            object = [WGEvent serialize:jsonResponse];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(object, dataError);
        }
    }];
}


-(void) refresh:(BoolResultBlock)handler {
    NSString *thisObjectURL = [NSString stringWithFormat:@"%@s/%@?attendees_limit=10", self.className, self.id];
    
    [WGApi get:thisObjectURL withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self replaceReferences];
            [self.modifiedKeys removeAllObjects];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGObject" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}


@end
