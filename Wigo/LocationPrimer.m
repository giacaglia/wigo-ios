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
static UILabel *titleLabel;
static UIView *blackOverlayView;
static UIButton *mainButton;

@implementation LocationPrimer

+(UIView *) defaultTitleLabel {
    if (titleLabel == nil) {
        UIView *window = [UIApplication sharedApplication].delegate.window;
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, window.frame.size.height/2 - 100 - 50, window.frame.size.width - 30, 200)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = UIColor.whiteColor;
        titleLabel.numberOfLines = 0;
        titleLabel.font = [FontProperties lightFont:18.0f];
        [window addSubview:titleLabel];
    }
    return titleLabel;
}

+(UIView *) defaultBlackOverlay {
    if (blackOverlayView == nil) {
        UIView *window = [UIApplication sharedApplication].delegate.window;
        blackOverlayView = [UIView new];
        blackOverlayView.backgroundColor = RGBAlpha(0, 0, 0, 0.5f);
        [window addSubview:blackOverlayView];
    }
    return blackOverlayView;
}

+(UIButton *)defaultButton {
    if (mainButton == nil) {
        UIView *window = [UIApplication sharedApplication].delegate.window;
        mainButton = [UIButton new];
        mainButton.frame = CGRectMake(0, 0, 200, 80);
        mainButton.center = CGPointMake(window.center.x, window.center.y + 50);
        mainButton.layer.borderWidth = 1.0f;
        mainButton.layer.cornerRadius = 15.0f;
        [mainButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [window addSubview:mainButton];
    }
    return mainButton;
}


+(void) addLocationPrimer {
    UIView *window = [UIApplication sharedApplication].delegate.window;
    
    LocationPrimer.defaultBlackOverlay.frame = window.frame;
    
    LocationPrimer.defaultTitleLabel.text = @"Please enable location so\nwe can show the amazing events\nand awesome people nearby";
    [window bringSubviewToFront:LocationPrimer.defaultTitleLabel];
    
    LocationPrimer.defaultButton.layer.borderColor = UIColor.clearColor.CGColor;
    LocationPrimer.defaultButton.backgroundColor = [FontProperties getBlueColor];
    [LocationPrimer.defaultButton setTitle:@"Enable Location" forState:UIControlStateNormal];
    [LocationPrimer.defaultButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [LocationPrimer.defaultButton addTarget:[LocationPrimer class] action:@selector(enableLocationPressed:) forControlEvents:UIControlEventTouchUpInside];
    [window bringSubviewToFront:LocationPrimer.defaultButton];
}

+(void) addErrorMessage {
    UIView *window = [UIApplication sharedApplication].delegate.window;
    LocationPrimer.defaultBlackOverlay.frame = window.frame;

    LocationPrimer.defaultTitleLabel.text = @"Wigo can’t be used until you\nprovide location permissions. Go into\nyour phone settings to do this.";
    
    LocationPrimer.defaultButton.layer.borderColor = UIColor.whiteColor.CGColor;
    LocationPrimer.defaultButton.backgroundColor = UIColor.clearColor;
    [LocationPrimer.defaultButton setTitle:@"Phone Settings" forState:UIControlStateNormal];
    [LocationPrimer.defaultButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [LocationPrimer.defaultButton addTarget:[LocationPrimer class] action:@selector(phoneSettingsPressed) forControlEvents:UIControlEventTouchUpInside];
    [window bringSubviewToFront:LocationPrimer.defaultButton];
}

+(void) removePrimer {
    [LocationPrimer.defaultBlackOverlay removeFromSuperview];
}

+(void) phoneSettingsPressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

+(void) enableLocationPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    [UIView animateWithDuration:1.5f animations:^{
        buttonSender.alpha = 0.0f;
    }];
    locationManager = [[CLLocationManager alloc] init];
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
}

+(BOOL) wasPushNotificationEnabled {
    if([CLLocationManager locationServicesEnabled] &&
       [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)
    {
        return YES;
    }
    return NO;
}



@end
