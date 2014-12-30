//
//  WGUser.m
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGUser.h"

#define kIdKey @"id"
#define kKeyKey @"key"
#define kEmailKey @"email"
#define kNameKey @"name"
#define kFacebookAccessTokenKey @"facebook_access_token"
#define kPrivacyKey @"privacy" //: "public",
#define kIsFollowerKey @"is_follower" //: false,
#define kNumFollowingKey @"num_following" //: 10,
#define kIsTappedKey @"is_tapped" //: false,
#define kIsBlockedKey @"is_blocked" //: false,
#define kIsBlockingKey @"is_blocking" //: false,
#define kBioKey @"bio" //: "I go out. But mostly in the mornings. ",
#define kImageKey @"image" //: null,
#define kCreatedKey @"created" //: "2014-12-14 21:41:58",
#define kModifiedKey @"modified" //: "2014-12-14 21:41:58",
#define kIsFollowingKey @"is_following" //: false,
#define kLastNameKey @"last_name" //: "Elman",
#define kIsFollowingRequestedKey @"is_following_requested" //: false,
#define kIsGoingOutKey @"is_goingout" //: false,

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

+(WGUser *)serialize:(NSDictionary *)json {
    WGUser *newWGUser = [WGUser new];
    
    newWGUser.className = @"user";
    newWGUser.dateFormatter = [[NSDateFormatter alloc] init];
    [newWGUser.dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    
    newWGUser.modifiedKeys = [[NSMutableArray alloc] init];
    newWGUser.parameters = [[NSMutableDictionary alloc] initWithDictionary: json];
    
    return newWGUser;
}

+ (void)setCurrentUser:(WGUser *)user {
    currentUser = user;
    [[NSUserDefaults standardUserDefaults] setObject:user.key forKey:@"key"];
}

+ (WGUser *)currentUser {
    return currentUser;
}

-(void) setKey:(NSString *)key {
    [self.parameters setObject:key forKey:kKeyKey];
    [self.modifiedKeys addObject:kKeyKey];
}

-(NSString *) key {
    return [self.parameters objectForKey:kKeyKey];
}

-(void) setPrivacy:(NSString *)privacy {
    /* if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPublicValue]) {
     newWGUser.privacy =             PUBLIC;
     } else if ([[json st_stringForKey:kPrivacyKey] isEqualToString:kPrivacyPrivateValue]) {
     newWGUser.privacy =             PRIVATE;
     } else {
     newWGUser.privacy =             OTHER;
     } */
    [self.parameters setObject:privacy forKey:kPrivacyKey];
    [self.modifiedKeys addObject:kPrivacyKey];
}

-(NSString *) privacy {
    return [self.parameters objectForKey:kPrivacyKey];
}

-(void) setBio:(NSString *)bio {
    [self.parameters setObject:bio forKey:kBioKey];
    [self.modifiedKeys addObject:kBioKey];
}

-(NSString *) bio {
    return [self.parameters objectForKey:kBioKey];
}

-(void) setImage:(NSString *)image {
    [self.parameters setObject:image forKey:kImageKey];
    [self.modifiedKeys addObject:kImageKey];
}

-(NSString *) image {
    return [self.parameters objectForKey:kImageKey];
}

-(void) setLastName:(NSString *)lastName {
    [self.parameters setObject:lastName forKey:kLastNameKey];
    [self.modifiedKeys addObject:kLastNameKey];
}

-(NSString *) lastName {
    return [self.parameters objectForKey:kLastNameKey];
}

-(void) setFirstName:(NSString *)firstName {
    [self.parameters setObject:firstName forKey:kFirstNameKey];
    [self.modifiedKeys addObject:kFirstNameKey];
}

-(NSString *) firstName {
    return [self.parameters objectForKey:kFirstNameKey];
}

-(void) setCreated:(NSDate *)created {
    [self.parameters setObject:[self.dateFormatter stringFromDate:created] forKey:kCreatedKey];
    [self.modifiedKeys addObject:kCreatedKey];
}

-(NSDate *) created {
    return [self.dateFormatter dateFromString: [self.parameters objectForKey:kCreatedKey]];
}

-(void) setModified:(NSDate *)modified {
    [self.parameters setObject:[self.dateFormatter stringFromDate:modified] forKey:kModifiedKey];
    [self.modifiedKeys addObject:kModifiedKey];
}

-(NSDate *) modified {
    return [self.dateFormatter dateFromString: [self.parameters objectForKey:kModifiedKey]];
}

-(void) setGender:(NSString *)gender {
    /* if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderMaleValue]) {
     newWGUser.gender =              MALE;
     } else if ([[json st_stringForKey:kGenderKey] isEqualToString:kGenderFemaleValue]) {
     newWGUser.gender =              FEMALE;
     } else {
     newWGUser.gender =              UNKNOWN;
     } */
    [self.parameters setObject:gender forKey:kGenderKey];
    [self.modifiedKeys addObject:kGenderKey];
}

-(NSString *) gender {
    return [self.parameters objectForKey:kGenderKey];
}

-(void) setUsername:(NSString *)username {
    [self.parameters setObject:username forKey:kUsernameKey];
    [self.modifiedKeys addObject:kUsernameKey];
}

-(NSString *) username {
    return [self.parameters objectForKey:kUsernameKey];
}

-(void) setEmail:(NSString *)email {
    [self.parameters setObject:email forKey:kEmailKey];
    [self.modifiedKeys addObject:kEmailKey];
}

-(NSString *) email {
    return [self.parameters objectForKey:kEmailKey];
}

-(void) setFacebookId:(NSString *)facebookId {
    [self.parameters setObject:facebookId forKey:kFacebookIdKey];
    [self.modifiedKeys addObject:kFacebookIdKey];
}

-(NSString *) facebookId {
    return [self.parameters objectForKey:kFacebookIdKey];
}

-(void) setFacebookAccessToken:(NSString *)facebookAccessToken {
    [self.parameters setObject:facebookAccessToken forKey:kFacebookAccessTokenKey];
    [self.modifiedKeys addObject:kFacebookAccessTokenKey];
}

-(NSString *) facebookAccessToken {
    return [self.parameters objectForKey:kFacebookAccessTokenKey];
}

-(void) setNumFollowing:(NSNumber *)numFollowing {
    [self.parameters setObject:numFollowing forKey:kNumFollowingKey];
    [self.modifiedKeys addObject:kNumFollowingKey];
}

-(NSNumber *) numFollowing {
    return [self.parameters objectForKey:kNumFollowingKey];
}

-(void) setNumFollowers:(NSNumber *)numFollowers {
    [self.parameters setObject:numFollowers forKey:kNumFollowersKey];
    [self.modifiedKeys addObject:kNumFollowersKey];
}

-(NSNumber *) numFollowers {
    return [self.parameters objectForKey:kNumFollowersKey];
}

-(void) setGroupRank:(NSNumber *)groupRank {
    [self.parameters setObject:groupRank forKey:kGroupRankKey];
    [self.modifiedKeys addObject:kGroupRankKey];
}

-(NSNumber *) groupRank {
    return [self.parameters objectForKey:kGroupRankKey];
}

-(void) setProperties:(NSDictionary *)properties {
    [self.parameters setObject:properties forKey:kPropertiesKey];
    [self.modifiedKeys addObject:kPropertiesKey];
}

-(NSDictionary *) properties {
    return [self.parameters objectForKey:kPropertiesKey];
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
    [self.parameters setObject:group forKey:kGroupKey];
    [self.modifiedKeys addObject:kGroupKey];
}

-(NSDictionary *) group {
    return [self.parameters objectForKey:kGroupKey];
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

-(void) setIsAttending:(NSNumber *)isAttending {
    [self.parameters setObject:isAttending forKey:kIsAttendingKey];
    [self.modifiedKeys addObject:kIsAttendingKey];
}

-(NSNumber *) isAttending {
    return [self.parameters objectForKey:kIsAttendingKey];
}

-(void) setIsBlocked:(NSNumber *)isBlocked {
    [self.parameters setObject:isBlocked forKey:kIsBlockedKey];
    [self.modifiedKeys addObject:kIsBlockedKey];
}

-(NSNumber *) isBlocked {
    return [self.parameters objectForKey:kIsBlockedKey];
}

-(void) setIsBlocking:(NSNumber *)isBlocking {
    [self.parameters setObject:isBlocking forKey:kIsBlockingKey];
    [self.modifiedKeys addObject:kIsBlockingKey];
}

-(NSNumber *) isBlocking {
    return [self.parameters objectForKey:kIsBlockingKey];
}

-(void) setIsFavorite:(NSNumber *)isFavorite {
    [self.parameters setObject:isFavorite forKey:kIsFavoriteKey];
    [self.modifiedKeys addObject:kIsFavoriteKey];
}

-(NSNumber *) isFavorite {
    return [self.parameters objectForKey:kIsFavoriteKey];
}

-(void) setIsFollower:(NSNumber *)isFollower {
    [self.parameters setObject:isFollower forKey:kIsFollowerKey];
    [self.modifiedKeys addObject:kIsFollowerKey];
}

-(NSNumber *) isFollower {
    return [self.parameters objectForKey:kIsFollowerKey];
}

-(void) setIsFollowing:(NSNumber *)isFollowing {
    [self.parameters setObject:isFollowing forKey:kIsFollowingKey];
    [self.modifiedKeys addObject:kIsFollowingKey];
}

-(NSNumber *) isFollowing {
    return [self.parameters objectForKey:kIsFollowingKey];
}

-(void) setIsFollowingRequested:(NSNumber *)isFollowingRequested {
    [self.parameters setObject:isFollowingRequested forKey:kIsFollowingRequestedKey];
    [self.modifiedKeys addObject:kIsFollowingRequestedKey];
}

-(NSNumber *) isFollowingRequested {
    return [self.parameters objectForKey:kIsFollowingRequestedKey];
}

-(void) setIsGoingOut:(NSNumber *)isGoingOut {
    [self.parameters setObject:isGoingOut forKey:kIsGoingOutKey];
    [self.modifiedKeys addObject:kIsGoingOutKey];
}

-(NSNumber *) isGoingOut {
    return [self.parameters objectForKey:kIsGoingOutKey];
}

-(void) setIsTapped:(NSNumber *)isTapped {
    [self.parameters setObject:isTapped forKey:kIsTappedKey];
    [self.modifiedKeys addObject:kIsTappedKey];
}

-(NSNumber *) isTapped {
    return [self.parameters objectForKey:kIsTappedKey];
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
            if ([self.isAttending boolValue]) return ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE;
            return FOLLOWING_USER_STATE;
        }
        else if ([self.isFollowingRequested boolValue]) {
            return NOT_YET_ACCEPTED_PRIVATE_USER_STATE;
        }
        else return NOT_SENT_FOLLOWING_PRIVATE_USER_STATE;
    }
    if ([self.isFollowing boolValue]) {
        if ([self.isAttending boolValue]) return ATTENDING_EVENT_FOLLOWING_USER_STATE;
        return FOLLOWING_USER_STATE;
    }
    return NOT_FOLLOWING_PUBLIC_USER_STATE;
}

- (void)signup:(UserResult)handler {
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


- (void)login:(UserResult)handler {
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

+(void) getUsers:(CollectionResult)handler {
    [WGApi get:@"users/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        WGCollection *users = [WGCollection serialize:jsonResponse andClass:[self class]];
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

@end
