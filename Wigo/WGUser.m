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
#define kNumFollowingKey @"num_following"
#define kIsTappedKey @"is_tapped"
#define kFriendRequestKey @"friend_request"
#define kIsFriendKey @"is_friend"
#define kIsBlockedKey @"is_blocked"
#define kIsBlockingKey @"is_blocking"
#define kBioKey @"bio"
#define kImageKey @"image"
#define kModifiedKey @"modified"
#define kLastNameKey @"last_name"
#define kIsGoingOutKey @"is_goingout"
#define kLastMessageReadKey @"last_message_read"
#define kLastNotificationReadKey @"last_notification_read"
#define kLastUserReadKey @"last_user_read"

#define kImagesKey @"images"
#define kHometownKey @"hometown"
#define kWorkKey @"work"
#define kEducationKey @"education"
#define kFriendsMetaKey @"friends_meta"
#define kBirthdayKey @"birthday"
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
#define kFirstNameKey @"first_name" //: "Josh",
#define kGenderKey @"gender" //: "male",
#define kFacebookIdKey @"facebook_id" //: "10101301503877593",
#define kNumFriendsKey @"num_friends" //: 5,
#define kUsernameKey @"username" //: "jelman"
#define kIsAttendingKey @"is_attending"
#define kPeriodWentOutKey @"period_went_out"
#define kNumMutualFriends @"num_mutual_friends"

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

#define kFriendRequestSent @"sent"
#define kFriendRequestReceived @"received"
#define kDictionaryTappedList @"is_tapped_dictionary"
#define kDictionaryIsFriendRequestList @"is_friend_request_read_list"

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

-(void) setLastMessageRead:(NSDate *)lastMessageRead {
    [[NSUserDefaults standardUserDefaults] setObject:lastMessageRead forKey:kLastMessageReadKey];
}

-(NSDate *) lastMessageRead {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastMessageReadKey]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:kLastMessageReadKey];
    }
    return nil;
}

-(void) setLastNotificationRead:(NSDate *)lastNotificationRead {
    [[NSUserDefaults standardUserDefaults] setObject:lastNotificationRead forKey:kLastNotificationReadKey];
}

-(NSDate *) lastNotificationRead {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastNotificationReadKey]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:kLastNotificationReadKey];
    }
    return nil;
}

-(void) setLastUserRead:(NSDate *)lastUserRead {
    [[NSUserDefaults standardUserDefaults] setObject:lastUserRead forKey:kLastUserReadKey];
}

-(NSDate *) lastUserRead {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastUserReadKey]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:kLastUserReadKey];
    }
    return nil;
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

-(void) setNumFriends:(NSNumber *)numFriends {
    [self setObject:numFriends forKey:kNumFriendsKey];
}

-(NSNumber *) numFriends {
    return [self objectForKey:kNumFriendsKey];
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

- (NSString *)hometown {
    NSDictionary *properties = self.properties;
    return [properties objectForKey:kHometownKey];
}

- (void)setHometown:(NSString *)hometown {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary: self.properties];
    [properties setObject:hometown forKey:kHometownKey];
    self.properties = properties;
}

- (NSString *)work {
    NSDictionary *properties = self.properties;
    return [properties objectForKey:kWorkKey];
}

- (void)setWork:(NSString *)work {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary: self.properties];
    [properties setObject:work forKey:kWorkKey];
    self.properties = properties;
}

- (NSString *)education {
    NSDictionary *properties = self.properties;
    return [properties objectForKey:kEducationKey];
}

- (void)setEducation:(NSString *)education {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary: self.properties];
    [properties setObject:education forKey:kEducationKey];
    self.properties = properties;
}

-(NSString *)age {
    NSString *birthday = self.birthday;
    if (!birthday) return @"";
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *dateFromString = [NSDate new];
    dateFromString = [dateFormatter dateFromString:birthday];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDateComponents *conversionInfo = [calendar components:NSYearCalendarUnit fromDate:dateFromString toDate:[NSDate date]  options:0];
    return [NSString stringWithFormat:@"%ld", (long)[conversionInfo year]];
}

-(NSDictionary *)friendsMetaDict {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kFriendsMetaKey];
}


-(void) setFriendsMetaDict:(NSDictionary *)friendsMetaDict {
    [[NSUserDefaults standardUserDefaults] setObject:friendsMetaDict forKey:kFriendsMetaKey];
}

-(void) setMetaObject:(id)object forKey:(NSString *)key {
    if (!self.id) return;
    if (WGProfile.currentUser.friendsMetaDict) {
        NSMutableDictionary *mutFriendsMetaDict = [NSMutableDictionary dictionaryWithDictionary:WGProfile.currentUser.friendsMetaDict];
        if ([mutFriendsMetaDict.allKeys containsObject:self.id.stringValue]) {
            NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithDictionary:[mutFriendsMetaDict objectForKey:self.id.stringValue]];
            [userDict setObject:object forKey:key];
            [mutFriendsMetaDict setObject:userDict forKey:self.id.stringValue];
        }
        else {
            NSDictionary *userDict = @{key : object};
            [mutFriendsMetaDict setObject:userDict forKey:self.id.stringValue];
        }
        WGProfile.currentUser.friendsMetaDict = mutFriendsMetaDict;
    }
    else {
        NSMutableDictionary *mutFriendsMetaDict = [NSMutableDictionary new];
        NSDictionary *userDict = @{key : object};
        [mutFriendsMetaDict setObject:userDict forKey:self.id.stringValue];
        WGProfile.currentUser.friendsMetaDict = mutFriendsMetaDict;
    }

}

