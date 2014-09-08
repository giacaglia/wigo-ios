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
    
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit fromDate:dateInLocalTimezone];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit fromDate:[NSDate date]];
    // If today
    if ([today hour] >= 6 && [today day] == [otherDay day] && [today month] == [otherDay month] && [today year] == [otherDay year]) {
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
    
    if ([today hour] >= 6 && [today day] == [otherDay day] && [today month] == [otherDay month] && [today year] == [otherDay year]) {
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
        if ([differenceDateComponents weekOfMonth] == 0) {
            if ([differenceDateComponents day] == 0 || [differenceDateComponents day] == 1) {
                return @"1 day ago";
            }
            return [NSString stringWithFormat:@"%ld days ago", (long)[differenceDateComponents day]];
        }
        else {
            if ([differenceDateComponents month] == 0) {
                if ([differenceDateComponents weekOfMonth] == 1) {
                    return @"1 week ago";
                }
                return [NSString stringWithFormat:@"%ld weeks ago", (long)[differenceDateComponents weekOfMonth]];
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
