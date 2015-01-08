//
//  WGProfile.m
//  Wigo
//
//  Created by Adam Eagle on 1/3/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGProfile.h"

#define kKeyKey @"key"
#define kSchoolStatisticsKey @"school_statistics"
#define kGoogleAnalyticsEnabledKey @"googleAnalyticsEnabled"
#define kCanFetchAppStartupKey @"canFetchAppStartup"
#define kTriedToRegisterKey @"triedToRegister"
#define kDatesAccessedKey @"datesAccessed"
#define kShowSchoolStatistics @"school_statistics"
#define kChosenPeople @"chosenPeople"
#define kNumberOfTimesWentOut @"numberOfTimesWentOut"
#define kAWSKeyKey @"awsKey"
#define kCDNPrefix @"cdnPrefix"
#define kShowedOnboardView @"showedOnboardView"
#define kFacebookAccessTokenKey @"facebook_access_token"
#define kAccessToken @"accessToken"
#define kFacebookIdKey @"facebook_id"
#define kLastNotificationReadKey @"last_notification_read"

#define kDefaultCDNPrefix @"wigo-uploads.s3.amazonaws.com"

static WGProfile *currentUser = nil;

@implementation WGProfile

-(id) init {
    self = [super init];
    if (self) {
        self.className = @"user";
        
        [[NSUserDefaults standardUserDefaults] setObject:self.key forKey:kKeyKey];
        [[NSUserDefaults standardUserDefaults] setObject:self.facebookId forKey:kFacebookIdKey];
        [[NSUserDefaults standardUserDefaults] setObject:self.facebookAccessToken forKey:kFacebookAccessTokenKey];
    }
    return self;
}

-(id) initWithJSON:(NSDictionary *)json {
    self = [super initWithJSON:json];
    if (self) {
        self.className = @"user";
        
        [[NSUserDefaults standardUserDefaults] setObject:self.key forKey:kKeyKey];
        [[NSUserDefaults standardUserDefaults] setObject:self.facebookId forKey:kFacebookIdKey];
        [[NSUserDefaults standardUserDefaults] setObject:self.facebookAccessToken forKey:kFacebookAccessTokenKey];
    }
    return self;
}

+(void) setCurrentUser:(WGUser *)user {
    currentUser = [[WGProfile alloc] initWithJSON:[user deserialize]];
}

+(WGProfile *) currentUser {
    if (!currentUser) {
        currentUser = [[WGProfile alloc] init];
    }
    return currentUser;
}

-(void) setKey:(NSString *)key {
    [self setObject:key forKey:kKeyKey];
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:kKeyKey];
}

-(NSString *) key {
    if ([self objectForKey:kKeyKey]) {
        return [self objectForKey:kKeyKey];
    }
    return [[NSUserDefaults standardUserDefaults] objectForKey:kKeyKey];
}

-(void) setFacebookId:(NSString *)facebookId {
    [self setObject:facebookId forKey:kFacebookIdKey];
    [[NSUserDefaults standardUserDefaults] setObject:facebookId forKey:kFacebookIdKey];
}

-(NSString *) facebookId {
    if ([self objectForKey:kFacebookIdKey]) {
        return [self objectForKey:kFacebookIdKey];
    }
    return [[NSUserDefaults standardUserDefaults] objectForKey:kFacebookIdKey];
}

-(void) setFacebookAccessToken:(NSString *)facebookAccessToken {
    [self setObject:facebookAccessToken forKey:kFacebookAccessTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:facebookAccessToken forKey:kFacebookAccessTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:facebookAccessToken forKey:kAccessToken];
}

-(NSString *) facebookAccessToken {
    if ([self objectForKey:kFacebookAccessTokenKey]) {
        return [self objectForKey:kFacebookAccessTokenKey];
    } else if ([self objectForKey:kAccessToken]) {
        return [self objectForKey:kAccessToken];
    }
    return [[NSUserDefaults standardUserDefaults] objectForKey:kFacebookAccessTokenKey];
}

-(void) setAwsKey:(NSString *)awsKey {
    [[NSUserDefaults standardUserDefaults] setObject:awsKey forKey:kAWSKeyKey];
}

-(NSString *) awsKey {
    NSString *awsKey = [[NSUserDefaults standardUserDefaults] objectForKey:kAWSKeyKey];
    if (!awsKey) {
        self.awsKey = self.key;
        return self.key;
    }
    return awsKey;
}

-(void) setCdnPrefix:(NSString *)cdnPrefix {
    [[NSUserDefaults standardUserDefaults] setObject:cdnPrefix forKey:kCDNPrefix];
}

-(NSString *) cdnPrefix {
    NSString *cdnPrefix = [[NSUserDefaults standardUserDefaults] objectForKey:kCDNPrefix];
    if (!cdnPrefix) {
        self.cdnPrefix = kDefaultCDNPrefix;
        return kDefaultCDNPrefix;
    }
    return cdnPrefix;
}

