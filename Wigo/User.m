
//
//  User.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "User.h"
#import "Profile.h"
#import <Parse/Parse.h>
#import "LocalyticsSession.h"
#import "Time.h"
#import "EventAnalytics.h"
#import "NSMutableDictionary+NotOverwrite.h"


@implementation User
{
    NSMutableDictionary* _proxy;
    NSMutableArray* modifiedKeys;
}

#pragma mark - NSMutableDictionary functions

- (id)initWithDictionary:(NSDictionary *)otherDictionary {
    self = [super init];
    if (self) {
        _proxy = [NSMutableDictionary dictionaryWithDictionary:otherDictionary];
        modifiedKeys = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id) init {
    if (self = [super init]) {
        _proxy = [[NSMutableDictionary alloc] init];
        modifiedKeys = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) setObject:(id)obj forKey:(id)key {
    if (obj) {
        [_proxy notNillsetObject:obj forKey:key];
        [modifiedKeys addObject:key];
    } else {
        [_proxy removeObjectForKey:key];
    }
}

- (void)removeObjectForKey:(id)aKey
{
    [_proxy removeObjectForKey:aKey];
}

- (NSUInteger)count
{
    return [_proxy count];
}

- (id)objectForKey:(id)aKey
{
    return [_proxy objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [_proxy objectEnumerator];
}

- (NSArray *)allKeys {
    return [_proxy allKeys];
}

- (NSString *)description {
    return [_proxy description];
}

- (BOOL)isEqualToUser:(User *)otherUser {
    if ([[_proxy objectForKey:@"id"] isEqualToNumber:[otherUser objectForKey:@"id"]]) {
        return YES;
    }
    return NO;
}

- (NSDictionary *)dictionary {
    return _proxy;
}

#pragma mark - Properties shortcuts
- (NSString *)email {
    return (NSString *)[_proxy objectForKey:@"email"];
}

- (void)setEmail:(NSString *)email {
    [_proxy notNillsetObject:email forKey:@"email"];
    [modifiedKeys addObject:@"email"];
}

- (NSString *)accessToken {
    return (NSString *)[_proxy objectForKey:@"accessToken"];
}

- (void)setAccessToken:(NSString *)accessToken {
    [_proxy notNillsetObject:accessToken forKey:@"accessToken"];
    [modifiedKeys addObject:@"accessToken"];
}

- (NSString *)key {
    return (NSString *)[_proxy objectForKey:@"key"];
}

- (void)setKey:(NSString *)key {
    [_proxy notNillsetObject:key forKey:@"key"];
    [modifiedKeys addObject:@"key"];
}


- (NSString *)firstName {
    if ([[_proxy allKeys] containsObject:@"first_name"]) {
        return [_proxy objectForKey:@"first_name"];
    }
    else return @"";
}

- (void)setFirstName:(NSString *)name {
    [_proxy notNillsetValue:name forKey:@"first_name"];
    [modifiedKeys addObject:@"first_name"];
}

- (NSString *)lastName {
    if ([[_proxy allKeys] containsObject:@"last_name"]) {
        return [_proxy objectForKey:@"last_name"];
    }
    else return @"";
}

- (void)setLastName:(NSString *)lastName {
    [_proxy notNillsetValue:lastName forKey:@"last_name"];
    [modifiedKeys addObject:@"last_name"];
}


- (NSString *)coverImageURL {
    NSArray *imagesURL = [self imagesURL];
    if ([imagesURL count] > 0 && [imagesURL isKindOfClass:[NSArray class]]) {
        return [imagesURL objectAtIndex:0];
    }
    return @"";
}

- (NSDictionary *)coverImageArea {
    NSArray *imagesArea = [self imagesArea];
    if ([imagesArea count] > 0 && [imagesArea isKindOfClass:[NSArray class]]) {
        NSDictionary *imageArea = [imagesArea objectAtIndex:0];
        return imageArea;

    }
    return [[NSDictionary alloc] init];
}

- (void)setImagesURL:(NSArray *)images {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties notNillsetObject:images forKey:@"images"];
    [_proxy notNillsetObject:[NSDictionary dictionaryWithDictionary:properties] forKey:@"properties"];
    [modifiedKeys addObject:@"properties"];
}

- (NSArray *)imagesURL {
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    if ([properties isKindOfClass:[NSDictionary class]] && [[properties allKeys] containsObject:@"images"]) {
        NSArray *images = [properties objectForKey:@"images"];
        return [images valueForKey:@"url"];
    }
    return [[NSArray alloc] init];
}

- (NSArray *)images {
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    if ([properties isKindOfClass:[NSDictionary class]] && [[properties allKeys] containsObject:@"images"]) {
        NSArray *images = [properties objectForKey:@"images"];
        return images;
    }
    return [[NSArray alloc] init];
}


- (void)addImageURL:(NSString *)imageURL {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self images]];
    if ([imagesArray count] < 5) {
        [imagesArray addObject:@{@"url": imageURL}];
        [self setImagesURL:[NSArray arrayWithArray:imagesArray]];
    }
}

