//
//  AppDelegate.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/14/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property NSMutableDictionary *notificationDictionary;

@end
