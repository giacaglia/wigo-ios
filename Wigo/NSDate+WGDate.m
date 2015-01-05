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
