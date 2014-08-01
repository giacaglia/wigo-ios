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
    
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:dateInLocalTimezone];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    // If today
    if ([today hour] >= 6 && [today day] == [otherDay day]) {
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
    
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit fromDate:dateInLocalTimezone];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit |NSHourCalendarUnit fromDate:[NSDate date]];
    
    if ([otherDay hour] >= 6 && [today day] == [otherDay day]) {
        NSDateFormatter *localTimeFormat = [[NSDateFormatter alloc] init];
        [localTimeFormat setDateFormat:@"h:mm a"];
        return [localTimeFormat stringFromDate:dateInLocalTimezone];
    }
    else { // Get the difference between the dates
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *differenceDateComponents = [gregorianCalendar
                                                      components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSDayCalendarUnit
                                                      fromDate:dateInLocalTimezone
                                                      toDate:[NSDate date]
                                                      options:0];
        if ([differenceDateComponents week] == 0) {
            if ([differenceDateComponents day] == 0 || [differenceDateComponents day] == 1) {
                return @"1 day ago";
            }
            return [NSString stringWithFormat:@"%d days ago", [differenceDateComponents day]];
        }
        else {
            if ([differenceDateComponents month] == 0) {
                if ([differenceDateComponents week] == 1) {
                    return @"1 week ago";
                }
                return [NSString stringWithFormat:@"%d weeks ago", [differenceDateComponents week]];
            }
            else {
                if ([differenceDateComponents month] == 1) {
                    return @"1 month ago";
                }
                return [NSString stringWithFormat:@"%d months ago", [differenceDateComponents month]];
            }
            
        }
    }
}


@end