- (NSString *)removeImageURL:(NSString *)imageURL {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self imagesURL]];
    if ([imagesArray count] > 3) {
        [imagesArray removeObject:imageURL];
        [self setImagesURL:[NSArray arrayWithArray:imagesArray]];
        return @"Deleted";
    }
    return @"Error";
}

- (void)makeImageURLCover:(NSString *)imageURL {
    NSMutableArray *imageMutableArrayURL = [[NSMutableArray alloc] initWithArray:[self imagesURL]];
    int indexOfCover = (int)[imageMutableArrayURL indexOfObject:imageURL];
    [imageMutableArrayURL exchangeObjectAtIndex:indexOfCover withObjectAtIndex:0];
    [self setImagesURL:[NSArray arrayWithArray:imageMutableArrayURL]];
}

- (void)setImagesArea:(NSArray *)imagesArea {
    NSMutableArray *imagesMutableArray = [[NSMutableArray alloc] initWithArray:[self images]];

    for (int j = 0; j < [[self images] count]; j++ ) {
        NSDictionary *imageArea = [imagesArea objectAtIndex:j];
        NSMutableDictionary *imageMutableDictionary = [NSMutableDictionary dictionaryWithDictionary:[imagesMutableArray objectAtIndex:j]];
        [imageMutableDictionary notNillsetObject:imageArea forKey:@"crop"];
        [imagesMutableArray setObject:imageMutableDictionary atIndexedSubscript:j];
    }
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties notNillsetObject:[NSArray arrayWithArray:imagesMutableArray] forKey:@"images"];
    [_proxy notNillsetObject:[NSDictionary dictionaryWithDictionary:properties] forKey:@"properties"];
    [modifiedKeys addObject:@"properties"];
}

- (BOOL)addImageArea:(CGRect)imageArea {
    NSMutableArray *imagesAreaArray = [[NSMutableArray alloc] initWithArray:[self imagesArea]];
    for (int i = 0 ; i < [[self imagesArea] count]; i++) {
        NSDictionary *imagesArea = [imagesAreaArray objectAtIndex:i];
        if ([imagesArea isKindOfClass:[NSNull class]])
            [imagesAreaArray setObject: @{@"x": @0, @"y": @0 ,@"width": @0, @"height": @0} atIndexedSubscript:i];
    }
    NSDictionary *areaDictionary = @{@"x": @((int)roundf(imageArea.origin.x)), @"y": @((int)roundf(imageArea.origin.y)) ,@"width": @((int)roundf(imageArea.size.width)), @"height": @((int)roundf(imageArea.size.height))};
    [imagesAreaArray setObject:areaDictionary atIndexedSubscript:([imagesAreaArray count] - 1)];
    [self setImagesArea:imagesAreaArray];
    return YES;
}

- (NSArray *)imagesArea {
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    if ([properties isKindOfClass:[NSDictionary class]] && [[properties allKeys] containsObject:@"images"]) {
        NSArray *images = [properties objectForKey:@"images"];
        return [images valueForKey:@"crop"];
    }
    else return [[NSArray alloc] init];
}

- (void)addImageWithURL:(NSString *)imageURL andArea:(CGRect)area {
    [self addImageURL:imageURL];
    [self addImageArea:area];
}

- (NSNumber *)eventID {
    return [_proxy objectForKey:@"eventID"] ;
}

- (void)setEventID:(NSNumber *)eventID {
    [_proxy notNillsetObject:eventID forKey:@"eventID"];
    [modifiedKeys addObject:@"eventID"];
    [self setIsAttending:YES];
    [self setAttendingEventID:eventID];
}

