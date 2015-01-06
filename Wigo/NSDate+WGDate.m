//
//  NSDate+WGDate_NSDate.m
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "NSDate+WGDate.h"

@implementation NSDate (WGDate)

-(NSString *) joinedString {
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [self dateByAddingTimeInterval:timeZoneSeconds];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    return [NSString stringWithFormat:@"Joined %@", [dateFormatter stringFromDate:self]];
}

#warning TODO: make sure this is correct
-(BOOL) isFromLastDay {
    NSDate *nowDate = [NSDate date];
    
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [self dateByAddingTimeInterval:timeZoneSeconds];
    
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:dateInLocalTimezone];
    
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

- (BOOL) isNextDayWithDate:(NSDate*)date {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *differenceDateComponents = [calendar
                                                  components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekOfYearCalendarUnit|NSDayCalendarUnit |NSMinuteCalendarUnit
                                                  fromDate:self
                                                  toDate:date
                                                  options:0];
    return [differenceDateComponents day] == 1;
}

-(NSString *) deserialize {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:self];
}

+(NSDate *) serialize:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter dateFromString:dateString];
}

@end
