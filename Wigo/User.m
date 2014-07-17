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
        [_proxy setObject:obj forKey:key];
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
    [_proxy setObject:email forKey:@"email"];
    [modifiedKeys addObject:@"email"];
}

- (NSString *)accessToken {
    return (NSString *)[_proxy objectForKey:@"accessToken"];
}

- (void)setAccessToken:(NSString *)accessToken {
    [_proxy setObject:accessToken forKey:@"accessToken"];
    [modifiedKeys addObject:@"accessToken"];
}

- (NSString *)key {
    return (NSString *)[_proxy objectForKey:@"key"];
}

- (void)setKey:(NSString *)key {
    [_proxy setObject:key forKey:@"key"];
    [modifiedKeys addObject:@"key"];
}


- (NSString *)firstName {
    return [_proxy objectForKey:@"first_name"];
}

- (void)setFirstName:(NSString *)name {
    [_proxy setValue:name forKey:@"first_name"];
    [modifiedKeys addObject:@"first_name"];
}

- (NSString *)lastName {
    return [_proxy objectForKey:@"last_name"];
}

- (void)setLastName:(NSString *)lastName {
    [_proxy setValue:lastName forKey:@"last_name"];
    [modifiedKeys addObject:@"last_name"];
}

- (void)loadImagesWithCallback:(void (^)(NSArray *imagesReturned))callback {
    
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    NSDictionary *imagesDictionary = [properties objectForKey:@"images"];
    NSMutableArray *imagesDataArray = [[NSMutableArray alloc] initWithCapacity:3];
    NSMutableArray *imagesReturned = [[NSMutableArray alloc] initWithCapacity:3];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        for (NSString *key in [imagesDictionary allKeys]) {
            NSString *pictureURL = [imagesDictionary objectForKey:key];
            NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:pictureURL]];
            if (imageData) {
                [imagesDataArray addObject:imageData];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
            for (NSData *imageData in imagesDataArray) {
                [imagesReturned addObject:[UIImage imageWithData:imageData]];
            }
            [_proxy setObject:imagesReturned forKey:@"images"];
            callback([NSArray arrayWithArray:imagesReturned]);
        });
    });
}

- (NSString *)coverImageURL {
    NSArray *imagesURL = [self imagesURL];
    if ([imagesURL count] > 0) {
        return [imagesURL objectAtIndex:0];
    }
    return @"";
}

- (void)setImagesURL:(NSArray *)images {
    NSMutableDictionary *imagesDictionary = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [images count]; i++) {
        [imagesDictionary setValue:[images objectAtIndex:i] forKey:[[NSNumber numberWithInt:i] stringValue]];
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties setObject:imagesDictionary forKey:@"images"];
    [_proxy setObject:[NSDictionary dictionaryWithDictionary:properties] forKey:@"properties"];
    [_proxy setObject:images forKey:@"imagesURL"];
    [modifiedKeys addObject:@"properties"];
}

- (NSArray *)imagesURL {
    NSArray *imagesURLArray = [_proxy objectForKey:@"imagesURL"];
    if ([imagesURLArray isKindOfClass:[NSArray class]]) {
        return imagesURLArray;
    }
    
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    int indexOfCoverImage = 0;
    if ([properties isKindOfClass:[NSDictionary class]] && [[properties allKeys] containsObject:@"images"]) {
        NSDictionary *imagesDictionary = [properties objectForKey:@"images"];
        NSMutableArray *imagesMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
        for (NSString *key in [imagesDictionary allKeys]) {
            NSString *pictureURL = [imagesDictionary objectForKey:key];
            [imagesMutableArray addObject:pictureURL];
            if ([key isEqualToString:@"0"]) {
                indexOfCoverImage = [imagesMutableArray count] - 1;
            }
        }
        [imagesMutableArray exchangeObjectAtIndex:indexOfCoverImage withObjectAtIndex:0];
        NSArray *imagesURLArray = [NSArray arrayWithArray:imagesMutableArray];
        [_proxy setObject:imagesURLArray forKey:@"imagesURL"];
        return imagesURLArray;
    }
    return [[NSArray alloc] init];
}

- (void)addImageURL:(NSString *)imageURL {
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithArray:[self imagesURL]];
    if ([imagesArray count] < 5) {
        [imagesArray addObject:imageURL];
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
    int indexOfCover = [imageMutableArrayURL indexOfObject:imageURL];
    [imageMutableArrayURL exchangeObjectAtIndex:indexOfCover withObjectAtIndex:0];
    [self setImagesURL:[NSArray arrayWithArray:imageMutableArrayURL]];
}

- (NSNumber *)eventID {
    return [_proxy objectForKey:@"eventID"] ;
}

- (void)setEventID:(NSNumber *)eventID {
    [_proxy setObject:eventID forKey:@"eventID"];
    [modifiedKeys addObject:@"eventID"];

}

