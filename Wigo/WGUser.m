//
//  WGUser.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGUser.h"
#import "WGEvent.h"

#define kKeyKey @"key"
#define kEmailKey @"email"
#define kNameKey @"name"
#define kFacebookAccessTokenKey @"facebook_access_token"
#define kPrivacyKey @"privacy"
#define kIsFollowerKey @"is_follower"
#define kNumFollowingKey @"num_following"
#define kIsTappedKey @"is_tapped"
#define kIsBlockedKey @"is_blocked"
#define kIsBlockingKey @"is_blocking"
#define kBioKey @"bio"
#define kImageKey @"image"
#define kModifiedKey @"modified"
#define kIsFollowingKey @"is_following"
#define kLastNameKey @"last_name"
#define kIsFollowingRequestedKey @"is_following_requested"
#define kIsGoingOutKey @"is_goingout"

#define kPropertiesKey @"properties" //: {},
#define kImagesKey @"images"
#define kURLKey @"url"
#define kCropKey @"crop"

#define kNotificationsKey @"notifications"
#define kTapsKey @"taps"
#define kFavoritesGoingOutKey @"favorites_going_out"
#define kIsFavoriteKey @"is_favorite" //: false,
#define kFirstNameKey @"first_name" //: "Josh",
#define kGenderKey @"gender" //: "male",
#define kFacebookIdKey @"facebook_id" //: "10101301503877593",
#define kNumFollowersKey @"num_followers" //: 5,
#define kUsernameKey @"username" //: "jelman"
#define kIsAttendingKey @"is_attending"

#define kGroupKey @"group" //: {},
#define kGroupRankKey @"group_rank" //: 60
#define kNumMembersKey @"num_members"

#define kGenderMaleValue @"male"
#define kGenderFemaleValue @"female"

#define kPrivacyPublicValue @"public"
#define kPrivacyPrivateValue @"private"

@interface WGUser()

@end


static WGUser *currentUser = nil;

@implementation WGUser

+(WGUser *) serialize:(NSDictionary *)json {
    WGUser *newWGUser = [WGUser new];
    
    newWGUser.className = @"user";
    [newWGUser initializeWithJSON:json];
    
    return newWGUser;
}

+(void) setCurrentUser:(WGUser *)user {
    currentUser = user;
    [[NSUserDefaults standardUserDefaults] setObject:user.key forKey:@"key"];
}

+(WGUser *) currentUser {
    return currentUser;
}

-(void) setKey:(NSString *)key {
    [self setObject:key forKey:kKeyKey];
}

-(NSString *) key {
    return [self objectForKey:kKeyKey];
}

-(void) setPrivacy:(NSString *)privacy {
    /* if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPublicValue]) {
     newWGUser.privacy =             PUBLIC;
     } else if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPrivateValue]) {
     newWGUser.privacy =             PRIVATE;
     } else {
     newWGUser.privacy =             OTHER;
     } */
    [self setObject:privacy forKey:kPrivacyKey];
}

-(NSString *) privacy {
    return [self objectForKey:kPrivacyKey];
}

-(void) setBio:(NSString *)bio {
    [self setObject:bio forKey:kBioKey];
}

-(NSString *) bio {
    return [self objectForKey:kBioKey];
}

-(void) setImage:(NSString *)image {
    [self setObject:image forKey:kImageKey];
}

-(NSString *) image {
    return [self objectForKey:kImageKey];
}

-(void) setLastName:(NSString *)lastName {
    [self setObject:lastName forKey:kLastNameKey];
}

-(NSString *) lastName {
    return [self objectForKey:kLastNameKey];
}

-(void) setFirstName:(NSString *)firstName {
    [self setObject:firstName forKey:kFirstNameKey];
}

-(NSString *) firstName {
    return [self objectForKey:kFirstNameKey];
}

-(void) setModified:(NSDate *)modified {
    [self setObject:[self.dateFormatter stringFromDate:modified] forKey:kModifiedKey];
}

-(NSDate *) modified {
    return [self.dateFormatter dateFromString: [self objectForKey:kModifiedKey]];
}

-(void) setGender:(NSString *)gender {
    /* if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderMaleValue]) {
     newWGUser.gender =              MALE;
     } else if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderFemaleValue]) {
     newWGUser.gender =              FEMALE;
     } else {
     newWGUser.gender =              UNKNOWN;
     } */
    [self setObject:gender forKey:kGenderKey];
}

