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

#define kPleaseEnableLocation @"Please allow location\nservices so we can show you\nsweet stuff nearby";


static CLLocationManager *locationManager;
static UILabel *titleLabel;
static UIView *blackOverlayView;
static UIButton *mainButton;

@interface LocationPrimer () <CLLocationManagerDelegate>
@end

@implementation LocationPrimer

+(UIView *) defaultTitleLabel {
    if (titleLabel == nil) {
        UIView *window = [UIApplication sharedApplication].delegate.window;
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, window.frame.size.height/2 - 100 - 50, window.frame.size.width - 30, 200)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = UIColor.whiteColor;
        titleLabel.numberOfLines = 0;
        titleLabel.font = [FontProperties lightFont:25.0f];
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
        mainButton.frame = CGRectMake(0, 0, 140, 60);
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

    LocationPrimer.defaultTitleLabel.text = kPleaseEnableLocation;
    [window bringSubviewToFront:LocationPrimer.defaultTitleLabel];
    
    LocationPrimer.defaultButton.layer.borderColor = UIColor.clearColor.CGColor;
    LocationPrimer.defaultButton.backgroundColor = [FontProperties getBlueColor];
    [LocationPrimer.defaultButton setTitle:@"Allow" forState:UIControlStateNormal];
    [LocationPrimer.defaultButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [LocationPrimer.defaultButton addTarget:[LocationPrimer class] action:@selector(enableLocationPressed:) forControlEvents:UIControlEventTouchUpInside];
    [window bringSubviewToFront:LocationPrimer.defaultButton];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [LocationPrimer.defaultBlackOverlay setHidden:NO];
        [LocationPrimer.defaultTitleLabel setHidden:NO];
        [LocationPrimer.defaultButton setHidden:NO];
    });

}

+(void) addErrorMessage {
    UIView *window = [UIApplication sharedApplication].delegate.window;
    
    LocationPrimer.defaultBlackOverlay.frame = window.frame;
    
    LocationPrimer.defaultTitleLabel.text = @"To use Wigo, please go to \nSettings > Privacy > Location Services, and switch Wigo to ON.";
    
    LocationPrimer.defaultButton.layer.borderColor = UIColor.whiteColor.CGColor;
    LocationPrimer.defaultButton.backgroundColor = UIColor.clearColor;
    [LocationPrimer.defaultButton setTitle:@"Settings" forState:UIControlStateNormal];
    [LocationPrimer.defaultButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [LocationPrimer.defaultButton addTarget:[LocationPrimer class] action:@selector(phoneSettingsPressed) forControlEvents:UIControlEventTouchUpInside];
    [window bringSubviewToFront:LocationPrimer.defaultButton];
    LocationPrimer.defaultButton.alpha = 1.0f;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [LocationPrimer.defaultBlackOverlay setHidden:NO];
        [LocationPrimer.defaultTitleLabel setHidden:NO];
        [LocationPrimer.defaultButton setHidden:NO];
    });
}

+(void) removePrimer {
    if (!LocationPrimer.defaultBlackOverlay.isHidden) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [LocationPrimer.defaultBlackOverlay setHidden:YES];
            [LocationPrimer.defaultButton setHidden:YES];
            [LocationPrimer.defaultTitleLabel setHidden:YES];
        });
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];

    }
}

+(void) phoneSettingsPressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

+(void) startPrimer {
    if (![CLLocationManager locationServicesEnabled] ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [LocationPrimer addErrorMessage];
        return;
    }
    if (![CLLocationManager locationServicesEnabled] ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [LocationPrimer addLocationPrimer];
        return;
    }
    if ([CLLocationManager locationServicesEnabled] &&
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse  ){
        [LocationPrimer removePrimer];
        return;
    }
}

+(BOOL) shouldFetchEvents {
    if (![CLLocationManager locationServicesEnabled] ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        return NO;
    }
    if (![CLLocationManager locationServicesEnabled] ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        return NO;
    }
    return YES;
}

+(void) enableLocationPressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    [UIView animateWithDuration:1.5f animations:^{
        buttonSender.alpha = 0.0f;
    }];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"user denied authorization");
        [LocationPrimer startPrimer];
    }
    else if (status == kCLAuthorizationStatusAuthorized) {
        NSLog(@"user allowed authorization");
        [LocationPrimer removePrimer];
    }
}

+(BOOL) wasPushNotificationEnabled {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]){
        UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (grantedSettings.types == UIUserNotificationTypeNone) {
            return NO;
        }
        return YES;
    }
    else {
        return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    }
  
}



@end