-(id) metaObjectForKey:(NSString *)key {
    if (!self.id) return nil;
    NSDictionary *friendsMetaDict = WGProfile.currentUser.friendsMetaDict;
    if (friendsMetaDict) {
        if ([friendsMetaDict.allKeys containsObject:self.id.stringValue]) {
            NSDictionary *userDict = [friendsMetaDict objectForKey:self.id.stringValue];
            if ([userDict.allKeys containsObject:key]) return [userDict objectForKey:key];
        }
    }
    return nil;
}


-(NSString *)birthday {
    NSDictionary *properties = self.properties;
    return [properties objectForKey:kBirthdayKey];
}

- (void)setBirthday:(NSString *)birthday {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary: self.properties];
    [properties setObject:birthday forKey:kBirthdayKey];
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

-(void) setIsFriend:(NSNumber *)isFriend {
    [self setMetaObject:isFriend forKey:kIsFriendKey];
}

-(NSNumber *) isFriend {
    return [self metaObjectForKey:kIsFriendKey];
}

-(void) setFriendRequest:(NSString *)friendRequest {
    [self setMetaObject:friendRequest forKey:kFriendRequestKey];
}

-(NSString *) friendRequest {
    return [self metaObjectForKey:kFriendRequestKey];
}

-(void) setFriendsIds:(NSArray*)friendsIds {
    for (NSString *friendID in friendsIds) {
        WGUser *user = [[WGUser alloc] initWithJSON:@{@"id": friendID}];
        [user setIsFriend:@YES];
    }
}

-(void) setIsGoingOut:(NSNumber *)isGoingOut {
    [self setObject:isGoingOut forKey:kIsGoingOutKey];
}

-(NSNumber *) isGoingOut {
    return [self objectForKey:kIsGoingOutKey];
}

-(void) setIsTapped:(NSNumber *)isTapped {
    NSDate* todayDate = [NSDate date];
    NSString *dayString = [todayDate getDayString];
    NSMutableDictionary *userToTapped = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryTappedList]];
    if (!userToTapped) userToTapped = [[NSMutableDictionary alloc] initWithDictionary:@{ dayString :@{}}];
    NSMutableDictionary *mutableDayDict =  [NSMutableDictionary dictionaryWithDictionary:[userToTapped objectForKey:dayString]];
    [mutableDayDict setObject:isTapped forKey:self.id.stringValue];
    [userToTapped setObject:mutableDayDict forKey:dayString];
    [[NSUserDefaults standardUserDefaults] setObject:userToTapped forKey:kDictionaryTappedList];
}

-(NSNumber *) isTapped {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kDictionaryTappedList];
    NSDate* todayDate = [NSDate date];
    NSString *dayString = [todayDate getDayString];
    NSMutableDictionary *dayTouserToTapped = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryTappedList]];
    for (NSString *key in dayTouserToTapped.allKeys) {
        if (![key isEqual:dayString]) {
            [dayTouserToTapped removeObjectForKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:dayTouserToTapped forKey:kDictionaryTappedList];
    NSDictionary *userToTapped = [dayTouserToTapped objectForKey:dayString];
    if (!userToTapped) return nil;
    if ([userToTapped.allKeys containsObject:self.id.stringValue]) {
        return [userToTapped objectForKey:self.id.stringValue];
    }
    return nil;
}

-(void) setIsFriendRequestRead:(BOOL)isFriendRequestRead {
    NSMutableArray *listOfFriendRequestRead = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryIsFriendRequestList]];
    if (isFriendRequestRead && ![listOfFriendRequestRead containsObject:self.id.stringValue]) [listOfFriendRequestRead addObject:self.id.stringValue];
    [[NSUserDefaults standardUserDefaults] setObject:listOfFriendRequestRead forKey:kDictionaryIsFriendRequestList];
}