- (NSString *)groupName {
    return [[_proxy objectForKey:@"group"] objectForKey:@"name"];
}

- (void)setGroupName:(NSString *)groupName {
    [[_proxy objectForKey:@"group"] notNillsetObject:groupName forKey:@"name"];
    [modifiedKeys addObject:@"group"];
}

- (NSNumber *)numberOfGroupMembers {
    return [[_proxy objectForKey:@"group"] objectForKey:@"num_members"];
}

- (void)setNumberOfGroupMembers:(NSNumber *)numberOfGroupMembers {
    [[_proxy objectForKey:@"group"] notNillsetObject:numberOfGroupMembers forKey:@"num_members"];
    [modifiedKeys addObject:@"group"];
}

- (NSNumber *)numberOfFollowing {
    NSNumber *following = (NSNumber *)[_proxy objectForKey:@"num_following"];
    if (following == nil) {
        return @-1;
    } else {
        return following;
    }
}

- (NSNumber *)numberOfFollowers {
    NSNumber *followers = (NSNumber *)[_proxy objectForKey:@"num_followers"];
    if (followers == nil) {
        return @-1;
    } else {
        return followers;
    }
}


- (NSString *)bioString {
    if ([_proxy objectForKey:@"bio"] != (id)[NSNull null]) {
        return [_proxy objectForKey:@"bio"];
    }
    return [self randomBioGenerator];
}

- (void)setBioString:(NSString *)bioString {
    [_proxy notNillsetObject:bioString forKey:@"bio"];
    [modifiedKeys addObject:@"bio"];
}

- (BOOL)isPrivate {
    return [[_proxy objectForKey:@"privacy"] isEqualToString:@"private"];
}

- (void)setIsPrivate:(BOOL)isPrivate {
    if (isPrivate) {
        [_proxy notNillsetObject:@"private" forKey:@"privacy"];
    }
    else [_proxy notNillsetObject:@"public" forKey:@"privacy"];
    [modifiedKeys addObject:@"privacy"];
}


- (NSString *)randomBioGenerator {
    NSArray *randomStrings = @[
                               @"WiGo takes my FOMO to a whole new level",
                               @"Tap tap - who's there?",
                               @"I go, you go, WiGo",
                               @"Too busy partying to fill out my bio",
                               @"I go hard",
                               @"Do you even WiGo, bro?",
                               @"Where are WiGoing tonight?",
                               @"If I tap you, put it on your resume",
                               @"Tap me",
                               @"I set my alarm for 6am every day so I'm the first one going out on WiGo",
                               @"If I don't tap you back, take the hint"
                               ];
    return [randomStrings objectAtIndex:(arc4random() % [randomStrings count])];
}

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@", [self firstName], [self lastName]];
}

- (BOOL)isGoingOut {
    if ([[_proxy allKeys] containsObject:@"is_goingout"]) {
        NSNumber *goingOutNumber = (NSNumber *)[_proxy objectForKey:@"is_goingout"];
        return [goingOutNumber boolValue];
    }
    return NO;
}

- (void)setIsGoingOut:(BOOL)isGoingOut {
    if ([[_proxy allKeys] containsObject:@"is_goingout"]) {
        BOOL existing = self.isGoingOut;
        if (isGoingOut & !existing) {
            [EventAnalytics tagEvent:@"Go Out"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"goingOutForRateApp" object:nil];
        }
        else if (! isGoingOut & existing) [EventAnalytics tagEvent:@"Ungo Out"];
    }

    if (!isGoingOut) [self setIsAttending:NO];
    [_proxy notNillsetObject:[NSNumber numberWithBool:isGoingOut] forKey:@"is_goingout"];
    [modifiedKeys addObject:@"is_goingout"];
}

- (BOOL)emailValidated {
    NSNumber *emailValidatedNumber = (NSNumber *)[_proxy objectForKey:@"email_validated"];
    return [emailValidatedNumber boolValue];
}

- (void)setEmailValidated:(BOOL)emailValidated {
    [_proxy notNillsetObject:[NSNumber numberWithBool:emailValidated] forKey:@"email_validated"];
    [modifiedKeys addObject:@"email_validated"];
}

