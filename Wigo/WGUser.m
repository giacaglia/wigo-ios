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

#import "UIImageView+ImageArea.h"

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
#define kWidthKey @"width"
#define kHeightKey @"height"
#define kSmallWidthKey @"small_width"
#define kSmallHeightKey @"small_height"
#define kInstaHandle @"instaHandle"
#define kEventsInsideProperties @"events"
#define kTriggers @"triggers"
#define kFindReferrer @"find_referrer"
#define kTooltipTracked @"tooltip_tracked"

#define kReferredByKey @"referred_by"
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
#define kPeriodWentOutKey @"period_went_out"

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

-(void) replaceReferences {
    [super replaceReferences];
    if ([self objectForKey:kGroupKey] && [[self objectForKey:kGroupKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGGroup serialize:[self objectForKey:kGroupKey]] forKey:kGroupKey];
    }
    if ([self objectForKey:kIsAttendingKey] && [[self objectForKey:kIsAttendingKey] isKindOfClass:[NSDictionary class]]) {
        [self.parameters setObject:[WGEvent serialize:[self objectForKey:kIsAttendingKey]] forKey:kIsAttendingKey];
    }
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
    [[NSUserDefaults standardUserDefaults] setObject:lastNotificationRead forKey:kLastNotificationReadKey];
}

-(NSNumber *) lastNotificationRead {
    if ([self objectForKey:kLastNotificationReadKey]) {
        return [self objectForKey:kLastNotificationReadKey];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastNotificationReadKey]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:kLastNotificationReadKey];
    }
    return @0;
}

-(void) setLastUserRead:(NSNumber *)lastUserRead {
    [self setObject:lastUserRead forKey:kLastUserReadKey];
}

-(NSNumber *) lastUserRead {
    return [self objectForKey:kLastUserReadKey];
}

-(void)setPeriodWentOut:(NSNumber *)periodWentOut {
    [self setObject:periodWentOut forKey:kPeriodWentOutKey];
}

-(NSNumber *)periodWentOut {
    return [self objectForKey:kPeriodWentOutKey];
}

-(void) setGender:(Gender)gender {
    NSString *genderName = nil;
    if ([WGUser genderNames].count > gender) {
        genderName = [[WGUser genderNames] objectAtIndex:gender];
    }
    [self setObject:genderName forKey:kGenderKey];
}

-(Gender) gender {
    if ([[WGUser genderNames] indexOfObject:[self objectForKey: kGenderKey]] == NSNotFound) {
        return MALE;
    }
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

- (NSString *)instaHandle {
    NSDictionary *properties = self.properties;
    return [properties objectForKey:kInstaHandle];
}

- (void)setInstaHandle:(NSString *)instaHandle {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary: self.properties];
    [properties setObject:instaHandle forKey:kInstaHandle];
    self.properties = properties;
}

-(NSArray *) images {
    NSDictionary *properties = self.properties;
    if ([properties.allKeys containsObject:kImagesKey]) {
        return [properties objectForKey:kImagesKey];
    }
    return [NSArray new];
}

-(void) setImages:(NSArray *)images {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary: self.properties];
    [properties setObject:images forKey:kImagesKey];
    self.properties = properties;
}

- (NSDictionary *)events {
    NSDictionary *properties = self.properties;
    if ([[properties allKeys] containsObject:kEventsInsideProperties]) {
        return [properties objectForKey:kEventsInsideProperties];
    }
    return [NSDictionary new];
}

- (void)setEvents:(NSDictionary *)events {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:self.properties];
    [properties setObject:events forKey:kEventsInsideProperties];
    self.properties = properties;
}

- (NSArray *)triggers {
    NSDictionary *events = self.events;
    if ([events.allKeys containsObject:kTriggers]) {
        return [events objectForKey:kTriggers];
    }
    return [NSArray new];
}

- (void)setTriggers:(NSArray *)triggers {
    NSMutableDictionary *events = [[NSMutableDictionary alloc] initWithDictionary:self.events];
    if (triggers.count == 0) {
        if ([[events allKeys] containsObject:kTriggers]) {
            [events removeObjectForKey:kTriggers];
        }
    }
    else {
        [events setObject:triggers forKey:kTriggers];
    }
    self.events = events;
}

- (BOOL)findReferrer {
    if ([self.triggers containsObject:kFindReferrer]) {
        return YES;
    }
    return NO;
}

