//
//  LocationPrimer.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/6/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationPrimer : NSObject
+(UILabel *)defaultTitleLabel;
+(UIView *) defaultBlackOverlay;
+(UIButton *)defaultButton;
+(void) addLocationPrimer;
+(void) removePrimer;
+(void) addErrorMessage;
+(BOOL) wasPushNotificationEnabled;
@end
