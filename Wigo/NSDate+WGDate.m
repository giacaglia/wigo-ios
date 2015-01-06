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
    
    NSDateComponents *dayJoined = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:dateInLocalTimezone];
    NSArray *monthsArray = @[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"];
    NSString *month = monthsArray[(int)[dayJoined month] - 1];
    
    return  [NSString stringWithFormat:@"Joined %@ %ld, %ld", month, (long)[dayJoined day], (long)[dayJoined year]];
}

#warning TODO: make sure this is correct
-(BOOL) isFromLastDay {
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [self dateByAddingTimeInterval:timeZoneSeconds];
    NSDate *nowDate = [NSDate date];
    
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:dateInLocalTimezone];
    
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit fromDate:nowDate];
    
    if ([today day] == [otherDay day] && [today month] == [otherDay month] && [today year] == [otherDay year]) {
        return NO;
    }
    
    return YES;
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
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    return [dateFormatter stringFromDate:self];
}

+(NSDate *) serialize:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    return [dateFormatter dateFromString:dateString];
}

@end
