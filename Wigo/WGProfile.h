//
//  WGProfile.h
//  Wigo
//
//  Created by Adam Eagle on 1/3/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGUser.h"

@interface WGProfile : WGUser

@property NSString *awsKey;
@property NSString *cdnPrefix;

@property NSNumber *schoolStatistics;
@property NSNumber *showedOnboardView;
@property NSNumber *googleAnalyticsEnabled;
@property NSNumber *canFetchAppStartup;
@property NSNumber *triedToRegister;
@property NSNumber *showSchoolStatistics;
@property NSNumber *numberOfTimesWentOut;
@property NSArray *datesAccessed;
@property WGCollection *chosenPeople;
@property float imageQuality;
@property float imageMultiple;

+(void) setCurrentUser:(WGUser *)user;
+(WGProfile *) currentUser;
-(void) login:(BoolResultBlock)handler;
-(void) signup:(BoolResultBlock)handler;
+(void) reload:(BoolResultBlock)handler;
-(void) setLastNotificationReadToLatest:(BoolResultBlock)handler;
-(void) setLastUserReadToLatest:(BoolResultBlock)handler;

-(void) addChosenPerson:(WGUser *)person;
-(void) addChosenPeople:(WGCollection *)people;

-(NSDate *) lastTimeAccessed;
-(void) addDateToDatesAccessed:(NSDate *) date;
-(BOOL) accessedThreeDaysInARow;

@end