-(NSString *) gender {
    return [self objectForKey:kGenderKey];
}

-(void) setUsername:(NSString *)username {
    [self setObject:username forKey:kUsernameKey];
}

-(NSString *) username {
    return [self objectForKey:kUsernameKey];
}

-(void) setEmail:(NSString *)email {
    [self setObject:email forKey:kEmailKey];
}

-(NSString *) email {
    return [self objectForKey:kEmailKey];
}

-(void) setFacebookId:(NSString *)facebookId {
    [self setObject:facebookId forKey:kFacebookIdKey];
}

-(NSString *) facebookId {
    return [self objectForKey:kFacebookIdKey];
}

-(void) setFacebookAccessToken:(NSString *)facebookAccessToken {
    [self setObject:facebookAccessToken forKey:kFacebookAccessTokenKey];
}

-(NSString *) facebookAccessToken {
    return [self objectForKey:kFacebookAccessTokenKey];
}

-(void) setNumFollowing:(NSNumber *)numFollowing {
    [self setObject:numFollowing forKey:kNumFollowingKey];
}

-(NSNumber *) numFollowing {
    return [self objectForKey:kNumFollowingKey];
}

-(void) setNumFollowers:(NSNumber *)numFollowers {
    [self setObject:numFollowers forKey:kNumFollowersKey];
}

-(NSNumber *) numFollowers {
    return [self objectForKey:kNumFollowersKey];
}

-(void) setGroupRank:(NSNumber *)groupRank {
    [self setObject:groupRank forKey:kGroupRankKey];
}

-(NSNumber *) groupRank {
    return [self objectForKey:kGroupRankKey];
}

-(void) setProperties:(NSDictionary *)properties {
    [self setObject:properties forKey:kPropertiesKey];
}

-(NSDictionary *) properties {
    return [self objectForKey:kPropertiesKey];
}

-(NSArray *) images {
    NSDictionary *properties = self.properties;
    return [properties objectForKey:kImagesKey];
}

-(void) setImages:(NSArray *)images {
    NSMutableDictionary *properties = [[[NSMutableDictionary alloc] init] initWithDictionary: self.properties];
    [properties setObject:images forKey:kImagesKey];
    self.properties = properties;
}

-(void) addImageURL:(NSString *)imageURL {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self images]];
    if ([imagesArray count] < 5) {
        [imagesArray addObject: @{kURLKey : imageURL}];
        [self setImages: imagesArray];
    }
}

-(void) removeImageAtIndex:(NSInteger)index {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self images]];
    if ([imagesArray count] > 3) {
        [imagesArray removeObjectAtIndex:index];
        [self setImages: imagesArray];
    }
}

-(void) makeImageAtIndexCoverImage:(NSInteger)index {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self images]];
    if (index < [imagesArray count]) {
        [imagesArray exchangeObjectAtIndex:index withObjectAtIndex:0];
        [self setImages: imagesArray];
    }
}

-(NSURL *) coverImageURL {
    return [NSURL URLWithString: [[self.images objectAtIndex:0] objectForKey:kURLKey]];
}

-(void) setGroup:(NSDictionary *)group {
    [self setObject:group forKey:kGroupKey];
}

-(NSDictionary *) group {
    return [self objectForKey:kGroupKey];
}

-(void) setGroupName:(NSString *)groupName {
    NSMutableDictionary *groupDict = [[[NSMutableDictionary alloc] init] initWithDictionary: self.group];
    [groupDict setObject:groupName forKey:kNameKey];
    self.group = groupDict;
}

-(NSString *) groupName {
    return [self.group objectForKey:kNameKey];
}

-(void) setGroupNumberMembers:(NSString *)groupNumberMembers {
    NSMutableDictionary *groupDict = [[[NSMutableDictionary alloc] init] initWithDictionary: self.group];
    [groupDict setObject:groupNumberMembers forKey:kNumMembersKey];
    self.group = groupDict;
}

-(NSNumber *) groupNumberMembers {
    return [self.group objectForKey:kNumMembersKey];
}

-(void) setIsAttending:(WGEvent *)isAttending {
    [self setObject:[isAttending deserialize] forKey:kIsAttendingKey];
}

-(WGEvent *) isAttending {
    return [WGEvent serialize: [self objectForKey:kIsAttendingKey]];
}

-(void) setIsBlocked:(NSNumber *)isBlocked {
    [self setObject:isBlocked forKey:kIsBlockedKey];
}

