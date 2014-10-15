//
//  Time.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/22/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Time : NSObject

+ (BOOL) isUTCtimeStringFromLastDay:(NSString *)utcTimeString;
+ (NSString *)getUTCTimeStringToLocalTimeString:(NSString *)utcTimeString;
+ (NSString *)getLocalDateJoinedFromUTCTimeString:(NSString *)utcTimeString;
+ (NSDateComponents *)differenceBetweenFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
@end