-(BOOL) isFriendRequestRead {
    NSArray *listOfFriendRequestRead = [[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryIsFriendRequestList];
    return [listOfFriendRequestRead containsObject:self.id.stringValue];
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

-(NSNumber *)numMutualFriends {
    if ([self objectForKey:kNumMutualFriends]) {
        return [self objectForKey:kNumMutualFriends];
    }
    return nil;
}

-(void)setNumMutualFriends:(NSNumber *)numMutualFriends {
    [self setObject:numMutualFriends forKey:kNumMutualFriends];
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


-(State) state {
    if (self.isCurrentUser) {
        return CURRENT_USER_STATE;
    }
    if (self.isBlocked.boolValue) return BLOCKED_USER_STATE;
    if (self.isFriend.boolValue) return FRIEND_USER_STATE;
    
    if ([self.friendRequest isEqual:kFriendRequestSent] ||
        [self.friendRequest isEqual:kFriendRequestReceived]) {
        return SENT_OR_RECEIVED_REQUEST_USER_STATE;
    }
   
    return NOT_FRIEND_STATE;
}

-(void) followUser {
    if (self.isBlocked.boolValue) {
        self.isBlocked = @NO;
        [WGProfile.currentUser unblock:self withHandler:^(BOOL success, NSError *error) {
            if (error) [[WGError sharedInstance] logError:error forAction:WGActionDelete];
        }];
        return;
    }
    if (self.isFriend.boolValue) {
        self.isFriend = @NO;
        [WGProfile.currentUser unfollow:self withHandler:^(BOOL success, NSError *error) {
            if (error) [[WGError sharedInstance] logError:error forAction:WGActionDelete];
        }];
        return;
    }
    
    
    self.friendRequest = kFriendRequestSent;
    [WGProfile.currentUser friendUser:self withHandler:^(BOOL success, NSError *error) {
        if (error) [[WGError sharedInstance] logError:error forAction:WGActionDelete];
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

-(void) getNumMutualFriends:(WGNumResultBlock)handler {
    __weak typeof(self) weakSelf = self;
    if ([WGProfile.currentUser.id isEqual:self.id]) return;
    [WGApi get:[NSString stringWithFormat:@"users/%@/friends/common/%@/count/", WGProfile.currentUser.id, self.id]
   withHandler:^(NSDictionary *jsonResponse, NSError *error) {
       if (error) {
           handler(nil, error);
           return;
       }
       __strong typeof(weakSelf) strongSelf = weakSelf;
       NSNumber *numberOfFriends = [jsonResponse objectForKey:@"count"];
       strongSelf.numMutualFriends = numberOfFriends;
       handler(numberOfFriends, error);
}];
}

-(void) getMeta:(BoolResultBlock)handler {
    [WGApi get:[NSString stringWithFormat:@"users/%@/meta/", self.id]
   withHandler:^(NSDictionary *jsonResponse, NSError *error) {
       if (error) {
           handler(NO, error);
           return;
       }
       for (NSString *key in jsonResponse) {
           if ([key isEqual:@"is_tapped"]) {
               BOOL isTapped = [[jsonResponse objectForKey:key] boolValue];
               [self setIsTapped:[NSNumber numberWithBool:isTapped]];
           }
           else {
               [self setObject:[jsonResponse objectForKey:key] forKey:key];
           }
       }
       handler(YES, nil);
   }];
}

-(void) getMutualFriends:(WGCollectionResultBlock)handler {
    [WGApi get:[NSString stringWithFormat:@"users/%@/friends/common/%@", WGProfile.currentUser.id, self.id]
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

-(void) getNotMeForMessage:(WGCollectionResultBlock)handler {
    [WGApi get:@"users/me/friends/"  withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
    [WGApi get:@"users/me/friends/" withArguments:@{ @"text" : query , @"context": contextString} andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
    [WGApi get:@"users/me/friends/" withArguments:@{ @"text" : query } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

- (void)getFriends:(WGCollectionResultBlock)handler {
    [WGApi get:[NSString stringWithFormat:@"users/%@/friends/", self.id]
   withHandler:^(NSDictionary *jsonResponse, NSError *error) {
       if (error) {
           handler(nil, error);
           return;
       }
       NSError *dataError;
       WGCollection *objects;
       NSDictionary *response;
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
    [WGApi get:[NSString stringWithFormat:@"users/%@/friends/requests/", self.id]
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
    [WGApi get:@"users/" withArguments:@{ @"text" : query} andHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
//    [user saveKey:kIsFollowingKey withValue:@NO andHandler:^(BOOL success, NSError *error) {
//        handler(error == nil, error);
//    }];
}

-(void) friendUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    [WGApi post:[NSString stringWithFormat:@"users/me/friends/"] withParameters:@{ @"friend_id": user.id} andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            user.isFriendRequestRead = kFriendRequestSent;
        }
        handler(error == nil, error);
    }];

}

-(void) acceptFriendRequestFromUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    if (!user.id) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi post:@"users/me/friends/" withParameters:@{ @"friend_id" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            self.numFriends = @([self.numFriends intValue] + 1);
        }
        handler(error == nil, error);
    }];
}

-(void) rejectFriendRequestForUser:(WGUser *)user withHandler:(BoolResultBlock)handler {
    if (!user.id) {
        return handler(NO, [NSError errorWithDomain:@"WGUser" code:100 userInfo:@{ NSLocalizedDescriptionKey : @"missing key" }]);
    }
    [WGApi delete:@"users/me/friends/" withArguments:@{ @"friend_id" : user.id } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
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
    [WGApi post:[NSString stringWithFormat:@"events/%@/attendees/", event.id] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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
    [WGApi get:[NSString stringWithFormat:@"conversations/%@/", self.id]
   withHandler:^(NSDictionary *jsonResponse, NSError *error) {
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

#pragma mark - Meta objects


@end
