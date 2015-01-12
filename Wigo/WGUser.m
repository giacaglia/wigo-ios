//
//  WGUser.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGUser.h"
#import "WGEvent.h"
#import "WGProfile.h"
#import "WGMessage.h"

#define kUserKey @"user"
#define kMeKey @"me"

#define kKeyKey @"key"
#define kEmailKey @"email"
#define kEmailValidatedKey @"email_validated"
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
#define kLastMessageReadKey @"last_message_read"
#define kLastNotificationReadKey @"last_notification_read"
#define kLastUserReadKey @"last_user_read"

#define kPropertiesKey @"properties" //: {},
#define kImagesKey @"images"
#define kURLKey @"url"
#define kSmallKey @"small"
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
#define kGroupLockedKey @"locked"
#define kGroupRankKey @"group_rank" //: 60
#define kNumMembersKey @"num_members"

#define kNumUnreadConversationsKey @"num_unread_conversations"
#define kNumUnreadNotificationsKey @"num_unread_notifications"
#define kNumUnreadUsersKey @"num_unread_users"

#define kGenderMaleValue @"male"
#define kGenderFemaleValue @"female"

#define kPrivacyPublicValue @"public"
#define kPrivacyPrivateValue @"private"

static WGUser *currentUser = nil;

@implementation WGUser

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"user";
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"user";
    }
    return self;
}

+(WGUser *) serialize:(NSDictionary *)json {
    WGUser *new = [[WGUser alloc] initWithJSON:json];
    if ([new isCurrentUser] && [WGProfile currentUser].key) {
        return [WGProfile currentUser];
    }
    return new;
}

-(BOOL) isCurrentUser {
    return [self isEqual:[WGProfile currentUser]];
}

-(void) setKey:(NSString *)key {
    [self setObject:key forKey:kKeyKey];
}

-(NSString *) key {
    return [self objectForKey:kKeyKey];
}

-(void) setPrivacy:(Privacy)privacy {
    NSString *privacyName = nil;
    if ([self privacyNames].count > privacy) {
        privacyName = [[self privacyNames] objectAtIndex:privacy];
    }
    [self setObject:privacyName forKey:kPrivacyKey];
}

-(Privacy) privacy {
    return (Privacy) [[self privacyNames] indexOfObject:[self objectForKey: kPrivacyKey]];
}

-(NSArray *) privacyNames {
    return @[kPrivacyPublicValue, kPrivacyPrivateValue];
}