-(NSNumber *) isBlocked {
    return [self objectForKey:kIsBlockedKey];
}

-(void) setIsBlocking:(NSNumber *)isBlocking {
    [self setObject:isBlocking forKey:kIsBlockingKey];
}

-(NSNumber *) isBlocking {
    return [self objectForKey:kIsBlockingKey];
}

-(void) setIsFavorite:(NSNumber *)isFavorite {
    [self setObject:isFavorite forKey:kIsFavoriteKey];
}

-(NSNumber *) isFavorite {
    return [self objectForKey:kIsFavoriteKey];
}

-(void) setIsFollower:(NSNumber *)isFollower {
    [self setObject:isFollower forKey:kIsFollowerKey];
}

-(NSNumber *) isFollower {
    return [self objectForKey:kIsFollowerKey];
}

-(void) setIsFollowing:(NSNumber *)isFollowing {
    [self setObject:isFollowing forKey:kIsFollowingKey];
}

-(NSNumber *) isFollowing {
    return [self objectForKey:kIsFollowingKey];
}

-(void) setIsFollowingRequested:(NSNumber *)isFollowingRequested {
    [self setObject:isFollowingRequested forKey:kIsFollowingRequestedKey];
}

-(NSNumber *) isFollowingRequested {
    return [self objectForKey:kIsFollowingRequestedKey];
}

-(void) setIsGoingOut:(NSNumber *)isGoingOut {
    [self setObject:isGoingOut forKey:kIsGoingOutKey];
}

-(NSNumber *) isGoingOut {
    return [self objectForKey:kIsGoingOutKey];
}

-(void) setIsTapped:(NSNumber *)isTapped {
    [self setObject:isTapped forKey:kIsTappedKey];
}

-(NSNumber *) isTapped {
    return [self objectForKey:kIsTappedKey];
}

-(void) setIsTapPushNotificationEnabled:(NSNumber *)isTapPushNotificationEnabled {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:self.properties];
    
    NSMutableDictionary *notifications = [[NSMutableDictionary alloc] initWithDictionary:[properties objectForKey:kNotificationsKey]];
    
    [notifications setObject:isTapPushNotificationEnabled forKey:kTapsKey];
    [properties setObject:notifications forKey:kNotificationsKey];
    
    self.properties = properties;
}

-(NSNumber *) isTapPushNotificationEnabled {
    if (self.properties) {
        if ([self.properties objectForKey:kNotificationsKey]) {
            return [[self.properties objectForKey:kNotificationsKey] objectForKey:kTapsKey];
        }
    }
    return nil;
}

-(void) setIsFavoritesGoingOutNotificationEnabled:(NSNumber *)isFavoritesGoingOutNotificationEnabled {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:self.properties];
    
    NSMutableDictionary *notifications = [[NSMutableDictionary alloc] initWithDictionary:[properties objectForKey:kNotificationsKey]];
    
    [notifications setObject:isFavoritesGoingOutNotificationEnabled forKey:kFavoritesGoingOutKey];
    [properties setObject:notifications forKey:kNotificationsKey];
    
    self.properties = properties;
}

-(NSNumber *) isFavoritesGoingOutNotificationEnabled {
    if (self.properties) {
        if ([self.properties objectForKey:kNotificationsKey]) {
            return [[self.properties objectForKey:kNotificationsKey] objectForKey:kFavoritesGoingOutKey];
        }
    }
    return nil;
}

-(State) state {
    if ([self.isBlocked boolValue]) {
        return BLOCKED_USER_STATE;
    }
    if ([self.privacy isEqualToString: @"private"]) {
        if ([self.isFollowing boolValue]) {
            if (self.isAttending) return ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE;
            return FOLLOWING_USER_STATE;
        }
        else if ([self.isFollowingRequested boolValue]) {
            return NOT_YET_ACCEPTED_PRIVATE_USER_STATE;
        }
        else return NOT_SENT_FOLLOWING_PRIVATE_USER_STATE;
    }
    if ([self.isFollowing boolValue]) {
        if (self.isAttending) return ATTENDING_EVENT_FOLLOWING_USER_STATE;
        return FOLLOWING_USER_STATE;
    }
    return NOT_FOLLOWING_PUBLIC_USER_STATE;
}

