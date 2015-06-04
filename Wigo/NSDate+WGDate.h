//
//  NSDate+WGDate_NSDate.h
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (WGDate)

+(NSDate *) dateInLocalTimezone;

-(NSString *) joinedString;

-(NSString *) timeInLocaltimeString;
-(NSString *) getUTCTimeStringToLocalTimeString;

-(NSDateComponents *) differenceBetweenDates:(NSDate *)date;

-(BOOL) isFromLastDay;
-(BOOL) isSameDayWithDate:(NSDate*)date;
-(BOOL) isNextDayWithDate:(NSDate*)date;
-(NSString *)getDayString;
-(NSString *) deserialize;
+(NSDate *) serialize:(NSString *)dateString;

+(NSString *) nowStringUTC;
-(NSString *)timeAgo;

- (NSDate *)noonOfDateInLocalTimeZone;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
@end