- (NSString *)groupName {
    return [[_proxy objectForKey:@"group"] objectForKey:@"name"];
}

- (void)setGroupName:(NSString *)groupName {
    [[_proxy objectForKey:@"group"] setObject:groupName forKey:@"name"];
    [modifiedKeys addObject:@"group"];
}

- (NSString *)bioString {
    if ([_proxy objectForKey:@"bio"] != (id)[NSNull null]) {
        return [_proxy objectForKey:@"bio"];
    }
    return [self randomBioGenerator];
}

- (void)setBioString:(NSString *)bioString {
    [_proxy setObject:bioString forKey:@"bio"];
    [modifiedKeys addObject:@"bio"];
}

- (BOOL)private {
    return [[_proxy objectForKey:@"privacy"] isEqualToString:@"private"];
}

- (void)setPrivate:(BOOL)private {
    if (private) {
        [_proxy setObject:@"private" forKey:@"privacy"];
    }
    [_proxy setObject:@"public" forKey:@"privacy"];
    [modifiedKeys addObject:@"privacy"];
}

- (NSString *)randomBioGenerator {
    NSArray *randomStrings = @[
                               @"I'm too drunk to taste this chicken",
                               @"I'm too busy partying to fill out my bio",
                               @"I'm too busy tapping others to pay mind to my profile",
                               @"I'd fill out my profile but I don't have any fingers",
                               @"I'm a robot",
                               @"This is my bio, there are many like it, but this one is mine. My bio is my friend. My bio cares for me like no man can. PS: I am hot!"
                               ];
    return [randomStrings objectAtIndex:(arc4random() % [randomStrings count])];
}

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@", [_proxy objectForKey:@"first_name"], [_proxy objectForKey:@"last_name"]];
}

- (BOOL)isGoingOut {
    NSNumber *goingOutNumber = (NSNumber *)[_proxy objectForKey:@"is_goingout"];
    return [goingOutNumber boolValue];
}

- (void)setIsGoingOut:(BOOL)isGoingOut {
    [_proxy setObject:[NSNumber numberWithBool:isGoingOut] forKey:@"is_goingout"];
    [modifiedKeys addObject:@"is_goingout"];
}

- (BOOL)emailValidated {
    NSNumber *emailValidatedNumber = (NSNumber *)[_proxy objectForKey:@"email_validated"];
    return [emailValidatedNumber boolValue];
}

- (void)setEmailValidated:(BOOL)emailValidated {
    [_proxy setObject:[NSNumber numberWithBool:emailValidated] forKey:@"email_validated"];
    [modifiedKeys addObject:@"email_validated"];
}

- (BOOL)isTapped {
    return [(NSNumber *)[_proxy objectForKey:@"is_tapped"] boolValue];
}

- (BOOL)isFavorite {
    NSNumber *favoriteNumber = (NSNumber *)[_proxy objectForKey:@"is_favorite"];
    return [favoriteNumber boolValue];
}

- (void)setIsFavorite:(BOOL)isFavorite {
    [_proxy setObject:[NSNumber numberWithBool:isFavorite] forKey:@"is_favorite"];
    [modifiedKeys addObject:@"is_favorite"];
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
//        NSLog(@"dictionary user %@", dictionaryUser);
        for (NSString *key in [dictionaryUser allKeys]) {
            [self setValue:[dictionaryUser objectForKey:key] forKey:key];
        }
        NSNumber *emailValidatedNumber = (NSNumber *)[dictionaryUser objectForKey:@"email_validated"];
        if (![emailValidatedNumber boolValue]) {
            return @"email_not_validated";
        }
    }

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"wigo_id"] = [_proxy objectForKey:@"id"];
    [currentInstallation saveInBackground];
//    NSLog(@"dictionary user %@", dictionaryUser);
    for (NSString *key in [dictionaryUser allKeys]) {
        [self setValue:[dictionaryUser objectForKey:key] forKey:key];
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
    NSDictionary *dictionaryUser = [query sendPOSTRequest];
//    NSLog(@"dictionary User %@", dictionaryUser);
    if (dictionaryUser == nil) {
        return @"no_network";
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
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"wigo_id"] = [dictionaryUser objectForKey:@"id"];
    [currentInstallation saveInBackground];
    for (NSString *key in [dictionaryUser allKeys]) {
        [self setValue:[dictionaryUser objectForKey:key] forKey:key];
    }
    [modifiedKeys removeAllObjects];
    return @"signed_up";
}

- (void)save {
    [modifiedKeys removeObject:@"facebook_access_token"];
    [modifiedKeys removeObject:@"facebook_id"];
    [modifiedKeys removeObject:@"email_validated"];
    [modifiedKeys removeObject:@"accessToken"];
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



@end
