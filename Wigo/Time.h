//
//  Time.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/22/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Time : NSObject

+ (NSString *)getUTCTimeStringToLocalTimeString:(NSString *)utcTimeString;

@end