-(void) setShowedOnboardView:(NSNumber *)showedOnboardView {
    [[NSUserDefaults standardUserDefaults] setObject:showedOnboardView forKey:kShowedOnboardView];
}

-(NSNumber *) showedOnboardView {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kShowedOnboardView];
}

-(void) setSchoolStatistics:(NSNumber *)schoolStatistics {
    [[NSUserDefaults standardUserDefaults] setObject:schoolStatistics forKey:kSchoolStatisticsKey];
}

-(NSNumber *) schoolStatistics {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSchoolStatisticsKey];
}

-(void) setGoogleAnalyticsEnabled:(NSNumber *)googleAnalyticsEnabled {
    [[NSUserDefaults standardUserDefaults] setObject:googleAnalyticsEnabled forKey:kGoogleAnalyticsEnabledKey];
}

-(NSNumber *) googleAnalyticsEnabled {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kGoogleAnalyticsEnabledKey];
}

-(void) setCanFetchAppStartup:(NSNumber *)canFetchAppStartup {
    [[NSUserDefaults standardUserDefaults] setObject:canFetchAppStartup forKey:kCanFetchAppStartupKey];
}

-(NSNumber *) canFetchAppStartup {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kCanFetchAppStartupKey];
}

-(void) setShowSchoolStatistics:(NSNumber *)showSchoolStatistics {
    [[NSUserDefaults standardUserDefaults] setObject:showSchoolStatistics forKey:kShowSchoolStatistics];
}

-(NSNumber *) showSchoolStatistics {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kShowSchoolStatistics];
}

-(void) setTriedToRegister:(NSNumber *)triedToRegister {
    [[NSUserDefaults standardUserDefaults] setObject:triedToRegister forKey:kTriedToRegisterKey];
}

-(NSNumber *) triedToRegister {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kTriedToRegisterKey];
}

-(void) setNumberOfTimesWentOut:(NSNumber *)numberOfTimesWentOut {
    [[NSUserDefaults standardUserDefaults] setObject:numberOfTimesWentOut forKey:kNumberOfTimesWentOut];
}

-(NSNumber *) numberOfTimesWentOut {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kNumberOfTimesWentOut];
}

-(void) setChosenPeople:(WGCollection *)chosenPeople {
    [[NSUserDefaults standardUserDefaults] setObject:chosenPeople forKey:kChosenPeople];
}

-(WGCollection *) chosenPeople {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kChosenPeople];
}

-(void) addChosenPerson:(WGUser *)person {
    if (!self.chosenPeople) {
        self.chosenPeople = [WGCollection serializeArray:@[] andClass:[WGUser class]];
    }
    [self.chosenPeople addObject:person];
}

-(void) addChosenPeople:(WGCollection *)people {
    if (!self.chosenPeople) {
        self.chosenPeople = people;
    } else {
        [self.chosenPeople addObjectsFromCollection:people];
    }
}

-(void) setDatesAccessed:(NSArray *)datesAccessed {
    [[NSUserDefaults standardUserDefaults] setObject:datesAccessed forKey:kDatesAccessedKey];
}

-(NSArray *) datesAccessed {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kDatesAccessedKey];
}

-(NSDate *) lastTimeAccessed {
    return [self.datesAccessed lastObject];
}

-(void) addDateToDatesAccessed:(NSDate *) date {
    if (!self.datesAccessed || [self.datesAccessed count] == 0) {
        self.datesAccessed = @[date];
        return;
    }
    
    NSMutableArray *mutableDatesAccessed = [[NSMutableArray alloc] initWithArray:self.datesAccessed];
    [mutableDatesAccessed addObject:date];
    self.datesAccessed = mutableDatesAccessed;
}

-(BOOL) accessedThreeDaysInARow {
    if (!self.datesAccessed) {
        return NO;
    }
    
    int dayCount = 1;
    NSDate *currentDay = [self.datesAccessed firstObject];
    
    for (NSDate *date in self.datesAccessed) {
        if ([currentDay isSameDayWithDate:date]) {
            // Don't count this as a day in a row
        } else if ([currentDay isNextDayWithDate:date]) {
            // This is the next day, so set the current day to this date
            dayCount += 1;
        } else {
            // This is not the next day, so reset the day count
            dayCount = 1;
        }
        if (dayCount >= 3) {
            return YES;
        }
        currentDay = date;
    }
    return NO;
}

+(void) reload:(BoolResultBlock)handler {
    [WGApi get:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        NSError *dataError;
        @try {
            [WGProfile setCurrentUser:[WGUser serialize:jsonResponse]];
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

-(void) setLastNotificationReadToLatest:(BoolResultBlock)handler {
    [WGApi post:@"users/me" withParameters:@{ kLastNotificationReadKey : @"latest" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        
        NSError *dataError;
        @try {
            self.parameters = [[NSMutableDictionary alloc] initWithDictionary:jsonResponse];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGObject" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            handler(dataError == nil, dataError);
        }
    }];
}

@end