- (void)setFindReferrer:(BOOL)findReferrer {
    NSMutableArray *triggers = [[NSMutableArray alloc] initWithArray:self.triggers];

    if (findReferrer) {
        if (![triggers containsObject:kFindReferrer]) {
            [triggers addObject:kFindReferrer];
        }
    }
    else {
        [triggers removeObject:kFindReferrer];
    }
    self.triggers = triggers;
}


- (NSArray *)arrayTooltipTracked {
    NSMutableDictionary *events = [[NSMutableDictionary alloc] initWithDictionary:self.events];
    if ([[events allKeys] containsObject:kTooltipTracked]) {
        return [events objectForKey:kTooltipTracked];
    }
    
    return [NSArray new];
}

- (void)setArrayTooltipTracked:(NSArray *)arrayTooltipTracked {
    NSMutableDictionary *events = [[NSMutableDictionary alloc] initWithDictionary:self.events];
    [events setObject:arrayTooltipTracked forKey:kTooltipTracked];
    self.events = events;
}

- (void)addTootltipTracked:(NSString *)tooltipTracked {
    NSMutableArray *arrayTooltipTracked = [[NSMutableArray alloc] initWithArray:self.arrayTooltipTracked];
    [arrayTooltipTracked addObject:tooltipTracked];
    [self setArrayTooltipTracked:arrayTooltipTracked];
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

-(void) setImageDictionary:(NSDictionary *)imageDictionary forIndex:(NSInteger)index {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self images]];
    if (index >= 0 && index < [imagesArray count]) {
        [imagesArray replaceObjectAtIndex:index withObject:imageDictionary];
        [self setImages: imagesArray];
    }
}

-(void) removeImageAtIndex:(NSInteger)index {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self images]];
    if (index < 0 || index >= [imagesArray count]) {
        NSLog(@"Invalid index %ld for image removal", (long)index);
        return;
    }
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
    if (self.images && [self.images count] > 0) {
        return [NSURL URLWithString: [[self.images objectAtIndex:0] objectForKey:kURLKey]];
    }
    return [NSURL URLWithString:@""];
}

-(NSURL *) smallCoverImageURL {
    if (self.images && [self.images count] > 0 && [[self.images objectAtIndex:0] objectForKey:kSmallKey]) {
        return [NSURL URLWithString: [[self.images objectAtIndex:0] objectForKey:kSmallKey]];
    }
    return [self coverImageURL];
}

-(UIImage *) avatarImage {
    if (!self.avatarView) {
        self.avatarView = [[UIImageView alloc] init];
        [self.avatarView setImageWithURL:[self smallCoverImageURL] imageArea:[self smallCoverImageArea]];
    }
    return self.avatarView.image;
}

-(UIImage *) avatarHighlightedImage {
    return nil;
}

-(UIImage *) avatarPlaceholderImage {
    return [UIImage imageNamed:@"grayIcon"];
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
    return [NSArray new];
}

-(NSArray *) smallImagesURL {
    NSArray *images = [self images];
    if (self.properties && images) {
        return [images valueForKey:kSmallKey];
    }
    return [NSArray new];
}

-(NSDictionary *) coverImageArea {
    NSArray *imagesArea = [self imagesArea];
    if (imagesArea && [imagesArea count] > 0) {
        return [imagesArea objectAtIndex:0];
    }
    return [[NSDictionary alloc] init];
}

-(NSDictionary *) smallCoverImageArea {
    if ([[self.images objectAtIndex:0] objectForKey:kSmallKey]) {
        NSArray *imagesArea = [self imagesArea];
        if (imagesArea && [imagesArea count] > 0) {
            NSDictionary *area = [imagesArea objectAtIndex:0];
            if (area && ![area isEqual:[NSNull null]]) {
                NSNumber *width = [[self.images objectAtIndex:0] objectForKey:kWidthKey];
                NSNumber *smallWidth = [[self.images objectAtIndex:0] objectForKey:kSmallWidthKey];
                float resize = 3.0;
                if (width && smallWidth) {
                    resize = [width floatValue] / [smallWidth floatValue];
                }
                NSMutableDictionary *smallArea = [[NSMutableDictionary alloc] init];
                for (id key in [area allKeys]) {
                    int resizedValue = ([[area objectForKey:key] floatValue] / resize);
                    [smallArea setObject:[NSNumber numberWithInt:resizedValue] forKey:key];
                }
                return smallArea;
            }
        }
        return [[NSDictionary alloc] init];
    }
    return [self coverImageArea];
}

