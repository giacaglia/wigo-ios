//
//  WGEventMessage.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGEventMessage.h"
#import "WGEvent.h"

#define kUserKey @"user"
#define kMessageKey @"message"
#define kThumbnailKey @"thumbnail"
#define kPropertiesKey @"properties"
#define kMediaKey @"media"
#define kIsReadKey @"is_read"
#define kEventOwnerKey @"event_owner"
#define kVoteKey @"vote"
#define kDownVotesKey @"down_votes"
#define kUpVotesKey @"up_votes"
#define kMediaMimeType @"media_mime_type"

#define kImageEventType @"image/jpeg"
#define kVideoEventType @"video/mp4"

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

-(void) setVote:(NSNumber *)vote {
    [self setObject:vote forKey:kVoteKey];
}

-(NSNumber *) vote {
    return [self objectForKey:kVoteKey];
}

-(void) setUpVotes:(NSNumber *)upVotes {
    [self setObject:upVotes forKey:kUpVotesKey];
}

-(NSNumber *) upVotes {
    return [self objectForKey:kUpVotesKey];
}

-(void) setUser:(WGUser *)user {
    [self setObject:user forKey:kUserKey];
}

-(WGUser *) user {
    return [self objectForKey:kUserKey];
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

-(void) vote:(BOOL)upVote withHandler:(BoolResultBlock)handler {
    [WGApi post:@"eventmessagevotes/" withParameters:@{ @"message" : self.id, @"up_vote": @(upVote) } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

@end
