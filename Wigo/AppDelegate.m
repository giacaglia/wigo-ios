//
//  AppDelegate.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/14/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "AppDelegate.h"
#import "FontProperties.h"
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import <Crashlytics/Crashlytics.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"c08b20670e125cf177b5a6e7bb70d6b4e9b75c27"];
    NSString *parseApplicationId = PARSE_APPLICATIONID; // just for ease of debugging
    NSString *parseClientKey = PARSE_CLIENTKEY;
    
    
    
    [Parse setApplicationId:parseApplicationId
                  clientKey:parseClientKey];
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    // Override point for customization after application launch.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    
//    tabBar.barTintColor = RGB(244, 245, 245);
    tabBar.tintColor = [UIColor clearColor];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor clearColor],  } forState:UIControlStateSelected];
    [self changeTabBarToOrange];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToOrange) name:@"changeTabBarToOrange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToBlue) name:@"changeTabBarToBlue" object:nil];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    [PFPush handlePush:userInfo];
}


- (void) changeTabBarToOrange {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [tabBarController.view addGestureRecognizer:tap];
    tap.delegate = self;

    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [FontProperties getOrangeColor], NSFontAttributeName:[UIFont fontWithName:@"Whitney-MediumSC" size:11.0f] } forState:UIControlStateNormal];
    UITabBarItem *firstTab = [tabBar.items objectAtIndex:0];
    firstTab.image = [[UIImage imageNamed:@"peopleIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    firstTab = [tabBar.items objectAtIndex:1];
    firstTab.image = [[UIImage imageNamed:@"placesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    firstTab = [tabBar.items objectAtIndex:2];
    firstTab.image = [[UIImage imageNamed:@"chatsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    firstTab = [tabBar.items objectAtIndex:3];
    firstTab.image = [[UIImage imageNamed:@"notificationsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
//    [self addNotificationNumber:@0];

}

- (void) changeTabBarToBlue {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [FontProperties getBlueColor], NSFontAttributeName:[UIFont fontWithName:@"Whitney-MediumSC" size:11.0f] } forState:UIControlStateNormal];
    UITabBarItem *firstTab = [tabBar.items objectAtIndex:0];
    firstTab.image = [[UIImage imageNamed:@"peopleIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    firstTab = [tabBar.items objectAtIndex:2];
    firstTab.image = [[UIImage imageNamed:@"chatsIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    firstTab = [tabBar.items objectAtIndex:3];
    firstTab.image = [[UIImage imageNamed:@"notificationsIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
//    [self addNotificationNumber:@0];


}

- (void)addNotificationNumber:(NSNumber *)number {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;

    UILabel *numberOfNotifications = [[UILabel alloc] initWithFrame:CGRectMake(216, 6, 8, 8)];
    numberOfNotifications.backgroundColor = [FontProperties getOrangeColor];
    numberOfNotifications.layer.borderColor = [UIColor clearColor].CGColor;
    numberOfNotifications.layer.cornerRadius = 5;
    numberOfNotifications.layer.borderWidth = 1;
    numberOfNotifications.layer.masksToBounds = YES;
    [tabBar addSubview:numberOfNotifications];
}



# pragma mark - Facebook Login

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // You can add your app-specific url handling code here if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeAlertToNotShown" object:nil];
    
    return wasHandled;
}

#pragma mark - Tap Gesture

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Disallow recognition of tap gestures in the TabbarItem control.
    if ([touch.view isKindOfClass:[UIBarButtonItem class]]) {//change it to your condition
        if (touch.view.tag != 50) {
            return NO;
        }
        return YES;
    }
    return NO;
}
@end