-(NSString *) privacyName {
    return [[self privacyNames] objectAtIndex: self.privacy];
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

-(NSString *) fullName {
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

-(void) setModified:(NSDate *)modified {
    [self setObject:[modified deserialize] forKey:kModifiedKey];
}

-(NSDate *) modified {
    return [NSDate serialize:[self objectForKey:kModifiedKey]];
}

-(void) setLastMessageRead:(NSNumber *)lastMessageRead {
    [self setObject:lastMessageRead forKey:kLastMessageReadKey];
}

-(NSNumber *) lastMessageRead {
    return [self objectForKey:kLastMessageReadKey];
}

-(void) setLastNotificationRead:(NSNumber *)lastNotificationRead {
    [self setObject:lastNotificationRead forKey:kLastNotificationReadKey];
}

-(NSNumber *) lastNotificationRead {
    return [self objectForKey:kLastNotificationReadKey];
}

-(void) setLastUserRead:(NSNumber *)lastUserRead {
    [self setObject:lastUserRead forKey:kLastUserReadKey];
}

-(NSNumber *) lastUserRead {
    return [self objectForKey:kLastUserReadKey];
}

-(void) setGender:(Gender)gender {
    NSString *genderName = nil;
    if ([WGUser genderNames].count > gender) {
        genderName = [[WGUser genderNames] objectAtIndex:gender];
    }
    [self setObject:genderName forKey:kGenderKey];
}

-(Gender) gender {
    return (Gender) [[WGUser genderNames] indexOfObject:[self objectForKey: kGenderKey]];
}

+(Gender) genderFromName:(NSString *)name {
    return (Gender) [[WGUser genderNames] indexOfObject:name];
}

+(NSArray *) genderNames {
    return @[kGenderMaleValue, kGenderFemaleValue];
}

-(NSString *) genderName {
    return [[WGUser genderNames] objectAtIndex: self.gender];
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
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary: self.properties];
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

-(void) addImageDictionary:(NSDictionary *)imageDictionary {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self images]];
    if ([imagesArray count] < 5) {
        [imagesArray addObject: imageDictionary];
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

-(NSURL *) smallCoverImageURL {
    if ([[self.images objectAtIndex:0] objectForKey:kSmallKey]) {
        return [NSURL URLWithString: [[self.images objectAtIndex:0] objectForKey:kSmallKey]];
    }
    return [self coverImageURL];
}

-(NSArray *) imagesArea {
    if (self.properties && [[self.properties allKeys] containsObject:kImagesKey]) {
        NSArray *images = [self.properties objectForKey:kImagesKey];
        return [images valueForKey:kCropKey];
    }
    else return [[NSArray alloc] init];
}

-(NSArray *) imagesURL {
    if (self.properties && [[self.properties allKeys] containsObject:kImagesKey]) {
        NSArray *images = [self.properties objectForKey:kImagesKey];
        return [images valueForKey:kURLKey];
    }
    else return [[NSArray alloc] init];
}

-(NSDictionary *) coverImageArea {
    NSArray *imagesArea = [self imagesArea];
    if (imagesArea && [imagesArea count] > 0) {
        return [imagesArea objectAtIndex:0];
    }
    return [[NSDictionary alloc] init];
}

-(NSDictionary *) smallCoverImageArea {
    NSArray *imagesArea = [self imagesArea];
    if (imagesArea && [imagesArea count] > 0) {
        NSDictionary *area = [imagesArea objectAtIndex:0];
        if (area && ![area isEqual:[NSNull null]]) {
            NSMutableDictionary *smallArea = [[NSMutableDictionary alloc] init];
            for (id key in [area allKeys]) {
                int resizedValue = ([[area objectForKey:key] intValue] / 3);
                [smallArea setObject:[NSNumber numberWithInt:resizedValue] forKey:key];
            }
            return smallArea;
        }
    }
    return [[NSDictionary alloc] init];
}

-(void) setGroup:(WGGroup *)group {
    [self setObject:[group deserialize] forKey:kGroupKey];
}

-(WGGroup *) group {
    return [WGGroup serialize:[self objectForKey:kGroupKey]];
}

-(void) setEmailValidated:(NSNumber *)emailValidated {
    [self setObject:emailValidated forKey:kEmailValidatedKey];
}

-(NSNumber *) emailValidated {
    return [self objectForKey:kEmailValidatedKey];
}

-(void) setEventAttending:(WGEvent *)eventAttending {
    [self setObject:[eventAttending deserialize] forKey:kIsAttendingKey];
}

-(WGEvent *) eventAttending {
    return [WGEvent serialize:[self objectForKey:kIsAttendingKey]];
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

-(void) setNumUnreadConversations:(NSNumber *)numUnreadConversations {
    [self setObject:numUnreadConversations forKey:kNumUnreadConversationsKey];
}

-(NSNumber *) numUnreadConversations {
    return [self objectForKey:kNumUnreadConversationsKey];
}

-(void) setNumUnreadNotifications:(NSNumber *)numUnreadNotifications {
    [self setObject:numUnreadNotifications forKey:kNumUnreadNotificationsKey];
}

-(NSNumber *) numUnreadNotifications {
    return [self objectForKey:kNumUnreadNotificationsKey];
}

-(void) setNumUnreadUsers:(NSNumber *)numUnreadUsers {
    [self setObject:numUnreadUsers forKey:kNumUnreadUsersKey];
}

-(NSNumber *) numUnreadUsers {
    return [self objectForKey:kNumUnreadUsersKey];
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
    if ([self isCurrentUser]) {
        return FOLLOWING_USER_STATE;
    }
    if ([self.isBlocked boolValue]) {
        return BLOCKED_USER_STATE;
    }
    if (self.privacy == PRIVATE) {
        if ([self.isFollowing boolValue]) {
            if (self.eventAttending) return ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE;
            return FOLLOWING_USER_STATE;
        }
        else if ([self.isFollowingRequested boolValue]) {
            return NOT_YET_ACCEPTED_PRIVATE_USER_STATE;
        }
        else return NOT_SENT_FOLLOWING_PRIVATE_USER_STATE;
    }
    if ([self.isFollowing boolValue]) {
        if (self.eventAttending) return ATTENDING_EVENT_FOLLOWING_USER_STATE;
        return FOLLOWING_USER_STATE;
    }
    return NOT_FOLLOWING_PUBLIC_USER_STATE;
}

-(void) signup:(BoolResultBlock)handler {
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
        [parameters setObject:[self genderName] forKey:kGenderKey];
    }
    [WGApi post:@"register" withParameters:parameters andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
            [newInfo setObject:[jsonResponse objectForKey:@"message"] forKey:@"wigoMessage"];
            handler(NO, [NSError errorWithDomain:error.domain code:error.code userInfo:newInfo]);
            return;
        }
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self.modifiedKeys removeAllObjects];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}


-(void) login:(BoolResultBlock)handler {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:self.facebookId forKey:kFacebookIdKey];
    [parameters setObject:self.facebookAccessToken forKey:kFacebookAccessTokenKey];
    if (self.email) {
        [parameters setObject:self.email forKey:kEmailKey];
    }
    
    [WGApi post:@"login" withParameters:parameters andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
            [newInfo setObject:[jsonResponse objectForKey:@"code"] forKey:@"wigoCode"];
            handler(NO, [NSError errorWithDomain:error.domain code:error.code userInfo:newInfo]);
            return;
        }
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            [self.modifiedKeys removeAllObjects];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}

