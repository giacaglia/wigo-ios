//
//  WGProfile.m
//  Wigo
//
//  Created by Adam Eagle on 1/3/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGProfile.h"

#define kKeyKey @"key"
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
#define kFacebookIdKey @"facebook_id"

#define kDefaultCDNPrefix @"wigo-uploads.s3.amazonaws.com"

static WGProfile *currentUser = nil;

@implementation WGProfile

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

+(void) setCurrentUser:(WGUser *)user {
    currentUser = [[WGProfile alloc] initWithJSON:[user deserialize]];
    
    [[NSUserDefaults standardUserDefaults] setObject:user.key forKey:kKeyKey];
    [[NSUserDefaults standardUserDefaults] setObject:user.facebookId forKey:kFacebookIdKey];
    [[NSUserDefaults standardUserDefaults] setObject:user.facebookAccessToken forKey:kFacebookAccessTokenKey];
}

+(WGProfile *) currentUser {
    return currentUser;
}

-(void) setKey:(NSString *)key {
    [self setObject:key forKey:kKeyKey];
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:kKeyKey];
}

-(void) setFacebookId:(NSString *)facebookId {
    [self setObject:facebookId forKey:kFacebookIdKey];
    [[NSUserDefaults standardUserDefaults] setObject:facebookId forKey:kFacebookIdKey];
}

-(void) setFacebookAccessToken:(NSString *)facebookAccessToken {
    [self setObject:facebookAccessToken forKey:kFacebookAccessTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:facebookAccessToken forKey:kFacebookAccessTokenKey];
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
        if ([self isSameDayWithDate:currentDay andDate:date]) {
            // Don't count this as a day in a row
        } else if ([self isNextDayWithDate:currentDay andDate:date]) {
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

- (BOOL) isSameDayWithDate:(NSDate*)date1 andDate:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day] == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

- (BOOL) isNextDayWithDate:(NSDate*)date1 andDate:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *differenceDateComponents = [calendar
                                                  components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekOfYearCalendarUnit|NSDayCalendarUnit |NSMinuteCalendarUnit
                                                  fromDate:date1
                                                  toDate:date2
                                                  options:0];
    return [differenceDateComponents day] == 1;
}

@end
