//
//  Time.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/22/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Time.h"

@implementation Time

+ (NSString *)getUTCTimeStringToLocalTimeString:(NSString *)utcTimeString {
    NSDateFormatter *utcDateFormat = [[NSDateFormatter alloc] init];
    [utcDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateInUTC = [utcDateFormat dateFromString:utcTimeString];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSDate *dateInLocalTimezone = [dateInUTC dateByAddingTimeInterval:timeZoneSeconds];
    
    NSDateFormatter *localTimeFormat = [[NSDateFormatter alloc] init];
    [localTimeFormat setDateFormat:@"hh:mm a"];
    return [localTimeFormat stringFromDate:dateInLocalTimezone];
}


@end
