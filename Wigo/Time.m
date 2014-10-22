//
//  Time.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/22/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Time.h"

@implementation Time

+ (BOOL) isUTCtimeStringFromLastDay:(NSString *)utcTimeString {
    NSDateFormatter *utcDateFormat = [[NSDateFormatter alloc] init];
    [utcDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateInUTC = [utcDateFormat dateFromString:utcTimeString];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [dateInUTC dateByAddingTimeInterval:timeZoneSeconds];
    
    NSDate *nowDate = [NSDate date];
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:dateInLocalTimezone];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit fromDate:nowDate];
    NSDateComponents *differenceDateComponents = [Time differenceBetweenFromDate:dateInLocalTimezone toDate:nowDate];
    
    // IF it's the same day as today return NO;
    if ([otherDay hour] >= 6 && [today day] == [otherDay day] && [today month] == [otherDay month] && [today year] == [otherDay year]) {
        return NO;
    }
    if ([today hour] < 6 && [today month] == [otherDay month] && [today year] == [otherDay year] && [differenceDateComponents day] == 1) {
        return NO;
    }
    return YES;
}

+ (NSString *)getUTCTimeStringToLocalTimeString:(NSString *)utcTimeString {
    NSDateFormatter *utcDateFormat = [[NSDateFormatter alloc] init];
    [utcDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateInUTC = [utcDateFormat dateFromString:utcTimeString];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [dateInUTC dateByAddingTimeInterval:timeZoneSeconds];
        
    if (![Time isUTCtimeStringFromLastDay:utcTimeString]) {
        NSDateFormatter *localTimeFormat = [[NSDateFormatter alloc] init];
        [localTimeFormat setDateFormat:@"h:mm a"];
        return [localTimeFormat stringFromDate:dateInLocalTimezone];
    }
    else {
        NSDate *nowDate = [NSDate date];
        NSDateComponents *differenceDateComponents = [Time differenceBetweenFromDate:dateInLocalTimezone toDate:nowDate];
        if ([differenceDateComponents weekOfYear] == 0 && [differenceDateComponents month] == 0) {
            if ([differenceDateComponents day] == 0 || [differenceDateComponents day] == 1) {
                return @"1 day ago";
            }
            return [NSString stringWithFormat:@"%ld days ago", (long)[differenceDateComponents day]];
        }
        else {
            if ([differenceDateComponents month] == 0) {
                if ([differenceDateComponents weekOfYear] == 1) {
                    return @"1 week ago";
                }
                return [NSString stringWithFormat:@"%ld weeks ago", (long)[differenceDateComponents weekOfYear]];
            }
            else {
                if ([differenceDateComponents month] == 1) {
                    return @"1 month ago";
                }
                return [NSString stringWithFormat:@"%ld months ago", (long)[differenceDateComponents month]];
            }
            
        }
    }
}

+ (NSDateComponents *)differenceBetweenFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned int flags = NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekOfYearCalendarUnit |NSDayCalendarUnit;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents *otherDay=  [gregorianCalendar
                                  components:flags
                                  fromDate:[fromDate dateByAddingTimeInterval:-3600*6]];
    NSDateComponents *nowDay = [gregorianCalendar
                                components:flags
                                fromDate:[toDate dateByAddingTimeInterval:-3600*6]];
    NSDate *otherDayDate = [calendar dateFromComponents:otherDay];
    NSDate *nowDayDate = [calendar dateFromComponents:nowDay];
    
    NSDateComponents *differenceDateComponents = [gregorianCalendar
                                                  components:flags
                                                  fromDate:otherDayDate
                                                  toDate:nowDayDate
                                                  options:0];
    return differenceDateComponents;
}

+ (NSString *)getLocalDateJoinedFromUTCTimeString:(NSString *)utcTimeString {
    NSDateFormatter *utcDateFormat = [[NSDateFormatter alloc] init];
    [utcDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateInUTC = [utcDateFormat dateFromString:utcTimeString];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [dateInUTC dateByAddingTimeInterval:timeZoneSeconds];
    
    NSDateComponents *dayJoined = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:dateInLocalTimezone];
    NSArray *monthsArray = @[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"];
    NSString *month = monthsArray[[dayJoined month] - 1];
    return  [NSString stringWithFormat:@"Joined %@ %ld, %ld", month, (long)[dayJoined day], (long)[dayJoined year]];
}


@end
