//
//  WGEventMessage.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGEventMessage.h"

#define kUserKey @"user"
#define kMessageKey @"message"
#define kThumbnailKey @"thumbnail"
#define kMediaKey @"media"
#define kIsReadKey @"is_read"
#define kEventOwnerKey @"event_owner"
#define kDownVotesKey @"down_votes"
#define kUpVotesKey @"up_votes"

@implementation WGEventMessage

+(WGEventMessage *)serialize:(NSDictionary *)json {
    WGEventMessage *newWGEventMessage = [WGEventMessage new];
    
    newWGEventMessage.className = @"eventmessage";
    [newWGEventMessage initializeWithJSON:json];
    
    return newWGEventMessage;
}

-(void) setMessage:(NSString *)message {
    [self setObject:message forKey:kMessageKey];
}

-(NSString *) message {
    return [self objectForKey:kMessageKey];
}

-(void) setMedia:(NSString *)media {
    [self setObject:media forKey:kMediaKey];
}

-(NSString *) media {
    return [self objectForKey:kMediaKey];
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

-(void) setIsRead:(NSNumber *)isRead {
    [self setObject:isRead forKey:kIsReadKey];
}

-(NSNumber *) isRead {
    return [self objectForKey:kIsReadKey];
}

-(void) setDownVotes:(NSNumber *)downVotes {
    [self setObject:downVotes forKey:kDownVotesKey];
}

-(NSNumber *) downVotes {
    return [self objectForKey:kDownVotesKey];
}

-(void) setUpVotes:(NSNumber *)upVotes {
    [self setObject:upVotes forKey:kUpVotesKey];
}

-(NSNumber *) upVotes {
    return [self objectForKey:kUpVotesKey];
}

-(void) setUser:(WGUser *)user {
    [self setObject:[user deserialize] forKey:kUserKey];
}

-(WGUser *) user {
    return [WGUser serialize:[self objectForKey:kUserKey]];
}

@end