-(void) setGroup:(WGGroup *)group {
    [self setObject:group forKey:kGroupKey];
}

-(WGGroup *) group {
    return [self objectForKey:kGroupKey];
}

-(void) setEmailValidated:(NSNumber *)emailValidated {
    [self setObject:emailValidated forKey:kEmailValidatedKey];
}

-(NSNumber *) emailValidated {
    return [self objectForKey:kEmailValidatedKey];
}

-(void) setEventAttending:(WGEvent *)eventAttending {
    [self setObject:eventAttending forKey:kIsAttendingKey];
}

-(WGEvent *) eventAttending {
    return [self objectForKey:kIsAttendingKey];
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

-(void) setReferredBy:(NSNumber *)referredByNumber {
    [self setObject:referredByNumber forKey:kReferredByKey];
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
    if (self.isCurrentUser) {
        if (self.privacy == PRIVATE) return PRIVATE_STATE;
        else return PUBLIC_STATE;
    }
    if ([self.isBlocked boolValue]) {
        return BLOCKED_USER_STATE;
    }
    if (self.privacy == PRIVATE) {
        if ([self.isFollowingRequested boolValue]) {
            return NOT_YET_ACCEPTED_PRIVATE_USER_STATE;
        }
        else if ([self.isFollowing boolValue]) {
            if (self.eventAttending) return ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE;
            return FOLLOWING_USER_STATE;
        }
        else return NOT_SENT_FOLLOWING_PRIVATE_USER_STATE;
    }
    if ([self.isFollowing boolValue] || [self.isFollowingRequested boolValue]) {
        if (self.eventAttending) return ATTENDING_EVENT_FOLLOWING_USER_STATE;
        return FOLLOWING_USER_STATE;
    }
    return NOT_FOLLOWING_PUBLIC_USER_STATE;
}

-(void) followUser {
    // If it's blocked
    if (self.isBlocked.boolValue) {
        self.isBlocked = @NO;
        [WGProfile.currentUser unblock:self withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionDelete];
            }
        }];
    }
    else {
        if (self.isFollowing.boolValue || self.isFollowingRequested.boolValue) {
            // If it's following user
            self.isFollowing = @NO;
            self.isFollowingRequested = @NO;
            [WGProfile.currentUser unfollow:self withHandler:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] logError:error forAction:WGActionDelete];
                }
            }];
            
        }
        else  {
            if (self.privacy == PRIVATE) {
                // If it's not following and it's private
                self.isFollowingRequested = @YES;
            } else {
                // If it's not following and it's public
                self.isFollowing = @YES;
            }
            [WGProfile.currentUser follow:self withHandler:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] logError:error forAction:WGActionPost];
                }
            }];
        }
    }
    
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


-(void) refetchUserWithGroup:(NSNumber *)groupID andHandler:(BoolResultBlock)handler {
    __weak typeof(self) weakSelf = self;
    if (!groupID) {
        [WGApi get:[NSString stringWithFormat:@"users/%@", self.id] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                handler(NO, error);
                return;
            }
            NSError *dataError;
            @try {
                strongSelf.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            }
            @catch (NSException *exception) {
                NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
                
                dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
            }
            @finally {
                handler(YES, nil);
                return;
            }
        }];

    }
    else {
        [WGApi get:[NSString stringWithFormat:@"users/%@", self.id]
     withArguments:@{@"group": groupID.stringValue}
        andHandler:^(NSDictionary *jsonResponse, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                handler(NO, error);
                return;
            }
            NSError *dataError;
            @try {
                strongSelf.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
            }
            @catch (NSException *exception) {
                NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
                
                dataError = [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
            }
            @finally {
                handler(YES, nil);
                return;
            }
        }];
 
    }
}

-(void) getNotMeForMessage:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/me/"  withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

