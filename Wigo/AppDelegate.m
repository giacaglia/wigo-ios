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
#import "LocalyticsSession.h"


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
    
    self.notificationDictionary = [[NSMutableDictionary alloc] init];
    
    // Override point for customization after application launch.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.tintColor = [UIColor clearColor];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor clearColor] } forState:UIControlStateSelected];
    
    [self changeTabBarToOrange];
    [self addNotificationHandlers];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    NSString *gitCount = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitCount"];
    NSString *gitHash = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitHash"];
    
    [[LocalyticsSession shared] LocalyticsSession:@"b6cd95cf2fdb16d4a9c6442-0646de50-12de-11e4-224f-004a77f8b47f"];
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
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
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UINavigationController *navController = [tabBarController.viewControllers objectAtIndex:tabBarController.selectedIndex];
    if (navController) [navController popToRootViewControllerAnimated:NO];
    
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    NSDictionary *alert = [aps objectForKey:@"alert"];
    NSString *locKeyString = [alert objectForKey:@"loc-key"];
    if ([locKeyString isEqualToString:@"M"]) {
        tabBarController.selectedIndex = 2;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchMessages" object:nil];

    }
    else if ([locKeyString isEqualToString:@"F"] ||
        [locKeyString isEqualToString:@"FR"] ||
        [locKeyString isEqualToString:@"FA"]) {
        tabBarController.selectedIndex = 3;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchNotifications" object:nil];

    }
    else if ([locKeyString isEqualToString:@"T"]) {
        tabBarController.selectedIndex = 3;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchNotifications" object:nil];
    }
    else if ([locKeyString isEqualToString:@"G"]) {
        tabBarController.selectedIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchFollowing" object:nil];

    }
}




- (void) changeTabBarToOrange {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    [tabBarController.view addGestureRecognizer:tap];
//    tap.delegate = self;

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
//    [self addNotificationNumber:@3 toTabBar:@3];
//    [self addNotificationNumber:@4 toTabBar:@2];
//    [self clearNotificationAtTabBar:@3];

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


- (void)addNotificationNumber:(NSNumber *)number toTabBar:(NSNumber *)tabBarNumber {
    CGSize origin;
    if ([tabBarNumber isEqualToNumber:@2]) { // Chats notification
        origin = CGSizeMake(216, 6);
    }
    else { //Other notifications
        origin = CGSizeMake(295, 6);
    }
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    
    UILabel *numberOfNotificationsLabel = [[UILabel alloc] init];
    if ([number isEqualToNumber:@1]) {
        numberOfNotificationsLabel.frame = CGRectMake(origin.width, origin.height, 8, 8);
    }
    else {
        numberOfNotificationsLabel.frame = CGRectMake(origin.width, origin.height, 16, 12);
        numberOfNotificationsLabel.text = [number stringValue];
        numberOfNotificationsLabel.textAlignment = NSTextAlignmentCenter;
        numberOfNotificationsLabel.textColor = [UIColor whiteColor];
        numberOfNotificationsLabel.font = [UIFont fontWithName:@"Whitney-Medium" size:10.0];
    }
    numberOfNotificationsLabel.backgroundColor = [FontProperties getOrangeColor];
    numberOfNotificationsLabel.layer.borderColor = [UIColor clearColor].CGColor;
    numberOfNotificationsLabel.layer.cornerRadius = 5;
    numberOfNotificationsLabel.layer.borderWidth = 1;
    numberOfNotificationsLabel.layer.masksToBounds = YES;
    
    [tabBar addSubview:numberOfNotificationsLabel];
    [self.notificationDictionary setValue:numberOfNotificationsLabel forKey:[tabBarNumber stringValue]];
}


- (void)clearNotificationAtTabBar:(NSNumber *)tabBarNumber {
    UILabel *numberOfNotificationLabel = [self.notificationDictionary valueForKey:[tabBarNumber stringValue]];
    [numberOfNotificationLabel removeFromSuperview];
}

- (void)addNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToOrange) name:@"changeTabBarToOrange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToBlue) name:@"changeTabBarToBlue" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearNotifications) name:@"clearNotifications" object:nil];

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
