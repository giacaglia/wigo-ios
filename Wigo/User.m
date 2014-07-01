//
//  User.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/16/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "User.h"

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
    if ([_proxy objectForKey:@"id"] == [otherUser objectForKey:@"id"]) {
        return YES;
    }
    return NO;
}

#pragma mark - Properties shortcuts
- (NSString *)email {
    return (NSString *)[_proxy objectForKey:@"email"];
}

- (void)setEmail:(NSString *)email {
    [_proxy setObject:email forKey:@"email"];
    [modifiedKeys addObject:@"email"];
}

- (NSString *)key {
    return (NSString *)[_proxy objectForKey:@"key"];
}

- (void)setKey:(NSString *)key {
    [_proxy setObject:key forKey:@"key"];
    [modifiedKeys addObject:@"key"];
}

- (UIImage *)coverImage {
    NSArray *imageArray = [self images];
    if ([imageArray count] > 0) {
        return [imageArray objectAtIndex:0];
    }
    else {
        NSString *pictureURL = [_proxy objectForKey:@"image"];
        NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:pictureURL]];
        return [UIImage imageWithData:imageData];
    }
}

- (void)setCoverImage:(UIImage *)coverImage {
    self.coverImage = coverImage;
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
            [imagesDataArray addObject:imageData];
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

- (NSArray *)images {
    if ([_proxy objectForKey:@"images"] != (id)[NSNull null] && [_proxy objectForKey:@"images"] != nil) {
        return [_proxy objectForKey:@"images"];
    }
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    NSDictionary *imagesDictionary = [properties objectForKey:@"images"];
    NSMutableArray *imagesMutableArray = [[NSMutableArray alloc] initWithCapacity:3];
    for (NSString *key in [imagesDictionary allKeys]) {
        NSString *pictureURL = [imagesDictionary objectForKey:key];
        NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:pictureURL]];
        [imagesMutableArray addObject:[UIImage imageWithData:imageData]];
    }
    NSArray *images = [NSArray arrayWithArray:imagesMutableArray];
    if (images) {
        [_proxy setObject:images forKey:@"images"];
        return images;
    }
    else {
        return @[[self coverImage]];
    }
}

- (void)setImages:(NSArray *)images{
    NSMutableDictionary *imagesDictionary = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [images count]; i++) {
        [imagesDictionary setValue:[images objectAtIndex:i] forKey:[[NSNumber numberWithInt:i] stringValue]];
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties setObject:imagesDictionary forKey:@"images"];
    [_proxy setObject:[NSDictionary dictionaryWithDictionary:properties] forKey:@"properties"];
    [modifiedKeys addObject:@"properties"];
}

- (NSArray *)imagesURL {
    if ([_proxy objectForKey:@"imagesURL"] != (id)[NSNull null] && [_proxy objectForKey:@"imagesURL"] != nil) {
        return [_proxy objectForKey:@"imagesURL"];
    }
    NSDictionary *properties = [_proxy objectForKey:@"properties"];
    NSDictionary *imagesDictionary = [properties objectForKey:@"images"];
    NSMutableArray *imagesMutableArray = [[NSMutableArray alloc] initWithCapacity:3];
    for (NSString *key in [imagesDictionary allKeys]) {
        NSString *pictureURL = [imagesDictionary objectForKey:key];
        [imagesMutableArray addObject:pictureURL];
    }
    NSArray *imagesURLArray = [NSArray arrayWithArray:imagesMutableArray];
    [_proxy setObject:imagesURLArray forKey:@"imagesURL"];
    return imagesURLArray;
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
    NSNumber *goingOutNumber = (NSNumber *)[_proxy objectForKey:@"goingout"];
    return [goingOutNumber boolValue];
}

- (void)setIsGoingOut:(BOOL)isGoingOut {
    [_proxy setObject:[NSNumber numberWithBool:isGoingOut] forKey:@"goingout"];
    [modifiedKeys addObject:@"goingout"];
}

#pragma mark - Saving data
- (NSString *)login {
    Query *query = [[Query alloc] init];
    [query queryWithClassName:@"login"];
    [query setValue:[self objectForKey:@"fbID"] forKey:@"facebook_id"];
    [query setValue:[FBSession activeSession].accessTokenData.accessToken forKey:@"facebook_access_token"];
    [query setValue:self.email forKey:@"email"];
    NSDictionary *dictionaryUser = [query sendPOSTRequest];
    if ([[dictionaryUser objectForKey:@"code"] isEqualToString:@"invalid_email"]) {
        return @"invalid_email";
    }
    NSLog(@"dictionary user %@", dictionaryUser);
    [self setKey:[dictionaryUser objectForKey:@"key"]];
    [modifiedKeys removeObject:@"facebook_access_token"];
    [modifiedKeys removeObject:@"email"];
    [modifiedKeys removeObject:@"first_name"];
    [modifiedKeys removeObject:@"last_name"];
    [modifiedKeys removeObject:@"fbID"];
    [modifiedKeys removeObject:@"key"];

    [self save];
    return @"logged_in";
}

- (void)save {
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


@end
