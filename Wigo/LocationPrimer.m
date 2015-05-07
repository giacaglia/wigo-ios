//
//  LocationPrimer.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/6/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "LocationPrimer.h"
#import "Globals.h"
#import <CoreLocation/CoreLocation.h>

static CLLocationManager *locationManager;

@implementation LocationPrimer

+(void)addLocationPrimer {
    UIView *window = [[[UIApplication sharedApplication] delegate] window];
    
    UIView *blackOverlayView = [[UIView alloc] initWithFrame:window.frame];
    blackOverlayView.backgroundColor = RGBAlpha(0, 0, 0, 0.5f);
    [window addSubview:blackOverlayView];
    
    UILabel *pleaseEnable = [[UILabel alloc] initWithFrame:CGRectMake(15, window.frame.size.height/2 - 100 - 50, window.frame.size.width - 30, 200)];
    pleaseEnable.text = @"Please enable location so\nwe can show the amazing events\nand awesome people nearby";
    pleaseEnable.textAlignment = NSTextAlignmentCenter;
    pleaseEnable.textColor = UIColor.whiteColor;
    pleaseEnable.font = [FontProperties lightFont:18.0f];
    pleaseEnable.numberOfLines = 0;
    [window addSubview:pleaseEnable];
    
    UIButton *enableLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 80)];
    enableLocationButton.center = CGPointMake(window.center.x, window.center.y + 50);
    enableLocationButton.layer.borderColor = UIColor.clearColor.CGColor;
    enableLocationButton.layer.borderWidth = 1.0f;
    enableLocationButton.layer.cornerRadius = 15.0f;
    enableLocationButton.backgroundColor = [FontProperties getBlueColor];
    [enableLocationButton setTitle:@"Enable Location" forState:UIControlStateNormal];
    [enableLocationButton addTarget:[LocationPrimer class] action:@selector(enableLocationPressed:) forControlEvents:UIControlEventTouchUpInside];
    [enableLocationButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [window addSubview:enableLocationButton];
}

+ (void)enableLocationPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    buttonSender.hidden = YES;
    locationManager = [[CLLocationManager alloc] init];
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
}

@end
