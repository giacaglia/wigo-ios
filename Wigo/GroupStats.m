//
//  GroupStats.m
//  Wigo
//
//  Created by Alex Grinman on 11/21/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "GroupStats.h"

#define kStatsApiUrl @"analytics/school/%@/school_page"
#define kTop25StatsUrl @"analytics/schools/"

#define kEngagmentKey @"engagement"
#define kActivePercentKey @"active"

#define kCumulativeKey @"cumulative_totals" 
#define kVerifiedKey @"verified"

#define kSchool @"school"
#define kNumMembers @"num_members"

#define kDaily @"daily"
#define kWeekly @"weekly"
#define kMonthly @"monthly"

@implementation GroupStats


+ (void)getTop25:(ApiResultBlock)handler {
    [WGApi get:kTop25StatsUrl withArguments:@{@"ordering": @"-num_members", @"locked": @"false", @"limit": @"25", @"key" : @"q2up893ijea24joi" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(jsonResponse, error);
    }];

}

+ (void)doGet:(ApiResultBlock)handler {
    [WGApi get:[NSString stringWithFormat: kStatsApiUrl, [WGProfile currentUser].group.id] withArguments:@{ @"key" : @"q2up893ijea24joi" } andHandler:^(NSDictionary *jsonResponse, NSError *error) {
        handler(jsonResponse, error);
    }];
}

+ (void)loadStats:(void (^)(GroupStats *, NSError *))handler {
    
    [GroupStats doGet:
     ^(NSDictionary *jsonResponse, NSError *error) {
         
         if (error) {
             handler(nil, error);
             return;
         }
         
         GroupStats *groupStats = nil;
         NSError *exceptionError = nil;
         @try {
             groupStats = [GroupStats deserializeFromDictionary: jsonResponse];
         }
         @catch (NSException *exception) {
             
             NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to get stats.",
                                        NSLocalizedFailureReasonErrorKey: exception.reason };
             exceptionError = [[NSError alloc] initWithDomain: exception.name code:0 userInfo: userInfo];
         }
         @finally {
             handler(groupStats, exceptionError);
         }
    }];
}

+ (GroupStats *) deserializeFromDictionary: (NSDictionary *) jsonResult {
    
    GroupStats *groupStats = [GroupStats new];
    
    //get new users day, week, month, all
    NSDictionary *cumulativeDaily= jsonResult[kCumulativeKey][kDaily][kVerifiedKey];
    groupStats.todayUserCount = [GroupStats getMostRecentDateCount: cumulativeDaily];
    
    NSDictionary *cumulativeWeekly = jsonResult[kCumulativeKey][kWeekly][kVerifiedKey];
    groupStats.weekUserCount = [GroupStats getMostRecentDateCount: cumulativeWeekly];

    NSDictionary *cumulativeMonthly = jsonResult[kCumulativeKey][kMonthly][kVerifiedKey];
    groupStats.monthUserCount = [GroupStats getMostRecentDateCount: cumulativeMonthly];
    
    groupStats.allUsersCount = jsonResult[kSchool][kNumMembers];

    //create engagment graph objects
    NSDictionary *engagement = jsonResult[kEngagmentKey];
    
    //daily engagement
    groupStats.dailyEngagement = [GroupStats getEngagementGraph: engagement[kDaily]];
//    groupStats.dailyEngagement.xAxisLabels = @[@"M", @"T", @"W", @"Th", @"F", @"Sa", @"Su"];
    
    groupStats.weeklyEngagement = [GroupStats getEngagementGraph: engagement[kWeekly]];
    
    groupStats.monthlyEngagement = [GroupStats getEngagementGraph: engagement[kMonthly]];

    return groupStats;
}

+ (EngagementGraph *) getEngagementGraph: (NSDictionary *) dictionary {
    EngagementGraph *engagementGraph = [EngagementGraph new];
    
    NSArray *sortedDates = [GroupStats sortDates: dictionary.allKeys];
    
    NSMutableArray *xAxisLabels = [[NSMutableArray alloc] init];
    NSMutableArray *yAxisLabels = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    NSNumber *maxValue = @0;
    for (NSString *dateString in sortedDates) {
        NSNumber *val = dictionary[dateString][kActivePercentKey];

        [xAxisLabels addObject: dateString];
        [values addObject: val];
        
        if (val > maxValue) {
            maxValue = (NSNumber *)val;
        }
    }
    
    engagementGraph.xAxisLabels = xAxisLabels;
    engagementGraph.yAxisLabels = yAxisLabels;
    engagementGraph.values = values;
    
    return engagementGraph;
}

+ (NSNumber *) getMostRecentDateCount: (NSDictionary *) dictionary {
    
    NSArray *sortedDays = [GroupStats sortDates: dictionary.allKeys];
    NSString *currentDate = [sortedDays lastObject];
    
    if (sortedDays.count <= 1) {
        return [dictionary objectForKey: currentDate];
    }
    
    NSString *previousDate = [sortedDays objectAtIndex: sortedDays.count - 2];
    
    NSNumber *currentCount = [dictionary objectForKey: currentDate];
    NSNumber *previousCount = [dictionary objectForKey: previousDate];

    return [NSNumber numberWithInt: [currentCount intValue] - [previousCount intValue]];
}

+ (NSArray *) sortDates: (NSArray *) dates {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSArray *sortedDates = [dates sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *date1 = [dateFormatter dateFromString: (NSString *)obj1];
        NSDate *date2 = [dateFormatter dateFromString: (NSString *)obj2];
        
        return [date1 compare: date2];
    }];
    
    return sortedDates;
}

@end