- (BOOL)isTapped {
    return [(NSNumber *)[_proxy objectForKey:@"is_tapped"] boolValue];
}

- (void)setIsTapped:(BOOL)isTapped {
    NSNumber *numberIsFollowingRequested = [NSNumber numberWithBool:isTapped];
    [_proxy notNillsetObject:numberIsFollowingRequested forKey:@"is_tapped"];
}

- (BOOL)isTapPushNotificationEnabled {
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    if ([properties isKindOfClass:[NSDictionary class]] && [[properties allKeys] containsObject:@"notifications"]) {
        NSMutableDictionary *notifications = [properties objectForKey:@"notifications"];
        if ([[notifications allKeys] containsObject:@"taps"]) {
            return [(NSNumber *)[notifications objectForKey:@"taps"] boolValue];
        }
    }
    return YES;
}

- (void)setIsTapPushNotificationEnabled:(BOOL)isTapPushNotificationEnabled {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:[_proxy objectForKey:@"properties"]];
    if ([properties isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *notifications;
        if ([[properties allKeys] containsObject:@"notifications"]) {
            notifications = [[NSMutableDictionary alloc] initWithDictionary:[properties objectForKey:@"notifications"]];
            [notifications notNillsetObject:[NSNumber numberWithBool:isTapPushNotificationEnabled ] forKey:@"taps"];
        }
        else {
            notifications = [[NSMutableDictionary alloc] initWithCapacity:1];
            [notifications notNillsetObject:[NSNumber numberWithBool:isTapPushNotificationEnabled ] forKey:@"taps"];
        }
        [properties notNillsetObject:notifications forKey:@"notifications"];
        [_proxy notNillsetObject:properties forKey:@"properties"];
    }
}

- (BOOL)isFavoritesGoingOutNotificationEnabled {
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    if ([properties isKindOfClass:[NSDictionary class]] && [[properties allKeys] containsObject:@"notifications"]) {
        NSMutableDictionary *notifications = [properties objectForKey:@"notifications"];
        if ([[notifications allKeys] containsObject:@"favorites_going_out"]) {
            return [(NSNumber *)[notifications objectForKey:@"favorites_going_out"] boolValue];
        }
    }
    return YES;
}

- (void)setIsFavoritesGoingOutNotificationEnabled:(BOOL)isFavoritesGoingOutNotificationEnabled {
    NSMutableDictionary *properties =  [[NSMutableDictionary alloc] initWithDictionary:[_proxy objectForKey:@"properties"]];
    if ([properties isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *notifications;
        if ([[properties allKeys] containsObject:@"notifications"]) {
            notifications = [[NSMutableDictionary alloc] initWithDictionary:[properties objectForKey:@"notifications"]];
            [notifications notNillsetObject:[NSNumber numberWithBool:isFavoritesGoingOutNotificationEnabled ] forKey:@"favorites_going_out"];
        }
        else {
            notifications = [[NSMutableDictionary alloc] initWithCapacity:1];
            [notifications notNillsetObject:[NSNumber numberWithBool:isFavoritesGoingOutNotificationEnabled ] forKey:@"favorites_going_out"];
        }
        [properties notNillsetObject:notifications forKey:@"notifications"];
        [_proxy notNillsetObject:properties forKey:@"properties"];
    }
}

- (BOOL)isFavorite {
    NSNumber *favoriteNumber = (NSNumber *)[_proxy objectForKey:@"is_favorite"];
    return [favoriteNumber boolValue];
}

- (void)setIsFavorite:(BOOL)isFavorite {
    [_proxy notNillsetObject:[NSNumber numberWithBool:isFavorite] forKey:@"is_favorite"];
    [modifiedKeys addObject:@"is_favorite"];
}

- (BOOL)isFollowing {
    NSNumber *followingNumber = (NSNumber *)[_proxy objectForKey:@"is_following"];
    return [followingNumber boolValue];
}

- (void)setIsFollowing:(BOOL)isFollowing {
    [_proxy notNillsetObject:[NSNumber numberWithBool:isFollowing] forKey:@"is_following"];
    [modifiedKeys addObject:@"is_following"];
}

- (BOOL)isAttending {
    if (![self isGoingOut]) return NO;
    NSDictionary *isAttending = (NSDictionary *)[_proxy objectForKey:@"is_attending"];
    if ([isAttending isKindOfClass:[NSDictionary class]]) return YES;
    else return NO;
}

- (void)setIsAttending:(BOOL)isAttending {
    if (isAttending == NO) {
        [_proxy removeObjectForKey:@"is_attending"];
    }
    else [_proxy notNillsetObject:[[NSDictionary alloc] init] forKey:@"is_attending"];
}

- (BOOL)isGroupLocked {
    if ([[_proxy allKeys] containsObject:@"group"]) {
        NSNumber *isGroupLocked = (NSNumber *)[[_proxy objectForKey:@"group"]  objectForKey:@"locked"];
        return [isGroupLocked boolValue];
    }
    return NO;
}

- (BOOL)isBlocked {
    NSNumber *blockedNumber = (NSNumber *)[_proxy objectForKey:@"is_blocked"];
    return [blockedNumber boolValue];
}

- (void)setIsBlocked:(BOOL)isBlocked {
    [_proxy notNillsetObject:[NSNumber numberWithBool:isBlocked] forKey:@"is_blocked"];
    [modifiedKeys addObject:@"is_following"];
}

- (NSString *)attendingEventName {
    if ([self isAttending]) {
        NSDictionary *isAttending = (NSDictionary *)[_proxy objectForKey:@"is_attending"];
        return [isAttending objectForKey:@"name"];
    }
    return @"";
}

- (void)setAttendingEventName:(NSString *)attendingEventName {
    if (attendingEventName != nil) {
        if ([self isAttending]) {
            NSMutableDictionary *isAttending = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[_proxy objectForKey:@"is_attending"]];
            [isAttending notNillsetObject:attendingEventName forKey:@"name"];
            [_proxy notNillsetObject:[NSDictionary dictionaryWithDictionary:isAttending] forKey:@"is_attending"];
        }
    }
}