-(void) signup:(UserResult)handler {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:self.facebookId forKey:kFacebookIdKey];
    [parameters setObject:self.facebookAccessToken forKey:kFacebookAccessTokenKey];
    [parameters setObject:self.email forKey:kEmailKey];
    if (self.firstName) {
        [parameters setObject:self.firstName forKey:kFirstNameKey];
    }
    if (self.lastName) {
        [parameters setObject:self.firstName forKey:kLastNameKey];
    }
    if (self.gender) {
        [parameters setObject:self.gender forKey:kGenderKey];
    }
    [WGApi post:@"register" withParameters:parameters andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        WGUser *user = [self.class serialize:jsonResponse];
        handler(user, error);
    }];
}


-(void) login:(UserResult)handler {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:self.facebookId forKey:kFacebookIdKey];
    [parameters setObject:self.facebookAccessToken forKey:kFacebookAccessTokenKey];
    [parameters setObject:self.email forKey:kEmailKey];
    
    [WGApi post:@"login" withParameters:parameters andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        WGUser *user = [self.class serialize:jsonResponse];
        handler(user, error);
    }];
}

+(void) get:(CollectionResult)handler {
    [WGApi get:@"users/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *users = [WGCollection serializeResponse:jsonResponse andClass:[self class]];
        handler(users, error);
    }];
}

+(void) getCurrentUser:(UserResult)handler {
    [WGApi get:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        handler([WGUser serialize:jsonResponse], error);
    }];
}

#pragma mark Various API Calls

-(void) broadcastMessage:(NSString *) message withHandler:(BoolResult)handler {
    [WGApi post:@"school/broadcast" withParameters:@{ @"message": message } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) resendVerificationEmail:(BoolResult) handler {
    [WGApi get:@"verification/resend" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) uploadFile:(NSData *)fileData withName:(NSString *)filename options:(NSDictionary *)options andHandler:(BoolResult) handler {
    
#warning Complete this - fix AWSUploader
    
}

-(void) uploadVideo:(NSData *)fileData withName:(NSString *)filename thumbnail:(NSData *)thumbnailData thumbnailName:(NSString *)thumnailName options:(NSDictionary *)options andHandler:(BoolResult) handler {

#warning Complete this - fix AWSUploader
    
}

-(void) sendInvites:(NSDictionary *)numbers withHandler:(BoolResult)handler {
    [WGApi post:@"invites/?force=true" withParameters:numbers andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) unblock:(WGUser *)user withHandler:(BoolResult)handler {
    NSString *queryString = [NSString stringWithFormat:@"users/%@", user.id];
    
    [WGApi post:queryString withParameters:@{ @"is_blocked" : @NO } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isBlocked = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) block:(WGUser *)user withType:(NSNumber *)type andHandler:(BoolResult)handler {
    [WGApi post:@"blocks/" withParameters:@{ @"block" : user.id, @"type" : type } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isBlocked = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}


-(void) tap:(WGUser *)user withHandler:(BoolResult)handler {
    [WGApi post:@"taps" withParameters:@{ @"tapped" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isTapped = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) untap:(WGUser *)user withHandler:(BoolResult)handler {
    NSString *queryString = [NSString stringWithFormat:@"users/%@/", user.id];
    [WGApi post:queryString withParameters:@{ @"is_tapped" : @NO } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isTapped = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) unfollow:(WGUser *)user withHandler:(BoolResult)handler {
#warning Can you unfollow by User ID?
    NSString *queryString = [NSString stringWithFormat:@"follows/?user=me&follow=%@", user.id];
    [WGApi delete:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollowing = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) follow:(WGUser *)user withHandler:(BoolResult)handler {
    [WGApi post:@"follows/" withParameters:@{ @"follow" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollowingRequested = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) acceptFollowRequestForUser:(WGUser *)user withHandler:(BoolResult)handler {
    NSString *queryString = [NSString stringWithFormat:@"follows/accept?from=%@", user.id];
    [WGApi get:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollower = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) rejectFollowRequestForUser:(WGUser *)user withHandler:(BoolResult)handler {
    NSString *queryString = [NSString stringWithFormat:@"follows/reject?from=%@", user.id];
    [WGApi get:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollower = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) goingOut:(BoolResult)handler {
    [WGApi post:@"goingouts/" withParameters:@{} andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            self.isGoingOut = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) goingToEvent:(WGEvent *)event withHandler:(BoolResult)handler {
    [WGApi post:@"eventattendees/" withParameters:@{ @"event" : event.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            self.isGoingOut = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

@end