-(void) searchNotMe:(NSString *)query withContext:(NSString *)contextString withHandler:(WGCollectionResultBlock)handler {
    if (!query) {
        return handler(nil, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi get:@"users/" withArguments:@{ @"id__ne" : self.id, @"text" : query , @"context": contextString} andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

-(void) searchNotMe:(NSString *)query withHandler:(WGCollectionResultBlock)handler {
    if (!query) {
        return handler(nil, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi get:@"users/" withArguments:@{ @"id__ne" : self.id, @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

+(void) getReferals:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/" withArguments:@{ @"context" : @"referral" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

-(void) getFriendRequests:(WGCollectionResultBlock)handler {
    [WGApi get:[NSString stringWithFormat:@"users/%@/friends/requests", self.id]
   withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

+(void) searchInvites:(NSString *)query withHandler:(WGCollectionResultBlock)handler {
    if (!query) {
        return handler(nil, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi get:@"users/suggestions/" withArguments:@{ @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
//    [WGApi get:@"users/suggestions/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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


+(void) searchReferals:(NSString *)query withHandler:(WGSerializedCollectionResultBlock)handler {
    if (!query) {
        return handler([NSURL URLWithString:@"users/"], nil, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi get:@"users/" withArguments:@{ @"context": @"referral", @"text" : query, @"id__ne" : [WGProfile currentUser].id } andSerializedHandler:^(NSURL *urlSent, NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(urlSent, nil, error);
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
            handler(urlSent, objects, dataError);
        }
    }];
}


+(void) searchUsers:(NSString *)query withHandler:(WGCollectionResultBlock)handler {
    if (!query) {
        return handler(nil, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi get:@"users/" withArguments:@{ @"text" : query, @"id__ne" : [WGProfile currentUser].id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
    if (!message) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
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
    [WGApi post:@"invites/" withArguments:@{} andParameters:numbers andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) unblock:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [user saveKey:kIsBlockedKey withValue:@NO andHandler:^(BOOL success, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) block:(WGUser *)user withType:(NSString *)type andHandler:(BoolResultBlock)handler {
    if (!user.id || !type) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi post:@"blocks/" withParameters:@{ @"block" : user.id, @"type" : type } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isBlocked = @YES;
        }
        handler(error == nil, error);
    }];
}


-(void) tapUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    if (!user.id) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi post:@"users/me/taps/" withParameters:@{ @"tapped_id" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isTapped = @YES;
        }
        handler(error == nil, error);
    }];
}

- (void)tapAllUsersWithHandler:(BoolResultBlock)handler {
    [WGApi post:@"taps" withParameters:@{ @"following" : @YES } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) tapUsers:(WGCollection *)users withHandler:(BoolResultBlock)handler {
    NSMutableArray *taps = [[NSMutableArray alloc] init];
    for (WGUser *user in users) {
        if (!user.id) {
            return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
        }
        [taps addObject:@{ @"tapped" : user.id }];
    }
    [WGApi post:@"taps" withParameters:taps andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            for (WGUser *user in users) {
                user.isTapped = @YES;
            }
        }
        handler(error == nil, error);
    }];
}

-(void) untap:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [user saveKey:kIsTappedKey withValue:@NO andHandler:^(BOOL success, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) unfollow:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [user saveKey:kIsFollowingKey withValue:@NO andHandler:^(BOOL success, NSError *error) {
        handler(error == nil, error);
    }];
}

-(void) follow:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [WGApi post:[NSString stringWithFormat:@"users/me/friends/"] withParameters:@{ @"friend_id": user.id} andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollowingRequested = @YES;
        }
        handler(error == nil, error);
    }];

}

-(void) acceptFollowRequestForUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    if (!user.id) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi post:@"users/me/friends/" withParameters:@{ @"friend_id" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollower = @YES;
            self.numFollowers = @([self.numFollowers intValue] + 1);
        }
        handler(error == nil, error);
    }];
}

-(void) rejectFollowRequestForUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    if (!user.id) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi delete:@"users/me/friends/" withArguments:@{ @"friend_id" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFollower = @NO;
        }
        handler(error == nil, error);
    }];
}

-(void) goingOut:(BoolResultBlock)handler {
    [WGApi post:@"goingouts/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            self.isGoingOut = @YES;
        }
        handler(error == nil, error);
    }];
}

-(void) goingToEvent:(WGEvent *)event withHandler:(BoolResultBlock)handler {
    if (!event.id) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi post:@"eventattendees/" withParameters:@{ @"event" : event.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            self.isGoingOut = @YES;
            self.eventAttending = event;
        }
        handler(error == nil, error);
    }];
}

-(void) readConversation:(BoolResultBlock)handler {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", self.id];
    
    NSDictionary *options = @{ @"read": @YES };
    
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
    [WGApi get:@"messages/" withArguments:@{ @"conversation" : self.id, @"ordering" : @"-id" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

-(void) remove:(BoolResultBlock)handler {
    handler(NO, [NSError errorWithDomain: @"WGUser" code: 0 userInfo: @{NSLocalizedDescriptionKey : @"cannot delete user" }]);
}

@end