- (NSNumber *)attendingEventID {
    if ([self isAttending]) {
        NSDictionary *isAttending = (NSDictionary *)[_proxy objectForKey:@"is_attending"];
        return [isAttending objectForKey:@"id"];
    }
    return @0;
}

- (void)setAttendingEventID:(NSNumber *)attendingEventID {
    if (attendingEventID != nil) {
        if ([self isAttending]) {
            NSMutableDictionary *isAttending = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[_proxy objectForKey:@"is_attending"]];
            [isAttending notNillsetObject:attendingEventID forKey:@"id"];
            [_proxy notNillsetObject:[NSDictionary dictionaryWithDictionary:isAttending] forKey:@"is_attending"];
        }
    }
}

- (NSNumber *)lastMessageRead {
    return (NSNumber *)[_proxy objectForKey:@"last_message_read"];
}

- (void)setLastMessageRead:(NSNumber *)lastMessageRead {
    [_proxy notNillsetObject:lastMessageRead forKey:@"last_message_read"];
    [modifiedKeys addObject:@"last_message_read"];
}

- (NSNumber *)lastNotificationRead {
    return (NSNumber *)[_proxy objectForKey:@"last_notification_read"];
}

- (void)setLastUserRead:(NSNumber *)lastUserRead {
    if ([[_proxy allKeys] containsObject:@"last_user_read"]) {
        [_proxy notNillsetObject:lastUserRead forKey:@"last_user_read"];
        [modifiedKeys addObject:@"last_user_read"];
    }
}

- (NSNumber *)lastUserRead {
    if ([[_proxy allKeys] containsObject:@"last_user_read"]) return (NSNumber *)[_proxy objectForKey:@"last_user_read"];
    else return @0;
}

- (void)setLastNotificationRead:(NSNumber *)lastNotificationRead {
    [_proxy notNillsetObject:lastNotificationRead forKey:@"last_notification_read"];
    [modifiedKeys addObject:@"last_notification_read"];
}


- (BOOL)isFollowingRequested {
    if ([[_proxy allKeys] containsObject:@"is_following_requested"]) {
        NSNumber *isFollowingRequestedNumber = (NSNumber *)[_proxy objectForKey:@"is_following_requested"];
        return [isFollowingRequestedNumber boolValue];
    }
    return NO;
}

- (void)setIsFollowingRequested:(BOOL)isFollowingRequested {
    NSNumber *numberIsFollowingRequested = [NSNumber numberWithBool:isFollowingRequested];
    [_proxy notNillsetObject:numberIsFollowingRequested forKey:@"is_following_requested"];
}

