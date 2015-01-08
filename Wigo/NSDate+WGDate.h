//
//  NSDate+WGDate_NSDate.h
//  Wigo
//
//  Created by Adam Eagle on 1/5/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (WGDate)

-(NSString *) joinedString;

-(NSString *) getUTCTimeStringToLocalTimeString;

-(BOOL) isFromLastDay;

-(BOOL) isSameDayWithDate:(NSDate*)date;

-(BOOL) isNextDayWithDate:(NSDate*)date;

-(NSString *) deserialize;
+(NSDate *) serialize:(NSString *)dateString;

+(NSString *) nowStringUTC;

@end
