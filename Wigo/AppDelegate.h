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


@interface AppDelegate : UIResponder <UIApplicationDelegate, UIGestureRecognizerDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property NSMutableDictionary *notificationDictionary;

@end