- (STATE)getUserState {
    if ([self isBlocked]) {
        return BLOCKED_USER;
    }
    if ([self isPrivate]) {
        if ([self isFollowing]) {
            if ([self isAttending]) return ATTENDING_EVENT_ACCEPTED_PRIVATE_USER;
            return FOLLOWING_USER;
        }
        else if ([self isFollowingRequested]) {
            return NOT_YET_ACCEPTED_PRIVATE_USER;
        }
        else return NOT_SENT_FOLLOWING_PRIVATE_USER;
    }
    if ([self isFollowing]) {
        if ([self isAttending]) return ATTENDING_EVENT_FOLLOWING_USER;
        return FOLLOWING_USER;
    }
    else return NOT_FOLLOWING_PUBLIC_USER;
}

- (NSString *)joinedDate {
    NSString *utcCreation = [_proxy objectForKey:@"created"];
    return [Time getLocalDateJoinedFromUTCTimeString:utcCreation];
}

#pragma mark - Saving data
- (NSString *)login {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"login"];
    [query setValue:[self objectForKey:@"facebook_id"] forKey:@"facebook_id"];
    [query setValue:[self accessToken] forKey:@"facebook_access_token"];
    [query setValue:self.email forKey:@"email"];
    NSDictionary *dictionaryUser = [query sendPOSTRequest];
    if (dictionaryUser == nil) {
        return @"error";
    }
    if ([[dictionaryUser allKeys] containsObject:@"code"]) {
        if ([[dictionaryUser objectForKey:@"code"] isEqualToString:@"invalid_email"]) {
            return @"invalid_email";
        }
        else if ([[dictionaryUser objectForKey:@"code"] isEqualToString:@"expired_token"]) {
            return @"expired_token";
        }
    }
    if ([[dictionaryUser allKeys] containsObject:@"status"]) {
        if ([[dictionaryUser objectForKey:@"status"] isEqualToString:@"error"]) {
            return @"error";
        }
    }
    if ([[dictionaryUser allKeys] containsObject:@"email_validated"] ) {
        for (NSString *key in [dictionaryUser allKeys]) {
            [self notNillsetValue:[dictionaryUser objectForKey:key] forKey:key];
        }
        NSNumber *emailValidatedNumber = (NSNumber *)[dictionaryUser objectForKey:@"email_validated"];
        if (![emailValidatedNumber boolValue]) {
            return @"email_not_validated";
        }
    }

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"wigo_id"] = [_proxy objectForKey:@"id"];
    [currentInstallation saveInBackground];
    for (NSString *key in [dictionaryUser allKeys]) {
        [self notNillsetValue:[dictionaryUser objectForKey:key] forKey:key];
    }
    [modifiedKeys removeAllObjects];
    return @"logged_in";
}


- (NSString *)signUp {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"register"];
    [query setValue:[self objectForKey:@"facebook_id"] forKey:@"facebook_id"];
    [query setValue:[self accessToken] forKey:@"facebook_access_token"];
    [query setValue:self.email forKey:@"email"];
    if ([[_proxy allKeys] containsObject:@"first_name"]) {
        [query setValue:[self firstName] forKey:@"first_name"];
    }
    if ([[_proxy allKeys] containsObject:@"last_name"]) {
        [query setValue:[self lastName] forKey:@"last_name"];
    }
    if ([[_proxy allKeys] containsObject:@"gender"]) {
        [query setValue:[_proxy objectForKey:@"gender"] forKey:@"gender"];
    }
    NSDictionary *dictionaryUser = [query sendPOSTRequest];
    if (dictionaryUser == nil) {
        return @"no_network";
    }
    if ([[dictionaryUser allKeys] containsObject:@"code"]) {
        if ([[dictionaryUser objectForKey:@"code"] isEqualToString:@"invalid_email"]) {
            return @"invalid _email";
        }
        else if ([[dictionaryUser objectForKey:@"code"] isEqualToString:@"expired_token"]) {
            return @"expired_token";
        }
    }
    if ([[dictionaryUser allKeys] containsObject:@"status"]) {
        if ([[dictionaryUser objectForKey:@"status"] isEqualToString:@"error"]) {
            return @"error";
        }
    }
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"wigo_id"] = [dictionaryUser objectForKey:@"id"];
    [currentInstallation saveInBackground];
    for (NSString *key in [dictionaryUser allKeys]) {
        [self notNillsetValue:[dictionaryUser objectForKey:key] forKey:key];
    }
    [modifiedKeys removeAllObjects];
    return @"signed_up";
}

