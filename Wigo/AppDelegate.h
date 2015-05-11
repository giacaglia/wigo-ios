//
//  AppDelegate.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/14/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

typedef void (^IsThereResult)(NSNumber *numberOfNewMessages, NSNumber *numberOfNewNotifications);


@interface AppDelegate : UIResponder <UIApplicationDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property NSMutableDictionary *notificationDictionary;

- (void) initializeGoogleAnalytics;
- (void) switchToTab:(NSString *)tab withOptions:(NSDictionary *)options;

@end
