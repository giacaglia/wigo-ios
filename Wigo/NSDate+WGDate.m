//
//  NSDate+WGDate_NSDate.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "NSDate+WGDate.h"

@implementation NSDate (WGDate)

+(NSDate *) dateInLocalTimezone {
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    return [[NSDate date] dateByAddingTimeInterval:timeZoneSeconds];
}

-(NSString *) joinedString {
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [self dateByAddingTimeInterval:timeZoneSeconds];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    return [NSString stringWithFormat:@"Joined %@", [dateFormatter stringFromDate:dateInLocalTimezone]];
}

- (NSString *) timeInLocaltimeString {
    NSDateFormatter *localTimeFormat = [[NSDateFormatter alloc] init];
    [localTimeFormat setDateFormat:@"h:mm a"];
    return [localTimeFormat stringFromDate:self];
}

-(NSString *) getUTCTimeStringToLocalTimeString {    
    if (![self isFromLastDay]) {
        NSDateFormatter *localTimeFormat = [[NSDateFormatter alloc] init];
        [localTimeFormat setDateFormat:@"h:mm a"];
        return [localTimeFormat stringFromDate:self];
    } else {
        NSDate *nowDate = [NSDate date];
        NSDateComponents *differenceDateComponents = [self differenceBetweenDates:nowDate];
        if ([differenceDateComponents weekOfYear] == 0 && [differenceDateComponents month] == 0) {
            if ([differenceDateComponents day] == 0 || [differenceDateComponents day] == 1) {
                return @"1 d";
            }
            return [NSString stringWithFormat:@"%ld d", (long)[differenceDateComponents day]];
        } else {
            if ([differenceDateComponents month] == 0) {
                if ([differenceDateComponents weekOfYear] == 1) {
                    return @"1 w";
                }
                return [NSString stringWithFormat:@"%ld w", (long)[differenceDateComponents weekOfYear]];
            }
            else {
                if ([differenceDateComponents month] == 1) {
                    return @"1 mo";
                }
                return [NSString stringWithFormat:@"%ld mo", (long)[differenceDateComponents month]];
            }
            
        }
    }
}

-(BOOL) isFromLastDay {
    NSDate *nowDate = [NSDate date];
    
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    nowDate = [nowDate dateByAddingTimeInterval:timeZoneSeconds];

    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:self];
    
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit fromDate:nowDate];
    
    NSDateComponents *differenceDateComponents = [self differenceBetweenDates:nowDate];
    
    if ([otherDay hour] >= 6 && [today day] == [otherDay day] && [today month] == [otherDay month] && [today year] == [otherDay year]) {
        return NO;
    }
    if ([today hour] < 6 && [today month] == [otherDay month] && [today year] == [otherDay year] && [differenceDateComponents day] == 1) {
        return NO;
    }
    
    return YES;
}

-(NSDateComponents *) differenceBetweenDates:(NSDate *)date {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned int flags = NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekOfYearCalendarUnit |NSDayCalendarUnit | NSHourCalendarUnit;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents *otherDay=  [gregorianCalendar
                                  components:flags
                                  fromDate:[self dateByAddingTimeInterval:-3600*6]];
    NSDateComponents *nowDay = [gregorianCalendar
                                components:flags
                                fromDate:[date dateByAddingTimeInterval:-3600*6]];
    NSDate *otherDayDate = [calendar dateFromComponents:otherDay];
    NSDate *nowDayDate = [calendar dateFromComponents:nowDay];
    
    NSDateComponents *differenceDateComponents = [gregorianCalendar
                                                  components:flags
                                                  fromDate:otherDayDate
                                                  toDate:nowDayDate
                                                  options:0];
    return differenceDateComponents;
}

- (BOOL) isSameDayWithDate:(NSDate*)date {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:self];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date];
    
    return [comp1 day] == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

- (NSDate *)noonOfDateInLocalTimeZone {
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comps = [calendar components:unitFlags fromDate:self];
    [comps setHour:12];
    [comps setMinute:0];
    [comps setSecond:0];
    
    return [calendar dateFromComponents:comps];
}

- (BOOL) isNextDayWithDate:(NSDate*)date {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *differenceDateComponents = [calendar
                                                  components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekOfYearCalendarUnit|NSDayCalendarUnit |NSMinuteCalendarUnit
                                                  fromDate:self
                                                  toDate:date
                                                  options:0];
    return [differenceDateComponents day] == 1;
}

-(NSString *)getDayString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    return [dateFormatter stringFromDate:self];
}

-(NSString *) deserialize {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    return [dateFormatter stringFromDate:[self dateByAddingTimeInterval:-timeZoneSeconds]];
}

+(NSDate *) serialize:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    return [[dateFormatter dateFromString:dateString] dateByAddingTimeInterval:timeZoneSeconds];
}

+(NSString *) nowStringUTC {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

-(NSString *)timeAgo {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned int flags = NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekOfYearCalendarUnit |NSDayCalendarUnit | NSHourCalendarUnit;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents *otherDay=  [gregorianCalendar
                                  components:flags
                                  fromDate:[self dateByAddingTimeInterval:-3600*6]];
   
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit fromDate:[NSDate date]];

    NSDate *otherDayDate = [calendar dateFromComponents:otherDay];
    NSDate *nowDayDate = [calendar dateFromComponents:today];
    
    double deltaSeconds = fabs([otherDayDate timeIntervalSinceDate:nowDayDate]);
    double deltaMinutes = deltaSeconds / 60.0f;
    
    int minutes;
    if (deltaMinutes < (24 * 60 * 2))
    {
        return @"Yesterday";
    }
    else {
        minutes = (int)floor(deltaMinutes/(60 * 24));
        return [NSString stringWithFormat:@"%d days ago", minutes];
    }

}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

@end