+(void) get:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getNotMe:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"id__ne" : [WGProfile currentUser].id, @"ordering" : @"is_goingout" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) searchNotMe:(NSString *)query withHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"id__ne" : [WGProfile currentUser].id, @"ordering" : @"is_goingout", @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getOnboarding:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"query" : @"onboarding" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getOrderedById:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"ordering" : @"id" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getInvites:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"following" : @"true", @"ordering" : @"invite" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) searchInvites:(NSString *)query withHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"following" : @"true", @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];

}

+(void) getSuggestions:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/suggestions/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) searchUsers:(NSString *)query withHandler:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(objects, dataError);
        }
    }];
}

+(void) getNewestUser:(WGUserResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"limit" : @1 } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGUser *user;
        @try {
            user = (WGUser *)[[WGCollection serializeResponse:jsonResponse andClass:[self class]] objectAtIndex:0];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(user, dataError);
        }
    }];
}

#pragma mark Various API Calls

-(void) broadcastMessage:(NSString *) message withHandler:(BoolResultBlock)handler {
    [WGApi post:@"school/broadcast" withParameters:@{ @"message": message } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) resendVerificationEmail:(BoolResultBlock) handler {
    [WGApi get:@"verification/resend" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) sendInvites:(NSArray *)numbers withHandler:(BoolResultBlock)handler {
    [WGApi post:@"invites/" withArguments:@{ @"force" : @YES } andParameters:numbers andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) unblock:(WGUser *)user withHandler:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"users/%@", user.id];
    
    [WGApi post:queryString withParameters:@{ kIsBlockedKey : @NO } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isBlocked = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) block:(WGUser *)user withType:(NSString *)type andHandler:(BoolResultBlock)handler {
    [WGApi post:@"blocks/" withParameters:@{ @"block" : user.id, @"type" : type } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isBlocked = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}


-(void) tapUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [WGApi post:@"taps" withParameters:@{ @"tapped" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isTapped = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) tapUsers:(WGCollection *)users withHandler:(BoolResultBlock)handler {
    NSMutableArray *taps = [[NSMutableArray alloc] init];
    for (WGUser *user in users) {
        [taps addObject:@{ @"tapped" : user.id }];
    }
    [WGApi post:@"taps" withParameters:taps andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            for (WGUser *user in users) {
                user.isTapped = [NSNumber numberWithBool:YES];
            }
        }
        handler(error == nil, error);
    }];
}

-(void) untap:(WGUser *)user withHandler:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"users/%@/", user.id];
    [WGApi post:queryString withParameters:@{ kIsTappedKey : @NO } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isTapped = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) unfollow:(WGUser *)user withHandler:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"users/%@/", user.id];
    [WGApi delete:queryString withArguments:@{ kIsFollowingKey : @NO } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollowing = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) follow:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [WGApi post:@"follows/" withParameters:@{ @"follow" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollowingRequested = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) acceptFollowRequestForUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [WGApi get:@"follows/accept" withArguments:@{ @"from" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollower = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) rejectFollowRequestForUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [WGApi get:@"follows/reject" withArguments:@{ @"from" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollower = [NSNumber numberWithBool:NO];
        }
        handler(error == nil, error);
    }];
}

-(void) goingOut:(BoolResultBlock)handler {
    [WGApi post:@"goingouts/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            self.isGoingOut = [NSNumber numberWithBool:YES];
        }
        handler(error == nil, error);
    }];
}

-(void) goingToEvent:(WGEvent *)event withHandler:(BoolResultBlock)handler {
    [WGApi post:@"eventattendees/" withParameters:@{ @"event" : event.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            self.isGoingOut = [NSNumber numberWithBool:YES];
            self.eventAttending = event;
        }
        handler(error == nil, error);
    }];
}

-(void) readConversation:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.id];
    
    NSDictionary *options = @{ @"read": [NSNumber numberWithBool:YES] };
    
    [WGApi post:queryString withParameters:options andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        handler(YES, error);
    }];
}

-(void) deleteConversation:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.id];
    
    [WGApi delete:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(NO, error);
            return;
        }
        handler(YES, error);
    }];
}

-(void) getConversation:(WGCollectionResultBlock)handler {
    [WGApi get:@"messages/" withArguments:@{ @"conversation" : self.id, @"ordering" : @"id" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[WGMessage class]];
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

@end