- (void)save {
    [modifiedKeys removeObject:@"facebook_access_token"];
    [modifiedKeys removeObject:@"facebook_id"];
    [modifiedKeys removeObject:@"email_validated"];
    [modifiedKeys removeObject:@"accessToken"];
    [modifiedKeys removeObject:@"tabNumber"];
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"users/me/"];
    [query setProfileKey:self.key];
    [modifiedKeys removeObject:@"eventID"];
    for (NSString *key in modifiedKeys) {
        [query setValue:[_proxy objectForKey:key] forKey:key];
    }
    NSDictionary *dictionaryUser = [query sendPOSTRequest];
    if  (!(dictionaryUser == nil)) {
        [_proxy addEntriesFromDictionary:dictionaryUser];
        modifiedKeys = [[NSMutableArray alloc] init];
    }
}

- (void)saveKey:(NSString *)key {
    Query *query = [[Query alloc] init];
    NSString *queryString = [NSString stringWithFormat:@"users/%@/", [_proxy objectForKey:@"id"]];
    [query queryWithClassName:queryString];
    [query setProfileKey:[Profile user].key];
    [query setValue:[_proxy objectForKey:key] forKey:key];
    NSDictionary *dictionaryUser = [query sendPOSTRequest];
    [_proxy addEntriesFromDictionary:dictionaryUser];
    [modifiedKeys removeObject:key];
}

- (void)saveKeyAsynchronously:(NSString *)key {
    [self saveKeyAsynchronously:key withHandler:^() {}];
}


- (void)saveKeyAsynchronously:(NSString *)key withHandler:(Handler)handler {
    Query *query = [[Query alloc] init];
    NSString *queryString = [NSString stringWithFormat:@"users/%@/", [_proxy objectForKey:@"id"]];
    [query queryWithClassName:queryString];
    [query setProfileKey:[Profile user].key];
    [query setValue:[_proxy objectForKey:key] forKey:key];
    
    [query sendAsynchronousHTTPMethod:POST withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            [_proxy addEntriesFromDictionary:jsonResponse];
            [modifiedKeys removeObject:key];
        }
        handler();
    }];
}
#pragma mark - Refactoring saving data

- (void)loginWithHandler:(QueryResult)handler {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"login"];
    [query setValue:[self objectForKey:@"facebook_id"] forKey:@"facebook_id"];
    [query setValue:[self accessToken] forKey:@"facebook_access_token"];
    [query setValue:self.email forKey:@"email"];
    [query sendAsynchronousHTTPMethod:POST withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (jsonResponse == nil || error != nil) {
            handler(jsonResponse, error);
        }
        else if ([[jsonResponse allKeys] containsObject:@"code"]) {
            if ([[jsonResponse objectForKey:@"code"] isEqualToString:@"does_not_exist"]) {
                handler(jsonResponse, error);
            }
            else {
                // Code can be invalid_email or expired_token
                handler(nil, [NSError errorWithDomain:@"Server"
                                                 code:100
                                             userInfo:@{NSLocalizedDescriptionKey:[jsonResponse objectForKey:@"code"]}]);
            }
        }
        else {
            if ([[jsonResponse allKeys] containsObject:@"id"]) {
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                currentInstallation[@"wigo_id"] = [jsonResponse objectForKey:@"id"];
                [currentInstallation saveInBackground];
            }
            for (NSString *key in [jsonResponse allKeys]) {
                [self notNillsetValue:[jsonResponse objectForKey:key] forKey:key];
            }
            
            [self updateUserAnalytics];
            
            [modifiedKeys removeAllObjects];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            handler(jsonResponse, error);
        }
    }];
}

- (void) updateUserAnalytics {
    NSString *groupName = self.groupName;
    if (groupName != nil) {
        [EventAnalytics tagGroup:groupName];
    }
    
    NSString *objId = [NSString stringWithFormat:@"%@", [self objectForKey:@"id"]];
    [EventAnalytics tagUser:objId];
}





@end
